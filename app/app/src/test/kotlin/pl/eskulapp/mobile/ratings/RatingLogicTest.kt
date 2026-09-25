package pl.eskulapp.mobile.ratings

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.time.Instant
import java.util.TimeZone

/** Testy JVM logiki ocen (docs/SPEC-OCENY.md §7). Te same przypadki co web/tests/ratings_test.php. */
class RatingLogicTest {
    private lateinit var savedTz: TimeZone

    // Celowo obca strefa telefonu: okno liczymy w Europe/Warsaw, niezaleznie od niej.
    @Before fun setUp() { savedTz = TimeZone.getDefault(); TimeZone.setDefault(TimeZone.getTimeZone("America/New_York")) }
    @After fun tearDown() { TimeZone.setDefault(savedTz) }

    private fun utc(s: String): Instant = Instant.parse(s)
    private fun waw(local: String, plusSec: Long = 0): Instant =
        RatingWindows.parseLocal(local)!!.toInstant().plusSeconds(plusSec)
    private fun phase(start: String?, end: String?, now: Instant, open: Int = 10, close: Int = 30) =
        RatingWindows.compute(start, end, open, close, now).phase

    private val s = "2026-10-20 10:00:00"
    private val e = "2026-10-20 10:45:00"

    @Test fun granice_okna() {
        assertEquals("start+9:59", RatingPhase.NOT_OPEN, phase(s, e, waw(s, 9 * 60 + 59)))
        assertEquals("start+10:00", RatingPhase.OPEN, phase(s, e, waw(s, 10 * 60)))
        assertEquals("end+30:00", RatingPhase.OPEN, phase(s, e, waw(e, 30 * 60)))
        assertEquals("end+30:01", RatingPhase.CLOSED, phase(s, e, waw(e, 30 * 60 + 1)))
        assertEquals(RatingPhase.OPEN, phase(s, e, waw(e, 30 * 60).plusMillis(900)))
    }

    @Test fun konfiguracja_minut_per_event() {
        assertEquals(RatingPhase.OPEN, phase(s, e, waw(s), 0, 0))
        assertEquals(RatingPhase.CLOSED, phase(s, e, waw(e, 1), 0, 0))
        assertEquals(RatingPhase.NOT_OPEN, phase(s, e, waw(s, 4 * 60 + 59), 5, 60))
        assertEquals(RatingPhase.OPEN, phase(s, e, waw(e, 3600), 5, 60))
    }

    @Test fun brak_godzin_nieoceniana() {
        assertEquals(RatingPhase.UNRATEABLE, phase(null, e, waw(s)))
        assertEquals(RatingPhase.UNRATEABLE, phase(s, null, waw(s)))
        assertEquals(RatingPhase.UNRATEABLE, phase("smieci", e, waw(s)))
        assertNull("zla data", RatingWindows.parseLocal("2026-02-30 10:00:00"))
    }

    @Test fun strefa_warszawa_lato_i_zima() {
        assertEquals(RatingPhase.NOT_OPEN, phase("2026-07-01 10:00:00", "2026-07-01 11:00:00", utc("2026-07-01T08:09:59Z")))
        assertEquals(RatingPhase.OPEN, phase("2026-07-01 10:00:00", "2026-07-01 11:00:00", utc("2026-07-01T08:10:00Z")))
        assertEquals(RatingPhase.NOT_OPEN, phase("2026-12-01 10:00:00", "2026-12-01 11:00:00", utc("2026-12-01T09:09:59Z")))
        assertEquals(RatingPhase.OPEN, phase("2026-12-01 10:00:00", "2026-12-01 11:00:00", utc("2026-12-01T09:10:00Z")))
    }

    @Test fun zmiana_czasu_wiosna() {
        val st = "2026-03-29 01:30:00"
        val en = "2026-03-29 03:30:00"
        assertEquals(RatingPhase.NOT_OPEN, phase(st, en, utc("2026-03-29T00:39:59Z")))
        assertEquals(RatingPhase.OPEN, phase(st, en, utc("2026-03-29T00:40:00Z")))
        assertEquals(RatingPhase.OPEN, phase(st, en, utc("2026-03-29T02:00:00Z")))
        assertEquals(RatingPhase.CLOSED, phase(st, en, utc("2026-03-29T02:00:01Z")))
        val w = RatingWindows.compute("2026-03-29 01:55:00", en, 10, 30, utc("2026-03-29T01:05:00Z"))
        assertEquals(RatingPhase.OPEN, w.phase)
        assertEquals("2026-03-29T03:05+02:00", w.opensAt!!.toOffsetDateTime().toString())
    }

    @Test fun zmiana_czasu_jesien() {
        val st = "2026-10-25 01:30:00"
        val en = "2026-10-25 03:30:00"
        assertEquals(RatingPhase.NOT_OPEN, phase(st, en, utc("2026-10-24T23:39:59Z")))
        assertEquals(RatingPhase.OPEN, phase(st, en, utc("2026-10-24T23:40:00Z")))
        assertEquals(RatingPhase.OPEN, phase(st, en, utc("2026-10-25T03:00:00Z")))
        assertEquals(RatingPhase.CLOSED, phase(st, en, utc("2026-10-25T03:00:01Z")))
    }

