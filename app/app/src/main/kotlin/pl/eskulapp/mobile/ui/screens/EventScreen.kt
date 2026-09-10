package pl.eskulapp.mobile.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
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

@Composable
fun EventScreen(vm: AppViewModel, id: Long) {
    val event by vm.repo.dao.event(id).collectAsStateWithLifecycle(null)
    val news by vm.repo.dao.news(id).collectAsStateWithLifecycle(emptyList())
    val readIds by vm.repo.dao.readNewsIds(id).collectAsStateWithLifecycle(emptyList())
    val unread = news.count { it.id !in readIds }
    val ev = event ?: return

    Column(Modifier.fillMaxSize().background(Bg)) {
        // header
        Column(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(bottomStart = 22.dp, bottomEnd = 22.dp))
                .background(Petrol).padding(start = 22.dp, end = 22.dp, top = 16.dp, bottom = 22.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(6.dp).clip(CircleShape).background(if (ev.status == "archived") Faint else Coral))
                Spacer(Modifier.width(8.dp))
                Text(if (ev.status == "archived") "Zapisane" else "Wydarzenie", color = PetrolText, fontSize = 12.sp)
            }
            Spacer(Modifier.height(8.dp))
            Text(ev.name, color = Surface, fontSize = 24.sp, fontWeight = FontWeight.ExtraBold, lineHeight = 28.sp)
            Spacer(Modifier.height(6.dp))
            val meta = listOfNotNull(
                if (!ev.startsAt.isNullOrBlank()) {
                    val s = dayShort(ev.startsAt!!.substring(0, 10))
                    val e = if (!ev.endsAt.isNullOrBlank()) dayShort(ev.endsAt!!.substring(0, 10)) else null
                    if (e != null && e != s) "$s-$e" else s
                } else null,
                ev.city,
                "Kod ${ev.accessCode}"
            ).joinToString(" · ")
            Text(meta, color = PetrolText, fontSize = 13.sp)
        }

        Column(Modifier.weight(1f).padding(20.dp)) {
            if (news.isNotEmpty()) {
                val latest = news.first()
                Row(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp))
                        .background(if (unread > 0) CoralTint else Tint)
                        .clickable { vm.nav.section(Screen.News(id)) }.padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(contentAlignment = Alignment.TopEnd) {
                        Box(Modifier.size(36.dp).clip(RoundedCornerShape(10.dp)).background(if (unread > 0) Coral else Petrol), contentAlignment = Alignment.Center) {
                            Ico(R.drawable.ic_bell, if (unread > 0) Ink else Surface, 20)
                        }
                        if (unread > 0) Box(
                            Modifier.size(18.dp).clip(CircleShape).background(CoralDark),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(if (unread > 9) "9+" else unread.toString(), color = Surface, fontSize = 10.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f)) {
                        // Wszystko przeczytane: tylko naglowek "Aktualności" + "brak powiadomień"
                        // (bez tresci ostatniej wiadomosci). Sa nieprzeczytane: tytul + badge.
                        if (unread > 0) {
                            Text(latest.title, fontWeight = FontWeight.SemiBold, fontSize = 14.sp, color = Ink)
                            Text("Aktualności · $unread nieprzeczytane", fontSize = 12.sp, color = CoralDark)
                        } else {
                            Text("Aktualności", fontWeight = FontWeight.SemiBold, fontSize = 14.sp, color = Ink)
                            Text("brak powiadomień", fontSize = 12.sp, color = Muted)
                        }
                    }
                    Ico(R.drawable.ic_chevron, if (unread > 0) CoralDark else Muted, 18)
                }
                Spacer(Modifier.height(16.dp))
            }

            @Composable
            fun tile(mod: Modifier, res: Int, title: String, sub: String, screen: Screen) {
                Column(
                    mod.clip(RoundedCornerShape(16.dp)).background(Surface)
                        .clickable { vm.nav.section(screen) }.padding(16.dp),
                    verticalArrangement = Arrangement.Center
                ) {
                    Box(Modifier.size(44.dp).clip(RoundedCornerShape(12.dp)).background(Tint), contentAlignment = Alignment.Center) {
                        Ico(res, Petrol, 24)
                    }
                    Spacer(Modifier.height(10.dp))
                    Text(title, fontWeight = FontWeight.SemiBold, fontSize = 16.sp, color = Ink)
                    Text(sub, fontSize = 12.sp, color = Muted)
                }
            }

            // Siatka 2x2 wypelnia cala pozostala wysokosc (rzedy i kafle dziela ja rowno).
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(Modifier.weight(1f), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    tile(Modifier.weight(1f).fillMaxHeight(), R.drawable.ic_calendar, "Agenda", "Program i sale", Screen.Agenda(id))
                    tile(Modifier.weight(1f).fillMaxHeight(), R.drawable.ic_person, "Prelegenci", "Kto występuje", Screen.Speakers(id))
                }
                Row(Modifier.weight(1f), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    tile(Modifier.weight(1f).fillMaxHeight(), R.drawable.ic_store, "Partnerzy", "Stoiska", Screen.Partners(id))
                    tile(Modifier.weight(1f).fillMaxHeight(), R.drawable.ic_pin, "Mapa", "Plan przestrzeni", Screen.MapS(id))
                }
            }
        }

    }
}
