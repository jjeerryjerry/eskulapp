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
import pl.eskulapp.mobile.reminders.Reminders

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

    fun toggleReminder(talkId: Long, eventId: Long, title: String, subtitle: String?, startsAt: String?, on: Boolean) {
        viewModelScope.launch {
            if (on) {
                val t = Reminders.triggerAt(startsAt) ?: (System.currentTimeMillis() + 5000)
                repo.dao.addReminder(ReminderEntity(talkId, eventId, title, subtitle, t))
                Reminders.schedule(getApplication(), talkId, title, subtitle, t)
            } else {
                repo.dao.removeReminder(talkId)
                Reminders.cancel(getApplication(), talkId)
            }
        }
    }
}
