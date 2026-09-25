import Foundation
import Network
import UserNotifications

enum APIError: Error, LocalizedError {
    case notFound
    case server(Int)
    case network
    var errorDescription: String? {
        switch self {
        case .notFound: return "Nie znaleziono wydarzenia o tym kodzie."
        case .server(let c): return "Błąd serwera (\(c))."
        case .network: return "Brak połączenia. Sprawdź internet i spróbuj ponownie."
        }
    }
}

enum TopScreen: Equatable {
    case entry
    case events
    case event(Int64)
}

@MainActor
final class AppStore: ObservableObject {
    static let apiBase = "https://eskulapp.pl/api"
    // Static bundle na CDN (architektura B), produkcyjny custom domain R2.
    static let cdnBase = "https://cdn.eskulapp.pl"

    @Published var top: TopScreen = .entry
    @Published private(set) var storedEvents: [StoredEvent] = []
    @Published private(set) var notifyIds: Set<Int64> = []
    @Published private(set) var reminderIds: Set<Int64> = []
    @Published private(set) var readNewsIds: Set<Int64> = []
    /// Glosy tego urzadzenia (oceny prelekcji), klucz = talkId. Trwale w ratings.json.
    @Published private(set) var ratings: [Int64: LocalRating] = [:]

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("events.json")
    }()
    private let ratingsURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("ratings.json")
    }()
    private let pathMonitor = NWPathMonitor()
    private var ratingSyncRunning = false
    private var ratingSyncAgain = false
    private var ratingRetryScheduled = false

    init() {
        load()
        notifyIds = Self.loadIds("notifyIds")
        reminderIds = Self.loadIds("reminderIds")
        readNewsIds = Self.loadIds("readNewsIds")
        loadRatings()
        top = storedEvents.isEmpty ? .entry : .events
        Task { _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) }
        // Odswiez dane z CDN w tle (manifest -> bundel tylko gdy wersja nowsza).
        if !storedEvents.isEmpty { Task { await refreshAll() } }
        // Zalegle glosy (oddane offline) wysylamy, gdy tylko jest siec (tez od razu po starcie).
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard path.status == .satisfied else { return }
            Task { @MainActor in await self?.syncPendingRatings() }
        }
        pathMonitor.start(queue: DispatchQueue(label: "pl.eskulapp.net"))
    }

    // MARK: dostep

    func event(_ id: Int64) -> StoredEvent? { storedEvents.first { $0.id == id } }

    /// Kolejnosc jak w Androidzie: archiwalne na dole, reszta wg daty startu (lub dodania) malejaco.
    var sortedEvents: [StoredEvent] {
        storedEvents.sorted { a, b in
            let aArch = a.bundle.event.statusOrDefault == "archived"
            let bArch = b.bundle.event.statusOrDefault == "archived"
            if aArch != bArch { return !aArch }
            let ak = a.bundle.event.startsAt ?? isoFrom(a.addedAt)
            let bk = b.bundle.event.startsAt ?? isoFrom(b.addedAt)
            if ak != bk { return ak > bk }
            return a.addedAt > b.addedAt
        }
    }

    private func isoFrom(_ epochSeconds: Double) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f.string(from: Date(timeIntervalSince1970: epochSeconds))
    }

    // MARK: siec

    /// Wspolny GET zwracajacy dane. 404 -> notFound; inne bledy -> server/network.
    private func httpGet(_ urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else { throw APIError.network }
        var req = URLRequest(url: url)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 15
        let data: Data
        let resp: URLResponse
        do {
            (data, resp) = try await URLSession.shared.data(for: req)
        } catch {
            throw APIError.network
        }
        let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
        if status == 404 { throw APIError.notFound }
        guard (200...299).contains(status) else { throw APIError.server(status) }
        return data
    }

    // ---- CDN (architektura B): manifest + wersjonowany bundel ----

    struct ManifestDTO: Decodable {
        let version: String
        let bundlePath: String
        enum CodingKeys: String, CodingKey { case version; case bundlePath = "bundle_path" }
    }

    func fetchManifest(_ code: String) async throws -> ManifestDTO {
        let c = code.trimmingCharacters(in: .whitespaces).uppercased()
        let data = try await httpGet("\(Self.cdnBase)/events/\(c)/manifest.json")
        return try JSONDecoder().decode(ManifestDTO.self, from: data)
    }

    func fetchBundleAt(_ path: String) async throws -> EventBundle {
        let p = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let data = try await httpGet("\(Self.cdnBase)/\(p)")
        return try JSONDecoder().decode(EventBundle.self, from: data)
    }

    // ---- Fallback: bezposrednio z PHP API ----

    func fetchBundle(_ code: String) async throws -> EventBundle {
        let c = code.trimmingCharacters(in: .whitespaces).uppercased()
        let data = try await httpGet("\(Self.apiBase)/public/events/\(c)/bundle")
        do {
            return try JSONDecoder().decode(EventBundle.self, from: data)
        } catch {
            throw APIError.server(0)
        }
    }

    // Wersja bundla per kod (z manifestu), zeby nie pobierac gdy bez zmian.
    private static func cdnVersion(_ code: String) -> String? {
        UserDefaults.standard.string(forKey: "cdnVer_\(code.uppercased())")
    }
    private static func setCdnVersion(_ code: String, _ v: String) {
        UserDefaults.standard.set(v, forKey: "cdnVer_\(code.uppercased())")
    }

    /// CDN najpierw (manifest + wersjonowany bundel), a gdy niedostepny to PHP.
    private func fetchSmart(_ code: String) async throws -> EventBundle {
        let c = code.trimmingCharacters(in: .whitespaces).uppercased()
        do {
            let m = try await fetchManifest(c)
            let b = try await fetchBundleAt(m.bundlePath)
            Self.setCdnVersion(c, m.version)
            return b
        } catch {
            return try await fetchBundle(c)
        }
    }

    // MARK: mutacje

    @discardableResult
    func addEvent(_ code: String) async throws -> Int64 {
        let bundle = try await fetchSmart(code)
        upsert(bundle)
        // W tle: odtworz oceny tego urzadzenia (np. event usuniety i dodany ponownie).
        if bundle.event.ratingsOn {
            let ev = bundle.event
            Task { await restoreMyRatings(eventId: ev.id, code: ev.accessCode) }
        }
        return bundle.event.id
    }

    /// Odswiezenie: pobiera bundel tylko gdy wersja w manifescie sie zmienila.
    func refresh(_ code: String) async {
        let c = code.trimmingCharacters(in: .whitespaces).uppercased()
        do {
            let m = try await fetchManifest(c)
            let exists = storedEvents.contains { $0.bundle.event.accessCode.uppercased() == c }
            if exists && Self.cdnVersion(c) == m.version { return }
            let b = try await fetchBundleAt(m.bundlePath)
            Self.setCdnVersion(c, m.version)
            upsert(b)
        } catch {
            if let b = try? await fetchBundle(c) { upsert(b) }
        }
    }

    /// Odswiezenie wszystkich dodanych eventow (np. przy starcie apki).
    func refreshAll() async {
        for code in storedEvents.map({ $0.bundle.event.accessCode }) {
            await refresh(code)
        }
    }

    private func upsert(_ bundle: EventBundle) {
        let existingAddedAt = storedEvents.first { $0.id == bundle.event.id }?.addedAt
        let stored = StoredEvent(bundle: bundle, addedAt: existingAddedAt ?? Date().timeIntervalSince1970)
        if let idx = storedEvents.firstIndex(where: { $0.id == bundle.event.id }) {
            storedEvents[idx] = stored
        } else {
            storedEvents.append(stored)
        }
        save()
    }

    func deleteEvent(_ id: Int64) {
        storedEvents.removeAll { $0.id == id }
        save()
    }

    func openEvent(_ id: Int64) { top = .event(id) }

    func toggleNotify(_ id: Int64, _ on: Bool) {
        if on { notifyIds.insert(id) } else { notifyIds.remove(id) }
        Self.saveIds("notifyIds", notifyIds)
    }

    func markAllNewsRead(_ eventId: Int64) {
        guard let ev = event(eventId) else { return }
        let ids = ev.bundle.news.map { $0.id }
        var changed = false
        for i in ids where !readNewsIds.contains(i) { readNewsIds.insert(i); changed = true }
        if changed { Self.saveIds("readNewsIds", readNewsIds) }
    }

    func unreadCount(_ eventId: Int64) -> Int {
        guard let ev = event(eventId) else { return 0 }
        return ev.bundle.news.filter { !readNewsIds.contains($0.id) }.count
    }

    func toggleReminder(talkId: Int64, title: String, subtitle: String?, startsAt: String?, on: Bool) {
        if on {
            reminderIds.insert(talkId)
            scheduleReminder(talkId: talkId, title: title, subtitle: subtitle, startsAt: startsAt)
            scheduleRateReminder(talkId: talkId, title: title)
        } else {
            reminderIds.remove(talkId)
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: ["talk_\(talkId)", "rate_\(talkId)"])
        }
        Self.saveIds("reminderIds", reminderIds)
    }

    private func scheduleReminder(talkId: Int64, title: String, subtitle: String?, startsAt: String?) {
        guard let start = parseLocalDate(startsAt) else { return }
        let fireDate = start.addingTimeInterval(-10 * 60) // 10 min przed, jak w Androidzie
        let delay = fireDate.timeIntervalSinceNow
        guard delay > 0 else { return } // minelo: stan zapamietany, ale nie budzimy
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = (subtitle?.isEmpty == false ? subtitle! : "Prelekcja wkrótce")
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let req = UNNotificationRequest(identifier: "talk_\(talkId)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    /// Przypomnienie "Oceń wykład" przy otwarciu okna ocen, tylko dla obserwowanych prelekcji.
    /// Bez nowej zgody: ta sama zgoda na powiadomienia co przypomnienia o prelekcjach.
    private func scheduleRateReminder(talkId: Int64, title: String) {
        guard let ev = storedEvents.first(where: { se in se.bundle.talks.contains { $0.id == talkId } }),
              ev.bundle.event.ratingsOn,
              let talk = ev.bundle.talks.first(where: { $0.id == talkId }) else { return }
        let w = RatingTime.window(startsAt: talk.startsAt, endsAt: talk.endsAt,
                                  openAfterStartMin: ev.bundle.event.ratingsOpenMin,
                                  closeAfterEndMin: ev.bundle.event.ratingsCloseMin, now: Date())
        guard w.phase == .notOpen, let opens = w.opensAt else { return }
        let delay = opens.timeIntervalSinceNow
        guard delay > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = "Oceń wykład: \(title)"
        content.body = "Ocenianie jest już otwarte. Wybierz ocenę od 1 do 10."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "rate_\(talkId)", content: content, trigger: trigger))
    }

    // MARK: oceny prelekcji (SPEC-OCENY §5): najpierw lokalnie, potem serwer

    /// Anonimowy identyfikator instalacji: losowy UUID v4 w UserDefaults (nie Keychain,
    /// wiec znika z odinstalowaniem). Serwer zapisuje tylko sha256(install_id + sol).
    static var installId: String {
        let key = "ratingInstallId"
        if let v = UserDefaults.standard.string(forKey: key) { return v }
        let v = UUID().uuidString.lowercased()
        UserDefaults.standard.set(v, forKey: key)
        return v
    }

    /// Ocena 1..10: zapis lokalny jako "pending" i wysylka od razu (albo gdy wroci siec).
    func rate(eventId: Int64, talkId: Int64, score: Int) {
        guard (1...10).contains(score), let ev = event(eventId) else { return }
        let version = max(Date().timeIntervalSince1970, (ratings[talkId]?.updatedAt ?? 0) + 0.001)
        ratings[talkId] = LocalRating(talkId: talkId, eventId: eventId,
                                      eventCode: ev.bundle.event.accessCode.uppercased(), score: score,
                                      status: RatingStatus.pending, error: nil, updatedAt: version)
        saveRatings()
        Task { await syncPendingRatings() }
    }

    /// Wysyla wszystkie glosy "pending". 409 po zamknieciu okna = "rejected" (UI pokazuje
    /// "Nie udało się zapisać, okno oceniania zamknięte."); siec/429/5xx = zostaje "pending".
    func syncPendingRatings() async {
        if ratingSyncRunning { ratingSyncAgain = true; return }
        ratingSyncRunning = true
        defer { ratingSyncRunning = false }
        var anyRetry = false
        repeat {
            ratingSyncAgain = false
            let pending = ratings.values.filter { $0.status == RatingStatus.pending }.sorted { $0.updatedAt < $1.updatedAt }
            for r in pending {
                let res = await postRating(r)
                // glos zmieniony w trakcie wysylki: nowa wersja zostaje "pending" (kolejny obieg)
                guard var cur = ratings[r.talkId], cur.updatedAt == r.updatedAt else { continue }
                switch res {
                case .saved:
                    cur.status = RatingStatus.synced
                    cur.error = nil
                case .rejected(let err):
                    cur.status = RatingStatus.rejected
                    cur.error = err
                case .retry:
                    anyRetry = true
                    continue
                }
                ratings[r.talkId] = cur
                saveRatings()
            }
        } while ratingSyncAgain
        if anyRetry { scheduleRatingRetry() }
    }

    /// Ponowienie po chwilowym bledzie przy dzialajacej sieci (np. 429, 5xx).
    private func scheduleRatingRetry() {
        guard !ratingRetryScheduled else { return }
        ratingRetryScheduled = true
        Task {
            try? await Task.sleep(nanoseconds: 60_000_000_000)
            ratingRetryScheduled = false
            await syncPendingRatings()
        }
    }

    private func postRating(_ r: LocalRating) async -> RatingResult {
        let code = r.eventCode.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? r.eventCode
        guard let url = URL(string: "\(Self.apiBase)/public/events/\(code)/talks/\(r.talkId)/rating") else {
            return .retry
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 15
        let payload: [String: Any] = ["install_id": Self.installId, "score": r.score]
        req.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            return ratingResult(httpCode: (resp as? HTTPURLResponse)?.statusCode ?? 0, body: data, score: r.score)
        } catch {
            return .retry
        }
    }

    /// GET .../ratings/mine: odtworzenie ocen tego urzadzenia. Glosow "pending" nie nadpisujemy.
    private func restoreMyRatings(eventId: Int64, code: String) async {
        let c = code.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? code
        let id = Self.installId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let data = try? await httpGet("\(Self.apiBase)/public/events/\(c)/ratings/mine?install_id=\(id)"),
              let mine = try? JSONDecoder().decode([MyRatingDTO].self, from: data) else { return }
        var changed = false
        for m in mine {
            if let local = ratings[m.talkId] {
                if local.status == RatingStatus.pending { continue }
                if local.status == RatingStatus.synced && local.score == m.score { continue }
            }
            ratings[m.talkId] = LocalRating(talkId: m.talkId, eventId: eventId, eventCode: code.uppercased(),
                                            score: m.score, status: RatingStatus.synced, error: nil,
                                            updatedAt: Date().timeIntervalSince1970)
            changed = true
        }
        if changed { saveRatings() }
    }

    private func loadRatings() {
        guard let data = try? Data(contentsOf: ratingsURL),
              let list = try? JSONDecoder().decode([LocalRating].self, from: data) else { return }
        ratings = Dictionary(list.map { ($0.talkId, $0) }, uniquingKeysWith: { a, b in a.updatedAt >= b.updatedAt ? a : b })
    }

    private func saveRatings() {
        if let data = try? JSONEncoder().encode(Array(ratings.values)) {
            try? data.write(to: ratingsURL, options: .atomic)
        }
    }

    // MARK: trwalosc

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([StoredEvent].self, from: data) {
            storedEvents = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(storedEvents) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private static func loadIds(_ key: String) -> Set<Int64> {
        let arr = UserDefaults.standard.array(forKey: key) as? [Int] ?? []
        return Set(arr.map { Int64($0) })
    }

    private static func saveIds(_ key: String, _ ids: Set<Int64>) {
        UserDefaults.standard.set(ids.map { Int($0) }, forKey: key)
    }
}
