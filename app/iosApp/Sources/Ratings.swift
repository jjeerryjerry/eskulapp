import Foundation

// Oceny prelekcji 1-10 (docs/SPEC-OCENY.md). Czysta logika bez UI, 1:1 z Androidem
// (ratings/RatingLogic.kt) i serwerem (Ratings::window). Apka liczy okno tylko dla UI,
// o przyjeciu glosu decyduje serwer wedlug wlasnego zegara.

enum RatingPhase { case unrateable, notOpen, open, closed }

struct RatingWindow {
    let phase: RatingPhase
    let opensAt: Date?
    let closesAt: Date?
}

/// Status lokalnego glosu (ratings.json).
enum RatingStatus {
    static let pending = "pending"    // zapisany lokalnie, czeka na wyslanie
    static let synced = "synced"      // serwer przyjal (200)
    static let rejected = "rejected"  // serwer odrzucil na stale (np. window_closed)
}

/// Lokalny glos na prelekcje (offline-first). updatedAt = lokalna wersja, nie jest wysylana.
struct LocalRating: Codable, Equatable {
    let talkId: Int64
    let eventId: Int64
    let eventCode: String
    var score: Int
    var status: String
    var error: String?
    var updatedAt: Double
}

/// Element GET /api/public/events/{code}/ratings/mine
struct MyRatingDTO: Decodable {
    let talkId: Int64
    let score: Int
    enum CodingKeys: String, CodingKey {
        case talkId = "talk_id"
        case score
    }
}

enum RatingTime {
    static let warsaw = TimeZone(identifier: "Europe/Warsaw")!
    static let defaultOpenMin = 10
    static let defaultCloseMin = 30

    /// "yyyy-MM-dd HH:mm[:ss]" w czasie lokalnym Warszawy -> chwila. Zmiana czasu jak na
    /// serwerze: godzina nieistniejaca przesuwa sie do przodu o luke, godzina podwojna =
    /// pozniejsze wystapienie (czas zimowy). Liczone jawnie, bez zaleznosci od DateFormatter.
    static func localDate(_ s: String?) -> Date? {
        guard let raw = s?.trimmingCharacters(in: .whitespaces) else { return nil }
        let parts = raw.replacingOccurrences(of: "T", with: " ").split(separator: " ")
        guard parts.count == 2 else { return nil }
        let ymd = parts[0].split(separator: "-", omittingEmptySubsequences: false).map { Int($0) }
        let hms = parts[1].split(separator: ":", omittingEmptySubsequences: false).map { Int($0) }
        guard ymd.count == 3, hms.count == 2 || hms.count == 3,
              let y = ymd[0], let mo = ymd[1], let d = ymd[2], let h = hms[0], let mi = hms[1] else { return nil }
        let sec = hms.count == 3 ? hms[2] : 0
        guard let sc = sec else { return nil }

        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let comps = DateComponents(year: y, month: mo, day: d, hour: h, minute: mi, second: sc)
        guard let wallDate = utc.date(from: comps) else { return nil }
        // odrzuc daty "przewiniete" przez kalendarz (np. 30 lutego, 24:00)
        let back = utc.dateComponents([.year, .month, .day, .hour, .minute, .second], from: wallDate)
        guard back.year == y, back.month == mo, back.day == d, back.hour == h, back.minute == mi, back.second == sc else {
            return nil
        }
        let wall = wallDate.timeIntervalSince1970          // zegar scienny liczony "jak UTC"
        func offset(_ t: TimeInterval) -> TimeInterval {
            TimeInterval(warsaw.secondsFromGMT(for: Date(timeIntervalSince1970: t)))
        }
        let before = offset(wall - 43200)
        let after = offset(wall + 43200)
        var valid: [TimeInterval] = []
        for o in Set([before, after]) where offset(wall - o) == o {
            valid.append(wall - o)
        }
        return Date(timeIntervalSince1970: valid.max() ?? (wall - before))
    }

