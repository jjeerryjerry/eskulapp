package pl.eskulapp.mobile.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.launch
import pl.eskulapp.mobile.data.NotFoundException
import pl.eskulapp.mobile.data.Repo
import pl.eskulapp.mobile.agenda.AgendaSlot
import pl.eskulapp.mobile.agenda.Conflicts
import pl.eskulapp.mobile.data.local.ReminderEntity
import pl.eskulapp.mobile.data.local.SessionEntity
import pl.eskulapp.mobile.data.local.SessionReminderEntity
import pl.eskulapp.mobile.ratings.RATING_QUESTIONS
import pl.eskulapp.mobile.ratings.RatingPhase
import pl.eskulapp.mobile.ratings.RatingWindows
import pl.eskulapp.mobile.reminders.Reminders
import java.time.Instant

class AppViewModel(app: Application) : AndroidViewModel(app) {
    val repo = Repo.get(app)

    var startScreen by mutableStateOf<Screen?>(null); private set
    lateinit var nav: Navigator; private set

    var entryLoading by mutableStateOf(false); private set
    var entryError by mutableStateOf<String?>(null)

    init {
        viewModelScope.launch {
            val s = if (repo.dao.eventCount() > 0) Screen.Events else Screen.Entry
            nav = Navigator(s)
            startScreen = s
            // Odswiez dane z CDN w tle (manifest -> bundel tylko gdy wersja nowsza).
            if (s == Screen.Events) launch { repo.refreshAll() }
            // Zalegle glosy (oddane offline) poleca, gdy bedzie siec.
            launch { runCatching { repo.syncPendingRatings() } }
        }
    }

    fun addEvent(code: String) {
        val c = code.trim().uppercase()
        if (c.isEmpty()) { entryError = "Wpisz kod wydarzenia."; return }
        entryError = null; entryLoading = true
        viewModelScope.launch {
            try {
                val ev = repo.addOrRefresh(c)
                entryLoading = false
                nav.setStack(Screen.Events, Screen.Event(ev.id))
                // W tle: odtworz oceny tego urzadzenia (np. event usuniety i dodany ponownie).
                if (ev.ratingsEnabled) launch { runCatching { repo.restoreMyRatings(ev.id, ev.accessCode) } }
            } catch (e: NotFoundException) {
                entryLoading = false; entryError = e.message
            } catch (e: Exception) {
                entryLoading = false; entryError = "Brak połączenia. Sprawdź internet i spróbuj ponownie."
            }
        }
    }

    fun refresh(code: String, done: (Boolean) -> Unit = {}) {
        viewModelScope.launch { done(repo.refresh(code)) }
    }

    fun deleteEvent(id: Long) { viewModelScope.launch { repo.deleteEvent(id) } }

    fun markNewsRead(eventId: Long, newsIds: List<Long>) {
        if (newsIds.isEmpty()) return
        viewModelScope.launch {
            repo.dao.markNewsRead(newsIds.map { pl.eskulapp.mobile.data.local.NewsReadEntity(it, eventId) })
        }
    }

    fun toggleEventNotify(id: Long, on: Boolean) {
        viewModelScope.launch {
            if (on) repo.dao.addNotify(pl.eskulapp.mobile.data.local.EventNotifyEntity(id))
            else repo.dao.removeNotify(id)
        }
    }

    /** Ocena prelekcji: 3 odpowiedzi 1..10, zapis lokalny + wysylka w tle (SPEC-OCENY §5). */
    fun rateTalk(eventId: Long, eventCode: String, talkId: Long, answers: List<Int>) {
        if (answers.size != RATING_QUESTIONS.size || answers.any { it !in 1..10 }) return
        viewModelScope.launch { repo.rate(eventId, eventCode, talkId, answers) }
    }

    /** Ostrzezenie o konflikcie czasowym czekajace na decyzje uczestnika (null = brak). */
    var conflictPrompt by mutableStateOf<ConflictPrompt?>(null); private set

    fun confirmConflict() { val p = conflictPrompt ?: return; conflictPrompt = null; p.proceed() }
    fun dismissConflict() { conflictPrompt = null }

