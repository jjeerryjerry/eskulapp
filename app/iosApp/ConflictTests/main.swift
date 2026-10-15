import Foundation

// Testy logiki konfliktow czasowych iOS, te same przypadki co Android (ConflictsTest.kt).
//   swiftc app/iosApp/Sources/Conflicts.swift app/iosApp/ConflictTests/main.swift -o /tmp/ct && /tmp/ct
// (CI: .github/workflows/pr-ios.yml). Kod wyjscia != 0 przy bledzie.

var failures = 0
var passed = 0
func check(_ ok: Bool, _ msg: String, line: Int = #line) {
    if ok { passed += 1 } else { failures += 1; print("FAIL (linia \(line)) \(msg)") }
}

func talk(_ id: Int64, _ s: String, _ e: String, session: Int64? = nil) -> AgendaSlot {
    AgendaSlot(itemId: id, isSession: false, title: "T\(id)", room: nil,
               startsAt: "2026-10-20 \(s):00", endsAt: "2026-10-20 \(e):00", sessionId: session)
}
func session(_ id: Int64, _ s: String, _ e: String) -> AgendaSlot {
    AgendaSlot(itemId: id, isSession: true, title: "S\(id)", room: nil,
               startsAt: "2026-10-20 \(s):00", endsAt: "2026-10-20 \(e):00")
}

check(Conflicts.with(talk(1, "10:00", "10:45"), [talk(2, "10:30", "11:20")]).map { $0.itemId } == [2], "nachodzace wyklady")
check(Conflicts.with(talk(1, "10:00", "10:30"), [talk(2, "10:30", "11:00")]).isEmpty, "styk to nie konflikt")
check(Conflicts.with(session(7, "09:20", "10:40"), [talk(1, "09:20", "10:10", session: 7)]).isEmpty, "sesja i jej podwyklad")
check(Conflicts.with(talk(1, "09:20", "10:10", session: 7), [session(7, "09:20", "10:40")]).isEmpty, "podwyklad i jego sesja")
check(Conflicts.with(session(7, "09:20", "10:40"), [talk(3, "10:30", "11:20")]).map { $0.key } == ["t3"], "sesja vs wyklad obok")
check(Conflicts.with(talk(1, "10:00", "11:00"), [session(1, "10:30", "11:30")]).count == 1, "to samo id, inny rodzaj")
let noEnd = AgendaSlot(itemId: 9, isSession: false, title: "x", room: nil, startsAt: "2026-10-20 10:00:00", endsAt: nil)
check(Conflicts.with(noEnd, [talk(2, "09:00", "12:00")]).isEmpty, "brak konca = brak konfliktu")
check(Conflicts.keys([talk(1, "10:00", "10:45"), talk(2, "10:30", "11:20"), talk(3, "12:00", "13:00")]) == ["t1", "t2"], "keys")

print("Konflikty: \(passed) OK, \(failures) FAIL")
exit(failures == 0 ? 0 : 1)