    /// Okno od starts_at + openMin do ends_at + closeMin, granice wlacznie z dokladnoscia
    /// do sekundy (start+10:00 otwarte, end+30:00 otwarte, end+30:01 zamkniete).
    static func window(startsAt: String?, endsAt: String?, openAfterStartMin: Int,
                       closeAfterEndMin: Int, now: Date) -> RatingWindow {
        guard let start = localDate(startsAt), let end = localDate(endsAt) else {
            return RatingWindow(phase: .unrateable, opensAt: nil, closesAt: nil)
        }
        let opens = start.addingTimeInterval(TimeInterval(openAfterStartMin * 60))
        let closes = end.addingTimeInterval(TimeInterval(closeAfterEndMin * 60))
        let t = floor(now.timeIntervalSince1970)
        let phase: RatingPhase
        if t < opens.timeIntervalSince1970 {
            phase = .notOpen
        } else if t > closes.timeIntervalSince1970 {
            phase = .closed
        } else {
            phase = .open
        }
        return RatingWindow(phase: phase, opensAt: opens, closesAt: closes)
    }

    /// "HH:mm" (dzis) albo "dd.MM, HH:mm" (inny dzien), w czasie Warszawy jak agenda.
    static func clock(_ at: Date, now: Date) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = warsaw
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = warsaw
        f.dateFormat = cal.isDate(at, inSameDayAs: now) ? "HH:mm" : "dd.MM, HH:mm"
        return f.string(from: at)
    }
}

/// Co pokazac w sekcji "Oceń wykład". Bez sredniej: uczestnik nie widzi wynikow.
struct RatingPanel: Equatable {
    let enabled: Bool
    let message: String
    let selected: Int?
    var warning: Bool = false
}

/// Stan sekcji oceny; nil = sekcji nie pokazujemy (oceny wylaczone albo prelekcja bez godzin).
func ratingPanel(ratingsEnabled: Bool, window: RatingWindow, score: Int?, status: String?,
                 error: String?, now: Date) -> RatingPanel? {
    if !ratingsEnabled || window.phase == .unrateable { return nil }
    let open = window.phase == .open
    let until = window.closesAt.map { RatingTime.clock($0, now: now) } ?? ""
    let kept: Int? = (status == RatingStatus.synced || status == RatingStatus.pending) ? score : nil
    if status == RatingStatus.rejected {
        let msg: String
        switch error ?? "" {
        case "window_closed": msg = "Nie udało się zapisać, okno oceniania zamknięte."
        case "window_not_open": msg = "Nie udało się zapisać, ocenianie jeszcze się nie zaczęło."
        case "ratings_disabled": msg = "Nie udało się zapisać, oceny są wyłączone."
        default: msg = "Nie udało się zapisać oceny."
        }
        return RatingPanel(enabled: open, message: msg, selected: nil, warning: true)
    }
    let pendingMsg = "Oceniono (\(kept ?? 0)). Zapiszemy ocenę, gdy będzie internet."
    switch window.phase {
    case .notOpen:
        let from = window.opensAt.map { RatingTime.clock($0, now: now) } ?? ""
        return RatingPanel(enabled: false, message: "Ocena od \(from)", selected: nil)
    case .open:
        if let k = kept, status == RatingStatus.pending {
            return RatingPanel(enabled: true, message: pendingMsg, selected: k)
        }
        if let k = kept {
            return RatingPanel(enabled: true, message: "Oceniono (\(k)). Możesz zmienić do \(until)", selected: k)
        }
        return RatingPanel(enabled: true, message: "Wybierz ocenę od 1 do 10. Głos jest anonimowy.", selected: nil)
    case .closed:
        if let k = kept, status == RatingStatus.pending {
            return RatingPanel(enabled: false, message: pendingMsg, selected: k)
        }
        if let k = kept {
            return RatingPanel(enabled: false, message: "Oceniono (\(k)). Ocenianie zamknięte.", selected: k)
        }
        return RatingPanel(enabled: false, message: "Ocenianie zamknięte.", selected: nil)
    case .unrateable:
        return nil
    }
}

/// Wynik wyslania glosu.
enum RatingResult: Equatable {
    case saved(Int)
    case rejected(String)   // odrzucony na stale: nie ponawiamy
    case retry              // siec, 429, 5xx: ponawiamy pozniej
}

/// Odpowiedz HTTP z POST .../rating -> RatingResult.
func ratingResult(httpCode: Int, body: Data?, score: Int) -> RatingResult {
    if (200...299).contains(httpCode) { return .saved(score) }
    if httpCode == 408 || httpCode == 429 || httpCode >= 500 || httpCode <= 0 { return .retry }
    if let body = body,
       let obj = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any],
       let err = obj["error"] as? String {
        return .rejected(err)
    }
    return .rejected("http_\(httpCode)")
}