    @Test fun godzina_nieistniejaca_i_podwojna_jak_na_serwerze() {
        assertEquals("2026-03-29T03:30+02:00", RatingWindows.parseLocal("2026-03-29 02:30:00")!!.toOffsetDateTime().toString())
        assertEquals("2026-10-25T02:30+01:00", RatingWindows.parseLocal("2026-10-25 02:30:00")!!.toOffsetDateTime().toString())
        assertEquals("2026-10-20T10:00+02:00", RatingWindows.parseLocal("2026-10-20T10:00")!!.toOffsetDateTime().toString())
    }

    // ---- stany sekcji "Oceń wykład"

    private fun panel(now: Instant, score: Int? = null, status: String? = null, error: String? = null, enabled: Boolean = true) =
        ratingPanel(enabled, RatingWindows.compute(s, e, 10, 30, now), score, status, error, now)

    @Test fun sekcja_ukryta_gdy_oceny_wylaczone_albo_brak_godzin() {
        assertNull(panel(waw(s, 1200), enabled = false))
        val now = waw(s, 1200)
        assertNull(ratingPanel(true, RatingWindows.compute(null, e, 10, 30, now), null, null, null, now))
    }

    @Test fun sekcja_jeszcze_nieaktywna() {
        val p = panel(waw(s, 60))!!
        assertFalse(p.enabled)
        assertEquals("Ocena od 10:10", p.message)
        val dayBefore = panel(waw(s, -86400))!!
        assertEquals("Ocena od 20.10, 10:10", dayBefore.message)
    }

    @Test fun sekcja_aktywna_i_oceniona() {
        val open = panel(waw(s, 1200))!!
        assertTrue(open.enabled)
        assertNull(open.selected)
        val rated = panel(waw(s, 1200), 8, RatingStatus.SYNCED)!!
        assertTrue(rated.enabled)
        assertEquals(8, rated.selected)
        assertEquals("Oceniono (8). Możesz zmienić do 11:15", rated.message)
        val pending = panel(waw(s, 1200), 6, RatingStatus.PENDING)!!
        assertEquals(6, pending.selected)
        assertTrue(pending.message.startsWith("Oceniono (6)."))
    }

    @Test fun sekcja_zamknieta_i_odrzucona() {
        val closed = panel(waw(e, 31 * 60))!!
        assertFalse(closed.enabled)
        assertEquals("Ocenianie zamknięte.", closed.message)
        val closedRated = panel(waw(e, 31 * 60), 9, RatingStatus.SYNCED)!!
        assertEquals(9, closedRated.selected)
        assertEquals("Oceniono (9). Ocenianie zamknięte.", closedRated.message)
        // glos oddany offline w oknie, doslany po zamknieciu: serwer 409 window_closed
        val rejected = panel(waw(e, 31 * 60), 9, RatingStatus.REJECTED, "window_closed")!!
        assertTrue(rejected.warning)
        assertNull(rejected.selected)
        assertEquals("Nie udało się zapisać, okno oceniania zamknięte.", rejected.message)
    }

    @Test fun teksty_bez_myslnikow_i_strzalek() {
        val nows = listOf(waw(s, -86400), waw(s, 60), waw(s, 1200), waw(e, 31 * 60))
        val texts = nows.flatMap { n ->
            listOf(null, RatingStatus.SYNCED, RatingStatus.PENDING, RatingStatus.REJECTED).mapNotNull { st ->
                panel(n, 7, st, "window_closed")?.message
            }
        }
        for (t in texts) assertFalse(t, Regex("[\\u2012-\\u2015\\u2190-\\u21FF\\u27F5-\\u27FF]| - ").containsMatchIn(t))
    }

    // ---- odpowiedzi serwera

    @Test fun mapowanie_odpowiedzi_http() {
        assertEquals(RatingResult.Saved(7), ratingResultFor(200, """{"ok":true,"score":7}""", 7))
        assertEquals(RatingResult.Rejected("window_closed"),
            ratingResultFor(409, """{"error":"window_closed","closed_at":"2026-10-20T11:15:00+02:00"}""", 7))
        assertEquals(RatingResult.Rejected("ratings_disabled"), ratingResultFor(403, """{"error":"ratings_disabled"}""", 7))
        assertEquals(RatingResult.Rejected("http_404"), ratingResultFor(404, null, 7))
        assertEquals(RatingResult.Retry, ratingResultFor(429, """{"error":"rate_limited"}""", 7))
        assertEquals(RatingResult.Retry, ratingResultFor(503, """{"error":"unavailable"}""", 7))
        assertEquals(RatingResult.Retry, ratingResultFor(-1, null, 7))
    }
}
