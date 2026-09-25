import Foundation

// Testy czystej logiki ocen iOS (docs/SPEC-OCENY.md §7), te same przypadki co Android
// (RatingLogicTest.kt) i serwer (web/tests/ratings_test.php). Poza projektem Xcode:
//
//   swiftc app/iosApp/Sources/Ratings.swift app/iosApp/RatingTests/main.swift -o /tmp/rt && /tmp/rt
//
// (CI: .github/workflows/pr-ios.yml). Kod wyjscia != 0 przy bledzie.

// Celowo obca strefa telefonu: okno liczymy w Europe/Warsaw, niezaleznie od niej.
setenv("TZ", "America/New_York", 1)
NSTimeZone.default = TimeZone(identifier: "America/New_York")!

var failures = 0
var passed = 0
func eq<T: Equatable>(_ expected: T, _ actual: T, _ msg: String, line: Int = #line) {
    if expected == actual { passed += 1 } else {
        failures += 1
        print("FAIL (linia \(line)) \(msg): oczekiwano \(expected), jest \(actual)")
    }
}

let iso = ISO8601DateFormatter()
func utc(_ s: String) -> Date { iso.date(from: s)! }
func waw(_ local: String, _ plusSec: Double = 0) -> Date { RatingTime.localDate(local)!.addingTimeInterval(plusSec) }
func phase(_ s: String?, _ e: String?, _ now: Date, _ open: Int = 10, _ close: Int = 30) -> RatingPhase {
    RatingTime.window(startsAt: s, endsAt: e, openAfterStartMin: open, closeAfterEndMin: close, now: now).phase
}
func offsetString(_ d: Date) -> String {
    let f = ISO8601DateFormatter()
    f.timeZone = RatingTime.warsaw
    f.formatOptions = [.withInternetDateTime]
    return f.string(from: d)
}

let s = "2026-10-20 10:00:00"
let e = "2026-10-20 10:45:00"

// granice okna
eq(RatingPhase.notOpen, phase(s, e, waw(s, 9 * 60 + 59)), "start+9:59")
eq(RatingPhase.open, phase(s, e, waw(s, 10 * 60)), "start+10:00")
eq(RatingPhase.open, phase(s, e, waw(e, 30 * 60)), "end+30:00")
eq(RatingPhase.closed, phase(s, e, waw(e, 30 * 60 + 1)), "end+30:01")
eq(RatingPhase.open, phase(s, e, waw(e, 30 * 60 + 0.9)), "ulamek sekundy")
eq(RatingPhase.open, phase(s, e, waw(s), 0, 0), "0/0 przy starcie")
eq(RatingPhase.closed, phase(s, e, waw(e, 1), 0, 0), "0/0 po koncu")

// nieoceniana
eq(RatingPhase.unrateable, phase(nil, e, waw(s)), "brak startu")
eq(RatingPhase.unrateable, phase(s, nil, waw(s)), "brak konca")
eq(RatingPhase.unrateable, phase("smieci", e, waw(s)), "smieci")
eq(true, RatingTime.localDate("2026-02-30 10:00:00") == nil, "30 lutego")

// strefa Warszawy lato/zima
eq(RatingPhase.notOpen, phase("2026-07-01 10:00:00", "2026-07-01 11:00:00", utc("2026-07-01T08:09:59Z")), "lato 08:09:59Z")
eq(RatingPhase.open, phase("2026-07-01 10:00:00", "2026-07-01 11:00:00", utc("2026-07-01T08:10:00Z")), "lato 08:10Z")
eq(RatingPhase.open, phase("2026-12-01 10:00:00", "2026-12-01 11:00:00", utc("2026-12-01T09:10:00Z")), "zima 09:10Z")
eq(RatingPhase.notOpen, phase("2026-12-01 10:00:00", "2026-12-01 11:00:00", utc("2026-12-01T09:09:59Z")), "zima 09:09:59Z")

