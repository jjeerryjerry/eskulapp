import Foundation

/// Pozycja agendy obserwowana dzwonkiem: wyklad albo cala sesja.
/// Czasy "yyyy-MM-dd HH:mm:ss" (czas lokalny eventu): porownanie tekstowe = chronologiczne.
struct AgendaSlot: Identifiable {
    let itemId: Int64
    let isSession: Bool
    let title: String
    let room: String?
    let startsAt: String?
    let endsAt: String?
    /// Dla wykladu: sesja, do ktorej nalezy (nil = wyklad samodzielny).
    var sessionId: Int64? = nil

    var key: String { (isSession ? "s" : "t") + String(itemId) }
    var id: String { key }
}

/// Konflikty czasowe miedzy obserwowanymi pozycjami (1:1 z Conflicts.kt w Androidzie).
enum Conflicts {
    /// Pozycje z `followed`, ktore nachodza czasowo na `candidate`.
    static func with(_ candidate: AgendaSlot, _ followed: [AgendaSlot]) -> [AgendaSlot] {
        followed.filter { $0.key != candidate.key && overlaps(candidate, $0) && !related(candidate, $0) }
    }

    /// Klucze obserwowanych pozycji, ktore koliduja z jakas inna obserwowana pozycja.
    static func keys(_ followed: [AgendaSlot]) -> Set<String> {
        Set(followed.filter { !with($0, followed).isEmpty }.map { $0.key })
    }

    /// Sesja i jej wlasny podwyklad to nie konflikt: siedzisz na tej samej sali.
    private static func related(_ a: AgendaSlot, _ b: AgendaSlot) -> Bool {
        if a.isSession && !b.isSession { return b.sessionId == a.itemId }
        if !a.isSession && b.isSession { return a.sessionId == b.itemId }
        return false
    }

    /// Przedzialy [start, end) nachodza na siebie. Brak ktoregos czasu = brak konfliktu.
    private static func overlaps(_ a: AgendaSlot, _ b: AgendaSlot) -> Bool {
        guard let aS = a.startsAt, let aE = a.endsAt, let bS = b.startsAt, let bE = b.endsAt else { return false }
        return aS < bE && bS < aE
    }
}

/// Ostrzezenie czekajace na decyzje uczestnika: `candidate` nachodzi na `conflicts`.
struct ConflictPrompt: Identifiable {
    let id = UUID()
    let candidate: AgendaSlot
    let conflicts: [AgendaSlot]
    let proceed: () -> Void
}
