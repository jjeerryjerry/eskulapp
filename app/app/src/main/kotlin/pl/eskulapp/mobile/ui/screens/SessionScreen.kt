package pl.eskulapp.mobile.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
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

/** Szczegoly sesji: moderatorzy, podwyklady (z wlasnymi dzwonkami), przypomnienie o sesji. */
@Composable
fun SessionScreen(vm: AppViewModel, sessionId: Long, eventId: Long) {
    val session by vm.repo.dao.session(sessionId).collectAsStateWithLifecycle(null)
    val talks by vm.repo.dao.talksForSession(sessionId).collectAsStateWithLifecycle(emptyList())
    val moderators by vm.repo.dao.moderatorsForSession(sessionId).collectAsStateWithLifecycle(emptyList())
    val rooms by vm.repo.dao.rooms(eventId).collectAsStateWithLifecycle(emptyList())
    val speakers by vm.repo.dao.speakers(eventId).collectAsStateWithLifecycle(emptyList())
    val talkSpeakers by vm.repo.dao.talkSpeakers(eventId).collectAsStateWithLifecycle(emptyList())
    val reminderIds by vm.repo.dao.reminderIds().collectAsStateWithLifecycle(emptyList())
    val sessionReminderIds by vm.repo.dao.sessionReminderIds().collectAsStateWithLifecycle(emptyList())
    val x = session ?: return
    val room = rooms.firstOrNull { it.id == x.roomId }?.name
    val on = x.id in sessionReminderIds
    val byId = speakers.associateBy { it.id }
    val names = talkSpeakers.groupBy { it.talkId }.mapValues { (_, l) ->
        l.mapNotNull { byId[it.speakerId] }.joinToString(", ") { (it.firstName + " " + it.lastName).trim() }
    }

    Column(Modifier.fillMaxSize().background(Bg)) {
        BackTopBar("Sesja", onBack = { vm.nav.pop() })
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(20.dp)) {
            val time = listOfNotNull(hhmm(x.startsAt).ifBlank { null }, hhmm(x.endsAt).ifBlank { null }).joinToString(" - ")
            Row {
                if (time.isNotBlank()) Pill(time, Tint, Petrol)
                if (room != null) { Spacer(Modifier.width(8.dp)); Pill(room, Grey, Muted) }
            }
            Spacer(Modifier.height(16.dp))
            Text(x.title, fontSize = 22.sp, fontWeight = FontWeight.Bold, color = Ink, lineHeight = 28.sp)
            if (!x.description.isNullOrBlank()) {
                Spacer(Modifier.height(12.dp))
                Text(x.description, fontSize = 15.sp, color = Muted, lineHeight = 22.sp)
            }
            if (moderators.isNotEmpty()) {
                Spacer(Modifier.height(20.dp))
                Text(if (moderators.size == 1) "Moderator" else "Moderatorzy", fontWeight = FontWeight.SemiBold, color = Ink, fontSize = 15.sp)
                Spacer(Modifier.height(8.dp))
                moderators.forEach { s ->
                    Row(
                        Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp))
                            .clickable { vm.nav.push(Screen.SpeakerDetail(s.id, eventId)) }.padding(vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Box(Modifier.size(40.dp).clip(CircleShape).background(Tint), contentAlignment = Alignment.Center) {
                            Text(initials(s.firstName, s.lastName), color = Petrol, fontWeight = FontWeight.Bold)
                        }
                        Spacer(Modifier.width(12.dp))
                        Column(Modifier.weight(1f)) {
                            Text((s.firstName + " " + s.lastName).trim(), fontWeight = FontWeight.SemiBold, color = Ink)
                            if (!s.title.isNullOrBlank()) Text(s.title, fontSize = 12.sp, color = Muted)
                        }
                        Ico(R.drawable.ic_chevron, Line, 18)
                    }
                }
            }
            if (talks.isNotEmpty()) {
                Spacer(Modifier.height(20.dp))
                Text("Wykłady w sesji", fontWeight = FontWeight.SemiBold, color = Ink, fontSize = 15.sp)
                Spacer(Modifier.height(8.dp))
                talks.forEach { t ->
                    val tOn = t.id in reminderIds
                    Row(
                        Modifier.fillMaxWidth().padding(vertical = 5.dp).clip(RoundedCornerShape(12.dp))
                            .background(Surface).border(1.dp, Line, RoundedCornerShape(12.dp))
                            .clickable { vm.nav.push(Screen.Talk(t.id, eventId)) }.padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(hhmm(t.startsAt), color = Petrol, fontWeight = FontWeight.SemiBold, fontSize = 13.sp, modifier = Modifier.width(48.dp))
                        Column(Modifier.weight(1f)) {
                            Text(t.title, fontWeight = FontWeight.SemiBold, fontSize = 14.sp, color = Ink, lineHeight = 18.sp)
                            val sub = names[t.id].orEmpty()
                            if (sub.isNotBlank()) Text(sub, fontSize = 12.sp, color = Muted, modifier = Modifier.padding(top = 3.dp))
                        }
                        BellButton(tOn, 34) { vm.toggleReminder(t.id, eventId, t.title, room, t.startsAt, !tOn) }
                    }
                }
            }
        }
        Button(
            onClick = { vm.toggleSessionReminder(x, room, !on) },
            colors = ButtonDefaults.buttonColors(containerColor = if (on) Coral else Petrol),
            shape = RoundedCornerShape(14.dp),
            modifier = Modifier.fillMaxWidth().padding(20.dp).height(54.dp)
        ) {
            Ico(R.drawable.ic_bell, if (on) Ink else Surface, 20)
            Spacer(Modifier.width(8.dp))
            Text(if (on) "Przypomnienie o sesji ustawione" else "Przypomnij o sesji", fontWeight = FontWeight.SemiBold, color = if (on) Ink else Surface)
        }
    }
}