// zmiana czasu
eq(RatingPhase.notOpen, phase("2026-03-29 01:30:00", "2026-03-29 03:30:00", utc("2026-03-29T00:39:59Z")), "wiosna otwarcie-1s")
eq(RatingPhase.open, phase("2026-03-29 01:30:00", "2026-03-29 03:30:00", utc("2026-03-29T00:40:00Z")), "wiosna otwarcie")
eq(RatingPhase.open, phase("2026-03-29 01:30:00", "2026-03-29 03:30:00", utc("2026-03-29T02:00:00Z")), "wiosna zamkniecie")
eq(RatingPhase.closed, phase("2026-03-29 01:30:00", "2026-03-29 03:30:00", utc("2026-03-29T02:00:01Z")), "wiosna zamkniecie+1s")
eq(RatingPhase.open, phase("2026-10-25 01:30:00", "2026-10-25 03:30:00", utc("2026-10-24T23:40:00Z")), "jesien otwarcie")
eq(RatingPhase.open, phase("2026-10-25 01:30:00", "2026-10-25 03:30:00", utc("2026-10-25T03:00:00Z")), "jesien zamkniecie")
eq(RatingPhase.closed, phase("2026-10-25 01:30:00", "2026-10-25 03:30:00", utc("2026-10-25T03:00:01Z")), "jesien zamkniecie+1s")
eq("2026-03-29T03:30:00+02:00", offsetString(RatingTime.localDate("2026-03-29 02:30:00")!), "godzina nieistniejaca")
eq("2026-10-25T02:30:00+01:00", offsetString(RatingTime.localDate("2026-10-25 02:30:00")!), "godzina podwojna")
eq("2026-03-29T03:05:00+02:00",
   offsetString(RatingTime.window(startsAt: "2026-03-29 01:55:00", endsAt: "2026-03-29 03:30:00",
                                  openAfterStartMin: 10, closeAfterEndMin: 30, now: Date()).opensAt!),
   "01:55 + 10 min")

// stany sekcji
func panel(_ now: Date, _ score: Int? = nil, _ status: String? = nil, _ error: String? = nil, enabled: Bool = true) -> RatingPanel? {
    ratingPanel(ratingsEnabled: enabled, window: RatingTime.window(startsAt: s, endsAt: e, openAfterStartMin: 10,
                                                                   closeAfterEndMin: 30, now: now),
                score: score, status: status, error: error, now: now)
}
eq(true, panel(waw(s, 1200), enabled: false) == nil, "oceny wylaczone")
eq("Ocena od 10:10", panel(waw(s, 60))?.message ?? "", "jeszcze nieaktywne")
eq(false, panel(waw(s, 60))?.enabled ?? true, "nieaktywne przyciski")
eq("Ocena od 20.10, 10:10", panel(waw(s, -86400))?.message ?? "", "inny dzien")
eq("Oceniono (8). Możesz zmienić do 11:15", panel(waw(s, 1200), 8, RatingStatus.synced)?.message ?? "", "oceniono")
eq(8, panel(waw(s, 1200), 8, RatingStatus.synced)?.selected ?? 0, "zaznaczona ocena")
eq("Ocenianie zamknięte.", panel(waw(e, 31 * 60))?.message ?? "", "zamkniete")
eq("Nie udało się zapisać, okno oceniania zamknięte.",
   panel(waw(e, 31 * 60), 9, RatingStatus.rejected, "window_closed")?.message ?? "", "409 po zamknieciu")

// odpowiedzi serwera
eq(RatingResult.saved(7), ratingResult(httpCode: 200, body: Data("{\"ok\":true,\"score\":7}".utf8), score: 7), "200")
eq(RatingResult.rejected("window_closed"),
   ratingResult(httpCode: 409, body: Data("{\"error\":\"window_closed\"}".utf8), score: 7), "409")
eq(RatingResult.rejected("http_404"), ratingResult(httpCode: 404, body: nil, score: 7), "404 bez ciala")
eq(RatingResult.retry, ratingResult(httpCode: 429, body: nil, score: 7), "429")
eq(RatingResult.retry, ratingResult(httpCode: 503, body: nil, score: 7), "503")
eq(RatingResult.retry, ratingResult(httpCode: 0, body: nil, score: 7), "brak sieci")

print("Wynik: \(passed) ok, \(failures) bledow")
exit(failures == 0 ? 0 : 1)
