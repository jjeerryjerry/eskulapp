package pl.eskulapp.mobile.agenda

/**
 * Pozycja agendy, ktora uczestnik obserwuje (dzwonek): wyklad albo cala sesja.
 * Czasy w formacie bundla "yyyy-MM-dd HH:mm:ss" (czas lokalny eventu), wiec
 * porownanie tekstowe = porownanie chronologiczne.
 */
data class AgendaSlot(
    val id: Long,
    val isSession: Boolean,
    val title: String,
    val room: String?,
    val startsAt: String?,
    val endsAt: String?,
    /** Dla wykladu: sesja, do ktorej nalezy (null = wyklad samodzielny). */
    val sessionId: Long? = null,
) {
    val key: String get() = (if (isSession) "s" else "t") + id
}

/** Konflikty czasowe miedzy obserwowanymi pozycjami (NOTATKA-AGENCJA 2026-10-14, pkt 2). */
object Conflicts {

    /** Pozycje z [followed], ktore nachodza czasowo na [candidate]. */
    fun with(candidate: AgendaSlot, followed: List<AgendaSlot>): List<AgendaSlot> =
        followed.filter { it.key != candidate.key && overlaps(candidate, it) && !related(candidate, it) }

    /** Klucze obserwowanych pozycji, ktore koliduja z jakas inna obserwowana pozycja. */
    fun keys(followed: List<AgendaSlot>): Set<String> =
        followed.filter { a -> with(a, followed).isNotEmpty() }.map { it.key }.toSet()

    /** Sesja i jej wlasny podwyklad to nie konflikt: siedzisz na tej samej sali. */
    private fun related(a: AgendaSlot, b: AgendaSlot): Boolean = when {
        a.isSession && !b.isSession -> b.sessionId == a.id
        !a.isSession && b.isSession -> a.sessionId == b.id
        else -> false
    }

    /** Przedzialy [start, end) nachodza na siebie. Brak ktoregos czasu = brak konfliktu. */
    private fun overlaps(a: AgendaSlot, b: AgendaSlot): Boolean {
        val aS = a.startsAt ?: return false; val aE = a.endsAt ?: return false
        val bS = b.startsAt ?: return false; val bE = b.endsAt ?: return false
        return aS < bE && bS < aE
    }
}
