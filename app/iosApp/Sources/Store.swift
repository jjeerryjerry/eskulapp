import Foundation
import UserNotifications

enum APIError: Error, LocalizedError {
    case notFound
    case server(Int)
    case network
    var errorDescription: String? {
        switch self {
        case .notFound: return "Nie znaleziono wydarzenia o tym kodzie."
        case .server(let c): return "Blad serwera (\(c))."
        case .network: return "Brak polaczenia. Sprawdz internet i sprobuj ponownie."
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

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("events.json")
    }()

    init() {
        load()
        notifyIds = Self.loadIds("notifyIds")
        reminderIds = Self.loadIds("reminderIds")
        readNewsIds = Self.loadIds("readNewsIds")
        top = storedEvents.isEmpty ? .entry : .events
        Task { _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) }
        // Odswiez dane z CDN w tle (manifest -> bundel tylko gdy wersja nowsza).
        if !storedEvents.isEmpty { Task { await refreshAll() } }
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
        } else {
            reminderIds.remove(talkId)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["talk_\(talkId)"])
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
        content.body = (subtitle?.isEmpty == false ? subtitle! : "Prelekcja wkrotce")
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let req = UNNotificationRequest(identifier: "talk_\(talkId)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
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
