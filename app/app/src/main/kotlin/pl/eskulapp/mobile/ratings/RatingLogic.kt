package pl.eskulapp.mobile.ratings

import java.time.Duration
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.time.format.ResolverStyle

// Oceny prelekcji 1-10 (docs/SPEC-OCENY.md). Czysta logika BEZ Androida, testy JVM
// w src/test. Apka liczy okno lokalnie tylko dla UI; o przyjeciu glosu decyduje serwer.

enum class RatingPhase { UNRATEABLE, NOT_OPEN, OPEN, CLOSED }

data class RatingWindow(val phase: RatingPhase, val opensAt: ZonedDateTime?, val closesAt: ZonedDateTime?)

/** Status lokalnego glosu (tabela Room talk_ratings). */
object RatingStatus {
    const val PENDING = "pending"   // zapisany lokalnie, czeka na wyslanie
    const val SYNCED = "synced"     // serwer przyjal (200)
    const val REJECTED = "rejected" // serwer odrzucil na stale (np. window_closed)
}

object RatingWindows {
    val WARSAW: ZoneId = ZoneId.of("Europe/Warsaw")
    const val DEFAULT_OPEN_MIN = 10
    const val DEFAULT_CLOSE_MIN = 30

    private val FMT_SEC = DateTimeFormatter.ofPattern("uuuu-MM-dd HH:mm:ss").withResolverStyle(ResolverStyle.STRICT)
    private val FMT_MIN = DateTimeFormatter.ofPattern("uuuu-MM-dd HH:mm").withResolverStyle(ResolverStyle.STRICT)
    private val HM = DateTimeFormatter.ofPattern("HH:mm")
    private val DM_HM = DateTimeFormatter.ofPattern("dd.MM, HH:mm")

    /**
     * "yyyy-MM-dd HH:mm[:ss]" w czasie lokalnym Warszawy -> chwila. Zmiana czasu jak na
     * serwerze (Ratings::parseLocal): godzina nieistniejaca przesuwa sie do przodu o luke,
     * godzina podwojna = pozniejsze wystapienie (czas zimowy).
     */
    fun parseLocal(s: String?): ZonedDateTime? {
        val t = s?.trim()?.replace('T', ' ') ?: return null
        val ldt = try {
            when (t.length) {
                19 -> LocalDateTime.parse(t, FMT_SEC)
                16 -> LocalDateTime.parse(t, FMT_MIN)
                else -> return null
            }
        } catch (e: Exception) {
            return null
        }
        return ZonedDateTime.of(ldt, WARSAW).withLaterOffsetAtOverlap()
    }

    /**
     * Okno: od starts_at + openAfterStartMin do ends_at + closeAfterEndMin, granice wlacznie
     * z dokladnoscia do sekundy (start+10:00 otwarte, end+30:00 otwarte, end+30:01 zamkniete).
     * Minuty dodawane w czasie rzeczywistym, wiec zmiana czasu nie przesuwa okna.
     */
    fun compute(startsAt: String?, endsAt: String?, openAfterStartMin: Int, closeAfterEndMin: Int, now: Instant): RatingWindow {
        val start = parseLocal(startsAt)
        val end = parseLocal(endsAt)
        if (start == null || end == null) return RatingWindow(RatingPhase.UNRATEABLE, null, null)
        val opens = start.plus(Duration.ofMinutes(openAfterStartMin.toLong()))
        val closes = end.plus(Duration.ofMinutes(closeAfterEndMin.toLong()))
        val t = now.epochSecond
        val phase = when {
            t < opens.toEpochSecond() -> RatingPhase.NOT_OPEN
            t > closes.toEpochSecond() -> RatingPhase.CLOSED
            else -> RatingPhase.OPEN
        }
        return RatingWindow(phase, opens, closes)
    }