    fun toggleReminder(talkId: Long, eventId: Long, title: String, subtitle: String?, startsAt: String?, on: Boolean) {
        viewModelScope.launch {
            if (on) {
                val talk = repo.dao.talkOnce(talkId)
                val slot = AgendaSlot(talkId, false, title, subtitle, startsAt, talk?.endsAt, talk?.sessionId)
                withConflictCheck(eventId, slot) {
                    viewModelScope.launch {
                        val t = Reminders.triggerAt(startsAt) ?: (System.currentTimeMillis() + 5000)
                        repo.dao.addReminder(ReminderEntity(talkId, eventId, title, subtitle, t))
                        Reminders.schedule(getApplication(), talkId, title, subtitle, t)
                        scheduleRateReminder(talkId, eventId, title)
                    }
                }
            } else {
                repo.dao.removeReminder(talkId)
                Reminders.cancel(getApplication(), talkId)
            }
        }
    }

    /** Przypomnienie o calej sesji (10 min przed startem), niezalezne od podwykladow. */
    fun toggleSessionReminder(session: SessionEntity, roomName: String?, on: Boolean) {
        viewModelScope.launch {
            if (on) {
                val slot = AgendaSlot(session.id, true, session.title, roomName, session.startsAt, session.endsAt)
                withConflictCheck(session.eventId, slot) {
                    viewModelScope.launch {
                        val t = Reminders.triggerAt(session.startsAt) ?: (System.currentTimeMillis() + 5000)
                        repo.dao.addSessionReminder(SessionReminderEntity(session.id, session.eventId, session.title, roomName, t))
                        Reminders.scheduleSession(getApplication(), session.id, session.title, roomName, t)
                    }
                }
            } else {
                repo.dao.removeSessionReminder(session.id)
                Reminders.cancelSession(getApplication(), session.id)
            }
        }
    }

    /** Brak kolizji = od razu [proceed]; kolizja = ostrzezenie, decyzja zostaje u uczestnika. */
    private suspend fun withConflictCheck(eventId: Long, candidate: AgendaSlot, proceed: () -> Unit) {
        val conflicts = Conflicts.with(candidate, followedSlots(eventId))
        if (conflicts.isEmpty()) proceed() else conflictPrompt = ConflictPrompt(candidate, conflicts, proceed)
    }

    private suspend fun followedSlots(eventId: Long): List<AgendaSlot> {
        val rooms = repo.dao.roomsOnce(eventId).associate { it.id to it.name }
        return repo.dao.followedTalks(eventId).map {
            AgendaSlot(it.id, false, it.title, rooms[it.roomId], it.startsAt, it.endsAt, it.sessionId)
        } + repo.dao.followedSessions(eventId).map {
            AgendaSlot(it.id, true, it.title, rooms[it.roomId], it.startsAt, it.endsAt)
        }
    }

    /**
     * Przypomnienie "Oceń wykład" przy otwarciu okna ocen, tylko dla obserwowanych prelekcji
     * (dzwonek). Bez nowej zgody: korzysta z tego samego kanalu co przypomnienia o prelekcjach.
     */
    private suspend fun scheduleRateReminder(talkId: Long, eventId: Long, title: String) {
        val ev = repo.dao.eventOnce(eventId) ?: return
        val talk = repo.dao.talkOnce(talkId) ?: return
        if (!ev.ratingsEnabled) return
        val w = RatingWindows.compute(talk.startsAt, talk.endsAt, ev.ratingsOpenMin, ev.ratingsCloseMin, Instant.now())
        val opensAt = w.opensAt ?: return
        if (w.phase != RatingPhase.NOT_OPEN) return
        Reminders.scheduleRate(getApplication(), talkId, title, opensAt.toInstant().toEpochMilli())
    }
}

/** Ostrzezenie: [candidate] nachodzi na juz obserwowane [conflicts]. [proceed] ustawia mimo to. */
class ConflictPrompt(val candidate: AgendaSlot, val conflicts: List<AgendaSlot>, val proceed: () -> Unit)
