package pl.eskulapp.mobile.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import pl.eskulapp.mobile.data.local.EventEntity
import pl.eskulapp.mobile.ui.Ico
import pl.eskulapp.mobile.ui.Seal
import pl.eskulapp.mobile.ui.dayShort
import pl.eskulapp.mobile.ui.isUpcoming
import pl.eskulapp.mobile.ui.theme.*
import pl.eskulapp.mobile.R

@Composable
fun EventsScreen(
    events: List<EventEntity>,
    notifyIds: List<Long> = emptyList(),
    onOpen: (Long) -> Unit,
    onAdd: () -> Unit,
    onToggleNotify: (Long, Boolean) -> Unit = { _, _ -> },
) {
    Column(Modifier.fillMaxSize().background(Bg).padding(top = 14.dp)) {
        Row(Modifier.padding(horizontal = 20.dp), verticalAlignment = Alignment.CenterVertically) {
            Seal(36); Spacer(Modifier.width(12.dp))
            Text("Moje wydarzenia", fontSize = 22.sp, fontWeight = FontWeight.ExtraBold, color = Ink)
        }
        Spacer(Modifier.height(18.dp))
        if (events.isEmpty()) {
            Column(Modifier.weight(1f).fillMaxWidth().padding(24.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Spacer(Modifier.weight(1f))
                Box(Modifier.size(120.dp).clip(RoundedCornerShape(60.dp)).background(Tint), contentAlignment = Alignment.Center) {
                    Ico(R.drawable.ic_calendar, Petrol, 56)
                }
                Spacer(Modifier.height(20.dp))
                Text("Nie masz jeszcze wydarzeń", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = Ink)
                Spacer(Modifier.height(8.dp))
                Text("Dodaj wydarzenie kodem od organizatora.", color = Muted, fontSize = 14.sp, textAlign = TextAlign.Center)
                Spacer(Modifier.weight(1f))
            }
        } else {
            LazyColumn(Modifier.weight(1f), contentPadding = PaddingValues(horizontal = 20.dp, vertical = 4.dp)) {
                items(events, key = { it.id }) { ev ->
                    EventCard(
                        ev,
                        notify = ev.id in notifyIds,
                        onToggleNotify = { onToggleNotify(ev.id, it) },
                        onClick = { onOpen(ev.id) },
                    )
                }
            }
        }
        Button(
            onClick = onAdd,
            colors = ButtonDefaults.buttonColors(containerColor = Petrol),
            shape = RoundedCornerShape(14.dp),
            modifier = Modifier.fillMaxWidth().padding(20.dp).height(54.dp)
        ) {
            Ico(R.drawable.ic_plus, Surface, 20); Spacer(Modifier.width(8.dp))
            Text("Dodaj wydarzenie kodem", fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
        }
    }
}

@Composable
private fun EventCard(ev: EventEntity, notify: Boolean, onToggleNotify: (Boolean) -> Unit, onClick: () -> Unit) {
    val archived = ev.status == "archived"
    Column(
        Modifier.fillMaxWidth().padding(vertical = 7.dp).clip(RoundedCornerShape(16.dp))
            .background(Surface).clickable { onClick() }.alpha(if (archived) 0.6f else 1f).padding(18.dp)
    ) {
        Row(verticalAlignment = Alignment.Top) {
            Text(ev.name, fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Ink, modifier = Modifier.weight(1f))
            val (bg, fg, lbl) = when {
                ev.status == "archived" -> Triple(Grey, Faint, "ARCHIWALNY")
                isUpcoming(ev.startsAt) -> Triple(CoralTint, CoralDark, "NADCHODZĄCE")
                else -> Triple(Tint, Petrol, "AKTYWNY")
            }
            Box(Modifier.clip(RoundedCornerShape(999.dp)).background(bg).padding(horizontal = 10.dp, vertical = 5.dp)) {
                Text(lbl, color = fg, fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
            }
        }
        Spacer(Modifier.height(8.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            val where = listOfNotNull(
                if (!ev.startsAt.isNullOrBlank()) dayShort(ev.startsAt.substring(0, 10)) else null,
                ev.city
            ).joinToString(" · ")
            Text(where.ifBlank { "termin do ustalenia" }, color = Muted, fontSize = 13.sp, modifier = Modifier.weight(1f))
            Box(
                Modifier.size(38.dp).clip(RoundedCornerShape(11.dp))
                    .background(if (notify) Coral else Tint)
                    .clickable { onToggleNotify(!notify) },
                contentAlignment = Alignment.Center
            ) {
                Ico(R.drawable.ic_bell, if (notify) Ink else Faint, 20)
            }
        }
        Text(
            if (notify) "Powiadomienia włączone" else "Powiadomienia wyłączone",
            color = if (notify) CoralDark else Faint, fontSize = 11.sp,
            fontWeight = FontWeight.Medium, modifier = Modifier.padding(top = 6.dp)
        )
    }
}
