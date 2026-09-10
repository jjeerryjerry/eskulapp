package pl.eskulapp.mobile.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
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

@Composable
fun TalkScreen(vm: AppViewModel, talkId: Long, eventId: Long) {
    val talk by vm.repo.dao.talk(talkId).collectAsStateWithLifecycle(null)
    val speakers by vm.repo.dao.speakersForTalk(talkId).collectAsStateWithLifecycle(emptyList())
    val rooms by vm.repo.dao.rooms(eventId).collectAsStateWithLifecycle(emptyList())
    val reminderIds by vm.repo.dao.reminderIds().collectAsStateWithLifecycle(emptyList())
    val t = talk ?: return
    val room = rooms.firstOrNull { it.id == t.roomId }?.name
    val on = t.id in reminderIds

    Column(Modifier.fillMaxSize().background(Bg)) {
        BackTopBar("Prelekcja", onBack = { vm.nav.pop() })
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(20.dp)) {
            val time = listOfNotNull(hhmm(t.startsAt).ifBlank { null }, hhmm(t.endsAt).ifBlank { null }).joinToString(" - ")
            Row {
                if (time.isNotBlank()) Pill(time, Tint, Petrol)
                if (room != null) { Spacer(Modifier.width(8.dp)); Pill(room, Grey, Muted) }
            }
            Spacer(Modifier.height(16.dp))
            Text(t.title, fontSize = 22.sp, fontWeight = FontWeight.Bold, color = Ink, lineHeight = 28.sp)
            if (!t.abstract.isNullOrBlank()) {
                Spacer(Modifier.height(12.dp))
                Text(t.abstract!!, fontSize = 15.sp, color = Muted, lineHeight = 22.sp)
            }
            if (speakers.isNotEmpty()) {
                Spacer(Modifier.height(20.dp))
                Text("Prelegenci", fontWeight = FontWeight.SemiBold, color = Ink, fontSize = 15.sp)
                Spacer(Modifier.height(8.dp))
                speakers.forEach { s ->
                    Row(Modifier.fillMaxWidth().padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                        Box(Modifier.size(40.dp).clip(CircleShape).background(Tint), contentAlignment = Alignment.Center) {
                            Text(initials(s.firstName, s.lastName), color = Petrol, fontWeight = FontWeight.Bold)
                        }
                        Spacer(Modifier.width(12.dp))
                        Column {
                            Text((s.firstName + " " + s.lastName).trim(), fontWeight = FontWeight.SemiBold, color = Ink)
                            if (!s.title.isNullOrBlank()) Text(s.title!!, fontSize = 12.sp, color = Muted)
                        }
                    }
                }
            }
        }
        Button(
            onClick = { vm.toggleReminder(t.id, eventId, t.title, room, t.startsAt, !on) },
            colors = ButtonDefaults.buttonColors(containerColor = if (on) Coral else Petrol),
            shape = RoundedCornerShape(14.dp),
            modifier = Modifier.fillMaxWidth().padding(20.dp).height(54.dp)
        ) {
            Ico(R.drawable.ic_bell, if (on) Ink else Surface, 20)
            Spacer(Modifier.width(8.dp))
            Text(if (on) "Przypomnienie ustawione" else "Przypomnij mi", fontWeight = FontWeight.SemiBold, color = if (on) Ink else Surface)
        }
    }
}

@Composable
fun Pill(text: String, bg: androidx.compose.ui.graphics.Color, fg: androidx.compose.ui.graphics.Color) {
    Box(Modifier.clip(RoundedCornerShape(999.dp)).background(bg).padding(horizontal = 12.dp, vertical = 6.dp)) {
        Text(text, color = fg, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
    }
}
