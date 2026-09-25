package pl.eskulapp.mobile.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.delay
import pl.eskulapp.mobile.R
import pl.eskulapp.mobile.ratings.RatingPanel
import pl.eskulapp.mobile.ratings.RatingWindows
import pl.eskulapp.mobile.ratings.ratingPanel
import pl.eskulapp.mobile.ui.*
import pl.eskulapp.mobile.ui.theme.*
import java.time.Instant

@Composable
fun TalkScreen(vm: AppViewModel, talkId: Long, eventId: Long) {
    val talk by vm.repo.dao.talk(talkId).collectAsStateWithLifecycle(null)
    val speakers by vm.repo.dao.speakersForTalk(talkId).collectAsStateWithLifecycle(emptyList())
    val rooms by vm.repo.dao.rooms(eventId).collectAsStateWithLifecycle(emptyList())
    val reminderIds by vm.repo.dao.reminderIds().collectAsStateWithLifecycle(emptyList())
    val event by vm.repo.dao.event(eventId).collectAsStateWithLifecycle(null)
    val rating by vm.repo.dao.rating(talkId).collectAsStateWithLifecycle(null)
    // "teraz" odswiezane co 15 s: stan okna ocen zmienia sie bez wychodzenia z ekranu
    val now by produceState(Instant.now()) {
        while (true) { delay(15_000); value = Instant.now() }
    }
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
            val ev = event
            if (ev != null) {
                val window = RatingWindows.compute(t.startsAt, t.endsAt, ev.ratingsOpenMin, ev.ratingsCloseMin, now)
                val panel = ratingPanel(ev.ratingsEnabled, window, rating?.score, rating?.status, rating?.error, now)
                if (panel != null) {
                    Spacer(Modifier.height(24.dp))
                    RatingSection(panel) { score -> vm.rateTalk(eventId, ev.accessCode, t.id, score) }
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

/** Sekcja "Oceń wykład": 10 kropli 1..10 (petrol aktywne, coral wybrane), bez srednich. */
@Composable
private fun RatingSection(panel: RatingPanel, onRate: (Int) -> Unit) {
    val shape = RoundedCornerShape(16.dp)
    Column(
        Modifier.fillMaxWidth().clip(shape).background(Surface).border(1.dp, Line, shape).padding(16.dp)
    ) {
        Text("Oceń wykład", fontWeight = FontWeight.SemiBold, color = Ink, fontSize = 15.sp)
        Spacer(Modifier.height(4.dp))
        Text(
            panel.message, fontSize = 13.sp, lineHeight = 18.sp,
            color = if (panel.warning) CoralDark else Muted,
        )
        Spacer(Modifier.height(14.dp))
        for (row in listOf(1..5, 6..10)) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                for (n in row) {
                    ScoreDrop(n, selected = panel.selected == n, enabled = panel.enabled, modifier = Modifier.weight(1f)) {
                        onRate(n)
                    }
                }
            }
            if (row.first == 1) Spacer(Modifier.height(10.dp))
        }
    }
}

@Composable
private fun ScoreDrop(n: Int, selected: Boolean, enabled: Boolean, modifier: Modifier, onClick: () -> Unit) {
    // Kontrast wg marki: na coralu tekst ink; aktywne petrol na jasnym petrolu; nieaktywne wygaszone.
    val bg = when {
        selected && enabled -> Coral
        selected -> CoralTint
        enabled -> Tint
        else -> Grey
    }
    val fg = when {
        selected -> Ink
        enabled -> Petrol
        else -> Faint
    }
    Box(
        modifier
            .aspectRatio(1f)
            .clip(CircleShape)
            .background(bg)
            .clickable(enabled = enabled, role = Role.Button, onClick = onClick)
            .semantics {
                contentDescription = "Ocena $n"
                this.selected = selected
            },
        contentAlignment = Alignment.Center,
    ) {
        Text(n.toString(), color = fg, fontSize = 17.sp, fontWeight = FontWeight.Bold)
    }
}
