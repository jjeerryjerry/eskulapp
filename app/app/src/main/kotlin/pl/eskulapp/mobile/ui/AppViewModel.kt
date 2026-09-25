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
import pl.eskulapp.mobile.data.local.ReminderEntity
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

    /** Ocena prelekcji 1..10: zapis lokalny + wysylka w tle (SPEC-OCENY §5). */
    fun rateTalk(eventId: Long, eventCode: String, talkId: Long, score: Int) {
        if (score !in 1..10) return
        viewModelScope.launch { repo.rate(eventId, eventCode, talkId, score) }
    }

    fun toggleReminder(talkId: Long, eventId: Long, title: String, subtitle: String?, startsAt: String?, on: Boolean) {
        viewModelScope.launch {
            if (on) {
                val t = Reminders.triggerAt(startsAt) ?: (System.currentTimeMillis() + 5000)
                repo.dao.addReminder(ReminderEntity(talkId, eventId, title, subtitle, t))
                Reminders.schedule(getApplication(), talkId, title, subtitle, t)
                scheduleRateReminder(talkId, eventId, title)
            } else {
                repo.dao.removeReminder(talkId)
                Reminders.cancel(getApplication(), talkId)
            }
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