    /** "HH:mm" (dzis) albo "dd.MM, HH:mm" (inny dzien), w czasie Warszawy jak agenda. */
    fun clock(at: ZonedDateTime, now: Instant): String {
        val local = at.withZoneSameInstant(WARSAW)
        val today = now.atZone(WARSAW).toLocalDate()
        return if (local.toLocalDate() == today) local.format(HM) else local.format(DM_HM)
    }
}

/** Co pokazac w sekcji "Oceń wykład" (tekst, aktywnosc przyciskow, zaznaczona ocena). */
data class RatingPanel(val enabled: Boolean, val message: String, val selected: Int?, val warning: Boolean = false)

/**
 * Stan sekcji oceny. null = sekcji nie pokazujemy (oceny wylaczone albo prelekcja bez godzin).
 * Bez sredniej: uczestnik nie widzi wynikow.
 */
fun ratingPanel(
    ratingsEnabled: Boolean,
    window: RatingWindow,
    score: Int?,
    status: String?,
    error: String?,
    now: Instant,
): RatingPanel? {
    if (!ratingsEnabled || window.phase == RatingPhase.UNRATEABLE) return null
    val open = window.phase == RatingPhase.OPEN
    val until = window.closesAt?.let { RatingWindows.clock(it, now) }.orEmpty()
    val kept = if (status == RatingStatus.SYNCED || status == RatingStatus.PENDING) score else null
    if (status == RatingStatus.REJECTED) {
        val msg = when (error) {
            "window_closed" -> "Nie udało się zapisać, okno oceniania zamknięte."
            "window_not_open" -> "Nie udało się zapisać, ocenianie jeszcze się nie zaczęło."
            "ratings_disabled" -> "Nie udało się zapisać, oceny są wyłączone."
            else -> "Nie udało się zapisać oceny."
        }
        return RatingPanel(open, msg, null, warning = true)
    }
    return when (window.phase) {
        RatingPhase.NOT_OPEN ->
            RatingPanel(false, "Ocena od " + RatingWindows.clock(window.opensAt!!, now), null)
        RatingPhase.OPEN -> when {
            kept != null && status == RatingStatus.PENDING ->
                RatingPanel(true, "Oceniono ($kept). Zapiszemy ocenę, gdy będzie internet.", kept)
            kept != null -> RatingPanel(true, "Oceniono ($kept). Możesz zmienić do $until", kept)
            else -> RatingPanel(true, "Wybierz ocenę od 1 do 10. Głos jest anonimowy.", null)
        }
        RatingPhase.CLOSED -> when {
            kept != null && status == RatingStatus.PENDING ->
                RatingPanel(false, "Oceniono ($kept). Zapiszemy ocenę, gdy będzie internet.", kept)
            kept != null -> RatingPanel(false, "Oceniono ($kept). Ocenianie zamknięte.", kept)
            else -> RatingPanel(false, "Ocenianie zamknięte.", null)
        }
        RatingPhase.UNRATEABLE -> null
    }
}

/** Wynik wyslania glosu na serwer. */
sealed interface RatingResult {
    data class Saved(val score: Int) : RatingResult
    /** Odrzucony na stale (okno, wylaczone oceny, brak prelekcji, walidacja): nie ponawiamy. */
    data class Rejected(val error: String) : RatingResult
    /** Chwilowy problem (siec, 429, 5xx): ponawiamy pozniej (WorkManager, backoff). */
    data object Retry : RatingResult
}

private val ERROR_RE = Regex("\"error\"\\s*:\\s*\"([a-z_]+)\"")

/** Odpowiedz HTTP z POST .../rating -> RatingResult. Czysta funkcja (testy JVM). */
fun ratingResultFor(httpCode: Int, body: String?, score: Int): RatingResult = when {
    httpCode in 200..299 -> RatingResult.Saved(score)
    httpCode == 408 || httpCode == 429 || httpCode >= 500 || httpCode <= 0 -> RatingResult.Retry
    else -> RatingResult.Rejected(body?.let { ERROR_RE.find(it)?.groupValues?.get(1) } ?: "http_$httpCode")
}
