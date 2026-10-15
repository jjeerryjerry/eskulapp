package pl.eskulapp.mobile.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import pl.eskulapp.mobile.R
import pl.eskulapp.mobile.agenda.AgendaSlot
import pl.eskulapp.mobile.agenda.Conflicts
import pl.eskulapp.mobile.data.local.SessionEntity
import pl.eskulapp.mobile.data.local.TalkEntity
import pl.eskulapp.mobile.ui.*
import pl.eskulapp.mobile.ui.theme.*

/** Pozycja listy agendy: wyklad samodzielny albo sesja z podwykladami. */
private sealed interface AgendaItem {
    val startsAt: String?
    val sort: Int
    data class Single(val talk: TalkEntity) : AgendaItem {
        override val startsAt get() = talk.startsAt
        override val sort get() = talk.sort
    }
    data class Block(val session: SessionEntity, val talks: List<TalkEntity>) : AgendaItem {
        override val startsAt get() = session.startsAt
        override val sort get() = session.sort
    }
}

@Composable
fun AgendaScreen(vm: AppViewModel, id: Long) {
    val days by vm.repo.dao.days(id).collectAsStateWithLifecycle(emptyList())
    val rooms by vm.repo.dao.rooms(id).collectAsStateWithLifecycle(emptyList())
    val talks by vm.repo.dao.talks(id).collectAsStateWithLifecycle(emptyList())
    val sessions by vm.repo.dao.sessions(id).collectAsStateWithLifecycle(emptyList())
    val moderators by vm.repo.dao.sessionModerators(id).collectAsStateWithLifecycle(emptyList())
    val speakers by vm.repo.dao.speakers(id).collectAsStateWithLifecycle(emptyList())
    val talkSpeakers by vm.repo.dao.talkSpeakers(id).collectAsStateWithLifecycle(emptyList())
    val reminderIds by vm.repo.dao.reminderIds().collectAsStateWithLifecycle(emptyList())
    val sessionReminderIds by vm.repo.dao.sessionReminderIds().collectAsStateWithLifecycle(emptyList())

    var dayId by remember(days) { mutableStateOf(days.firstOrNull()?.id) }
    var roomId by remember { mutableStateOf<Long?>(null) }
    var onlyFollowed by remember { mutableStateOf(false) }

    val byId = speakers.associateBy { it.id }
    val roomName = rooms.associate { it.id to it.name }
    fun names(ids: List<Long>) = ids.mapNotNull { byId[it] }
        .map { (it.firstName.trim() + " " + it.lastName.trim()).trim() }
        .filter { it.isNotBlank() }
        .joinToString(", ")
    val talkSpeakerNames: Map<Long, String> = talkSpeakers.groupBy { it.talkId }.mapValues { (_, l) -> names(l.map { it.speakerId }) }
    val moderatorNames: Map<Long, String> = moderators.groupBy { it.sessionId }.mapValues { (_, l) -> names(l.map { it.speakerId }) }

    // Kolizje czasowe miedzy obserwowanymi pozycjami (oznaczenie na liscie).
    val conflictKeys = remember(talks, sessions, reminderIds, sessionReminderIds) {
        Conflicts.keys(
            talks.filter { it.id in reminderIds }.map { AgendaSlot(it.id, false, it.title, null, it.startsAt, it.endsAt, it.sessionId) } +
                sessions.filter { it.id in sessionReminderIds }.map { AgendaSlot(it.id, true, it.title, null, it.startsAt, it.endsAt) }
        )
    }

    val items: List<AgendaItem> = remember(talks, sessions) {
        val sessionIds = sessions.map { it.id }.toSet()
        val inSession = talks.filter { it.sessionId in sessionIds }.groupBy { it.sessionId }
        (talks.filter { it.sessionId !in sessionIds }.map { AgendaItem.Single(it) } +
            sessions.map { AgendaItem.Block(it, inSession[it.id].orEmpty()) })
            .sortedWith(compareBy<AgendaItem>({ it.startsAt ?: "" }, { it.sort }))
    }

    Column(Modifier.fillMaxSize().background(Bg)) {
        BackTopBar("Agenda", onBack = { vm.nav.pop() }, trailing = {
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.clickable { onlyFollowed = !onlyFollowed }) {
                Checkbox(
                    checked = onlyFollowed, onCheckedChange = { onlyFollowed = it },
                    colors = CheckboxDefaults.colors(checkedColor = Petrol, uncheckedColor = Faint)
                )
                Text("Obserwowane", fontSize = 13.sp, color = if (onlyFollowed) Petrol else Muted, fontWeight = FontWeight.SemiBold)
            }
        })
        if (days.isNotEmpty()) {
            Row(Modifier.background(Surface).horizontalScroll(rememberScrollState()).padding(horizontal = 20.dp)) {
                days.forEach { d ->
                    val sel = d.id == dayId
                    Column(Modifier.padding(end = 24.dp).clickable { dayId = d.id }) {
                        Text(
                            (d.label ?: "Dzień") + "  " + dayShort(d.date),
                            fontSize = 15.sp, color = if (sel) Petrol else Faint,
                            fontWeight = if (sel) FontWeight.SemiBold else FontWeight.Medium,
                            modifier = Modifier.padding(bottom = 12.dp)
                        )
                        Box(Modifier.height(2.5.dp).width(if (sel) 70.dp else 0.dp).background(Petrol))
                    }
                }
            }
        }
        Row(Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 20.dp, vertical = 14.dp)) {
            Chip("Wszystkie sale", roomId == null) { roomId = null }
            rooms.forEach { r -> Spacer(Modifier.width(8.dp)); Chip(r.name, roomId == r.id) { roomId = r.id } }
        }
        fun inView(day: Long?, room: Long?) = (dayId == null || day == dayId) && (roomId == null || room == roomId)
        // Obserwowane: sesja widoczna gdy obserwujesz ja albo ktorys z jej podwykladow;
        // przy obserwowanej sesji widac wszystkie podwyklady, inaczej tylko obserwowane.
        val shown = items.mapNotNull { item ->
            when (item) {
                is AgendaItem.Single -> item.takeIf {
                    inView(it.talk.dayId, it.talk.roomId) && (!onlyFollowed || it.talk.id in reminderIds)
                }
                is AgendaItem.Block -> {
                    if (!inView(item.session.dayId, item.session.roomId)) null
                    else if (!onlyFollowed || item.session.id in sessionReminderIds) item
                    else item.talks.filter { it.id in reminderIds }.takeIf { it.isNotEmpty() }?.let { item.copy(talks = it) }
                }
            }
        }
        if (shown.isEmpty()) {
            Box(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) {
                Text(if (onlyFollowed) "Nie obserwujesz jeszcze żadnej prelekcji." else "Brak prelekcji w tym widoku.", color = Muted)
            }
        } else {
            LazyColumn(Modifier.weight(1f), contentPadding = PaddingValues(horizontal = 20.dp, vertical = 4.dp)) {
                items(shown, key = { if (it is AgendaItem.Block) "s${it.session.id}" else "t${(it as AgendaItem.Single).talk.id}" }) { item ->
                    when (item) {
                        is AgendaItem.Single -> {
                            val t = item.talk
                            val room = roomName[t.roomId]
                            val on = t.id in reminderIds
                            TalkRow(
                                time = hhmm(t.startsAt),
                                title = t.title,
                                subtitle = listOfNotNull(room, talkSpeakerNames[t.id]?.ifBlank { null }).joinToString(" · "),
                                reminder = on, conflict = "t${t.id}" in conflictKeys,
                                onToggleReminder = { vm.toggleReminder(t.id, id, t.title, room, t.startsAt, !on) },
                                onClick = { vm.nav.push(Screen.Talk(t.id, id)) },
                            )
                        }
                        is AgendaItem.Block -> {
                            val x = item.session
                            val room = roomName[x.roomId]
                            val on = x.id in sessionReminderIds
                            SessionCard(
                                time = listOf(hhmm(x.startsAt), hhmm(x.endsAt)).filter { it.isNotBlank() }.joinToString(" - "),
                                title = x.title,
                                subtitle = listOfNotNull(room, moderatorNames[x.id]?.ifBlank { null }?.let { "Moderacja: $it" }).joinToString(" · "),
                                reminder = on, conflict = "s${x.id}" in conflictKeys,
                                onToggleReminder = { vm.toggleSessionReminder(x, room, !on) },
                                onClick = { vm.nav.push(Screen.Session(x.id, id)) },
                            ) {
                                item.talks.forEach { t ->
                                    val tOn = t.id in reminderIds
                                    SubTalkRow(
                                        time = hhmm(t.startsAt), title = t.title,
                                        subtitle = talkSpeakerNames[t.id].orEmpty(),
                                        reminder = tOn, conflict = "t${t.id}" in conflictKeys,
                                        onToggleReminder = { vm.toggleReminder(t.id, id, t.title, roomName[t.roomId], t.startsAt, !tOn) },
                                        onClick = { vm.nav.push(Screen.Talk(t.id, id)) },
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun Chip(label: String, active: Boolean, onClick: () -> Unit) {
    Box(
        Modifier.clip(RoundedCornerShape(999.dp))
            .background(if (active) Petrol else Surface)
            .then(if (active) Modifier else Modifier.border(1.dp, Line, RoundedCornerShape(999.dp)))
            .clickable { onClick() }.padding(horizontal = 14.dp, vertical = 8.dp)
    ) {
        Text(label, color = if (active) Surface else Ink, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
    }
}

@Composable
private fun TalkRow(
    time: String, title: String, subtitle: String, reminder: Boolean, conflict: Boolean,
    onToggleReminder: () -> Unit, onClick: () -> Unit
) {
    Row(
        Modifier.fillMaxWidth().padding(vertical = 6.dp).clip(RoundedCornerShape(14.dp))
            .background(Surface).border(1.dp, Line, RoundedCornerShape(14.dp))
            .clickable { onClick() }.padding(14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(time, color = Petrol, fontWeight = FontWeight.SemiBold, fontSize = 14.sp, modifier = Modifier.width(52.dp))
        Column(Modifier.weight(1f)) {
            Text(title, fontWeight = FontWeight.SemiBold, fontSize = 15.sp, color = Ink, lineHeight = 19.sp)
            if (subtitle.isNotBlank()) Text(subtitle, fontSize = 12.sp, color = Muted, modifier = Modifier.padding(top = 3.dp))
            if (conflict) ConflictLabel()
        }
        BellButton(reminder, 40, onToggleReminder)
    }
}

/** Karta sesji: naglowek (czas, tytul, sala, moderacja, dzwonek sesji) + podwyklady. */
@Composable
private fun SessionCard(
    time: String, title: String, subtitle: String, reminder: Boolean, conflict: Boolean,
    onToggleReminder: () -> Unit, onClick: () -> Unit, content: @Composable ColumnScope.() -> Unit,
) {
    val shape = RoundedCornerShape(14.dp)
    Column(
        Modifier.fillMaxWidth().padding(vertical = 6.dp).clip(shape)
            .background(Surface).border(1.dp, Tint, shape)
    ) {
        Row(
            Modifier.fillMaxWidth().background(Tint.copy(alpha = 0.45f)).clickable { onClick() }.padding(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("SESJA", color = CoralDark, fontWeight = FontWeight.Bold, fontSize = 11.sp, letterSpacing = 1.sp)
                    if (time.isNotBlank()) {
                        Spacer(Modifier.width(8.dp))
                        Text(time, color = Petrol, fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
                    }
                }
                Text(title, fontWeight = FontWeight.Bold, fontSize = 16.sp, color = Ink, lineHeight = 20.sp, modifier = Modifier.padding(top = 3.dp))
                if (subtitle.isNotBlank()) Text(subtitle, fontSize = 12.sp, color = Muted, modifier = Modifier.padding(top = 3.dp))
                if (conflict) ConflictLabel()
            }
            BellButton(reminder, 40, onToggleReminder)
        }
        Column(Modifier.padding(start = 14.dp, end = 10.dp, top = 4.dp, bottom = 8.dp)) { content() }
    }
}

@Composable
private fun SubTalkRow(
    time: String, title: String, subtitle: String, reminder: Boolean, conflict: Boolean,
    onToggleReminder: () -> Unit, onClick: () -> Unit
) {
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp)).clickable { onClick() }.padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(time, color = Petrol, fontWeight = FontWeight.SemiBold, fontSize = 13.sp, modifier = Modifier.width(48.dp))
        Box(Modifier.width(2.dp).height(34.dp).background(Tint))
        Spacer(Modifier.width(10.dp))
        Column(Modifier.weight(1f)) {
            Text(title, fontWeight = FontWeight.SemiBold, fontSize = 14.sp, color = Ink, lineHeight = 18.sp)
            if (subtitle.isNotBlank()) Text(subtitle, fontSize = 12.sp, color = Muted, modifier = Modifier.padding(top = 2.dp))
            if (conflict) ConflictLabel()
        }
        BellButton(reminder, 34, onToggleReminder)
    }
}

/** Osobny click na dzwonku: tylko toggle przypomnienia, NIE otwiera szczegolow. */
@Composable
fun BellButton(on: Boolean, size: Int, onToggle: () -> Unit) {
    Box(
        Modifier.size(size.dp).clip(RoundedCornerShape(11.dp))
            .background(if (on) CoralTint else Grey)
            .clickable { onToggle() },
        contentAlignment = Alignment.Center
    ) {
        Ico(R.drawable.ic_bell, if (on) Coral else Faint, if (size >= 40) 22 else 19)
    }
}

@Composable
fun ConflictLabel() {
    Text("Kolizja czasowa", fontSize = 12.sp, color = CoralDark, fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(top = 3.dp))
}
