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
import pl.eskulapp.mobile.ui.*
import pl.eskulapp.mobile.ui.theme.*

@Composable
fun AgendaScreen(vm: AppViewModel, id: Long) {
    val days by vm.repo.dao.days(id).collectAsStateWithLifecycle(emptyList())
    val rooms by vm.repo.dao.rooms(id).collectAsStateWithLifecycle(emptyList())
    val talks by vm.repo.dao.talks(id).collectAsStateWithLifecycle(emptyList())
    val speakers by vm.repo.dao.speakers(id).collectAsStateWithLifecycle(emptyList())
    val talkSpeakers by vm.repo.dao.talkSpeakers(id).collectAsStateWithLifecycle(emptyList())
    val reminderIds by vm.repo.dao.reminderIds().collectAsStateWithLifecycle(emptyList())

    var dayId by remember(days) { mutableStateOf(days.firstOrNull()?.id) }
    var roomId by remember { mutableStateOf<Long?>(null) }
    var onlyFollowed by remember { mutableStateOf(false) }

    val byId = speakers.associateBy { it.id }
    val talkSpeakerNames: Map<Long, String> = talkSpeakers.groupBy { it.talkId }.mapValues { (_, list) ->
        list.mapNotNull { byId[it.speakerId] }
            .map { (it.firstName.trim() + " " + it.lastName.trim()).trim() }
            .filter { it.isNotBlank() }
            .joinToString(", ")
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
        val shown = talks.filter {
            (dayId == null || it.dayId == dayId) &&
                (roomId == null || it.roomId == roomId) &&
                (!onlyFollowed || it.id in reminderIds)
        }
        if (shown.isEmpty()) {
            Box(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) {
                Text(if (onlyFollowed) "Nie obserwujesz jeszcze żadnej prelekcji." else "Brak prelekcji w tym widoku.", color = Muted)
            }
        } else {
            LazyColumn(Modifier.weight(1f), contentPadding = PaddingValues(horizontal = 20.dp, vertical = 4.dp)) {
                items(shown, key = { it.id }) { t ->
                    val roomName = rooms.firstOrNull { it.id == t.roomId }?.name
                    val sub = listOfNotNull(roomName, talkSpeakerNames[t.id]?.ifBlank { null }).joinToString(" · ")
                    val on = t.id in reminderIds
                    TalkRow(
                        time = hhmm(t.startsAt), title = t.title, subtitle = sub, reminder = on,
                        onToggleReminder = { vm.toggleReminder(t.id, id, t.title, roomName, t.startsAt, !on) },
                        onClick = { vm.nav.push(Screen.Talk(t.id, id)) },
                    )
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
    time: String, title: String, subtitle: String, reminder: Boolean,
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
        }
        // Osobny click na dzwonku: tylko toggle przypomnienia, NIE otwiera prelekcji.
        Box(
            Modifier.size(40.dp).clip(RoundedCornerShape(11.dp))
                .background(if (reminder) CoralTint else Grey)
                .clickable { onToggleReminder() },
            contentAlignment = Alignment.Center
        ) {
            Ico(R.drawable.ic_bell, if (reminder) Coral else Faint, 22)
        }
    }
}
