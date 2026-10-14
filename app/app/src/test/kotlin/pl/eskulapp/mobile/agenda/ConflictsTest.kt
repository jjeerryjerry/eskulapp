package pl.eskulapp.mobile.agenda

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ConflictsTest {
    private fun talk(id: Long, s: String, e: String, session: Long? = null) =
        AgendaSlot(id, false, "T$id", null, "2026-10-20 $s:00", "2026-10-20 $e:00", session)

    private fun session(id: Long, s: String, e: String) =
        AgendaSlot(id, true, "S$id", null, "2026-10-20 $s:00", "2026-10-20 $e:00")

    @Test fun overlappingTalksConflict() {
        val c = Conflicts.with(talk(1, "10:00", "10:45"), listOf(talk(2, "10:30", "11:20")))
        assertEquals(listOf(2L), c.map { it.id })
    }

    @Test fun backToBackIsNotConflict() {
        assertTrue(Conflicts.with(talk(1, "10:00", "10:30"), listOf(talk(2, "10:30", "11:00"))).isEmpty())
    }

    @Test fun sessionAndOwnTalkAreNotConflict() {
        val s = session(7, "09:20", "10:40")
        assertTrue(Conflicts.with(s, listOf(talk(1, "09:20", "10:10", session = 7))).isEmpty())
        assertTrue(Conflicts.with(talk(1, "09:20", "10:10", session = 7), listOf(s)).isEmpty())
    }

    @Test fun sessionConflictsWithTalkElsewhere() {
        val c = Conflicts.with(session(7, "09:20", "10:40"), listOf(talk(3, "10:30", "11:20")))
        assertEquals(listOf("t3"), c.map { it.key })
    }

    @Test fun sameIdDifferentKindIsDistinct() {
        // wyklad id=1 i sesja id=1 to rozne pozycje
        val c = Conflicts.with(talk(1, "10:00", "11:00"), listOf(session(1, "10:30", "11:30")))
        assertEquals(1, c.size)
    }

    @Test fun missingTimesNeverConflict() {
        val noEnd = AgendaSlot(9, false, "x", null, "2026-10-20 10:00:00", null)
        assertTrue(Conflicts.with(noEnd, listOf(talk(2, "09:00", "12:00"))).isEmpty())
    }

    @Test fun keysMarksBothSides() {
        val k = Conflicts.keys(listOf(talk(1, "10:00", "10:45"), talk(2, "10:30", "11:20"), talk(3, "12:00", "13:00")))
        assertEquals(setOf("t1", "t2"), k)
    }
}
