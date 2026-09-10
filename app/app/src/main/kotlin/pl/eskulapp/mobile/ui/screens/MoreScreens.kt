package pl.eskulapp.mobile.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.rememberTransformableState
import androidx.compose.foundation.gestures.transformable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import pl.eskulapp.mobile.R
import pl.eskulapp.mobile.data.local.*
import pl.eskulapp.mobile.ui.*
import pl.eskulapp.mobile.ui.theme.*

@Composable
fun SpeakersScreen(vm: AppViewModel, id: Long) {
    val speakers by vm.repo.dao.speakers(id).collectAsStateWithLifecycle(emptyList())
    Column(Modifier.fillMaxSize().background(Bg)) {
        BackTopBar("Prelegenci", onBack = { vm.nav.pop() },
            trailing = { Text("${speakers.size} osób", color = Muted, fontSize = 13.sp) })
        if (speakers.isEmpty()) EmptyHint("Lista prelegentów pojawi się wkrótce.")
        LazyColumn(contentPadding = PaddingValues(20.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            items(speakers, key = { it.id }) { s ->
                Row(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(Surface)
                        .border(1.dp, Line, RoundedCornerShape(14.dp))
                        .clickable { vm.nav.push(Screen.SpeakerDetail(s.id, id)) }.padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(Modifier.size(46.dp).clip(CircleShape).background(Tint), contentAlignment = Alignment.Center) {
                        Text(initials(s.firstName, s.lastName), color = Petrol, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                    }
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f)) {
                        Text((s.firstName + " " + s.lastName).trim(), fontWeight = FontWeight.SemiBold, color = Ink, fontSize = 15.sp)
                        if (!s.title.isNullOrBlank()) Text(s.title!!, fontSize = 12.sp, color = Muted)
                    }
                    Ico(R.drawable.ic_chevron, Line, 18)
                }
            }
        }
    }
}

@Composable
fun PartnersScreen(vm: AppViewModel, id: Long) {
    val partners by vm.repo.dao.partners(id).collectAsStateWithLifecycle(emptyList())
    Column(Modifier.fillMaxSize().background(Bg)) {
        BackTopBar("Partnerzy", onBack = { vm.nav.pop() })
        if (partners.isEmpty()) EmptyHint("Partnerzy pojawią się wkrótce.")
        LazyColumn(Modifier.weight(1f), contentPadding = PaddingValues(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            items(partners, key = { it.id }) { p ->
                Row(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(Surface)
                        .border(1.dp, Line, RoundedCornerShape(16.dp))
                        .clickable { vm.nav.push(Screen.PartnerDetail(p.id, id)) }.padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(Modifier.size(52.dp).clip(RoundedCornerShape(13.dp)).background(Tint), contentAlignment = Alignment.Center) {
                        Text(p.name.take(2), color = Petrol, fontWeight = FontWeight.ExtraBold, fontSize = 18.sp)
                    }
                    Spacer(Modifier.width(14.dp))
                    Column(Modifier.weight(1f)) {
                        Text(p.name, fontWeight = FontWeight.Bold, fontSize = 16.sp, color = Ink)
                        if (!p.description.isNullOrBlank()) Text(p.description!!, fontSize = 12.sp, color = Muted, modifier = Modifier.padding(vertical = 4.dp))
                        if (!p.boothLocation.isNullOrBlank())
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Ico(R.drawable.ic_pin, Petrol, 14); Spacer(Modifier.width(5.dp))
                                Text(p.boothLocation!!, color = Petrol, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                            }
                    }
                    // Skrot na mape z wyroznionym stoiskiem tego partnera (osobny click)
                    if (!p.boothLocation.isNullOrBlank())
                        Box(
                            Modifier.size(38.dp).clip(RoundedCornerShape(11.dp)).background(CoralTint)
                                .clickable { vm.nav.push(Screen.MapS(id, p.id)) },
                            contentAlignment = Alignment.Center
                        ) { Ico(R.drawable.ic_pin, Coral, 20) }
                    Spacer(Modifier.width(8.dp))
                    Ico(R.drawable.ic_chevron, Line, 18)
                }
            }
        }
    }
}

/** Stala, przypisana na sztywno pozycja pinu stoiska na planie (frakcje 0..1).
 *  Uklad: 2 kolumny (x=0.30 / 0.70), wiersze rozlozone rownomiernie w pionie
 *  miedzy scena (gora) a wejsciem (dol). Stabilne per indeks partnera. */
private fun boothPos(i: Int, n: Int): Pair<Float, Float> {
    val cols = 2
    val rows = ((n + cols - 1) / cols).coerceAtLeast(1)
    val col = i % cols
    val row = i / cols
    val fx = if (col == 0) 0.30f else 0.70f
    val fy = if (rows <= 1) 0.5f else 0.22f + row * (0.56f / (rows - 1))
    return fx to fy
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun MapScreen(vm: AppViewModel, id: Long, highlightPartnerId: Long? = null) {
    val event by vm.repo.dao.event(id).collectAsStateWithLifecycle(null)
    val partners by vm.repo.dao.partners(id).collectAsStateWithLifecycle(emptyList())
    val booths = partners.filter { !it.boothLocation.isNullOrBlank() }

    // Zaznaczony partner = tylko podswietlenie pinu (bez baneru, bez auto-zoomu/centrowania).
    // Init z highlightPartnerId (wejscie z "Zobacz na mapie"); user sam scrolluje do mapy.
    var selectedId by remember(highlightPartnerId) { mutableStateOf(highlightPartnerId) }

    // Zoom/pan planu (styl "embed") - obslugiwane wylacznie gestem uzytkownika
    var scale by remember { mutableFloatStateOf(1f) }
    var offset by remember { mutableStateOf(Offset.Zero) }
    var planSize by remember { mutableStateOf(IntSize.Zero) }

    // Zoom pinch + pan (pan tylko gdy przyblizone -> inaczej pionowy gest scrolluje strone)
    val transformState = rememberTransformableState { zoomChange, panChange, _ ->
        scale = (scale * zoomChange).coerceIn(1f, 4f)
        val maxX = (scale - 1f) * planSize.width / 2f
        val maxY = (scale - 1f) * planSize.height / 2f
        offset = Offset(
            (offset.x + panChange.x).coerceIn(-maxX, maxX),
            (offset.y + panChange.y).coerceIn(-maxY, maxY),
        )
    }

    Column(Modifier.fillMaxSize().background(Bg)) {
        BackTopBar("Mapa", onBack = { vm.nav.pop() })

        // CALA strona (mapa + lista) w JEDNYM pionowym scrollu -> przewijaja sie razem.
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState())) {

            // Naglowek: obiekt + miasto
            Row(
                Modifier.padding(horizontal = 20.dp, vertical = 12.dp).fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp)).background(Tint).padding(14.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(Modifier.size(40.dp).clip(RoundedCornerShape(11.dp)).background(Petrol), contentAlignment = Alignment.Center) {
                    Ico(R.drawable.ic_pin, Surface, 22)
                }
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Text(event?.venueName ?: "Plan przestrzeni", color = Ink, fontWeight = FontWeight.Bold, fontSize = 15.sp)
                    if (!event?.city.isNullOrBlank()) Text(event!!.city!!, color = Muted, fontSize = 12.sp)
                }
            }

            // PELNE okno planu (embed) - piny na stalych pozycjach, pinch-zoom + pan.
            Box(
                Modifier.padding(horizontal = 20.dp).fillMaxWidth().height(460.dp)
                    .clip(RoundedCornerShape(18.dp)).background(Tint).border(1.dp, Line, RoundedCornerShape(18.dp))
                    .onSizeChanged { planSize = it }
                    // pan tylko przy zoom>1; przy 1x pionowy gest scrolluje cala strone
                    .transformable(state = transformState, canPan = { _ -> scale > 1f })
            ) {
                BoxWithConstraints(
                    Modifier.fillMaxSize().graphicsLayer {
                        scaleX = scale; scaleY = scale; translationX = offset.x; translationY = offset.y
                    }
                ) {
                    val w = maxWidth
                    val h = maxHeight
                    // scena (gora) i wejscie (dol)
                    Box(
                        Modifier.align(Alignment.TopCenter).padding(top = 12.dp).fillMaxWidth(0.6f)
                            .height(30.dp).clip(RoundedCornerShape(9.dp)).background(Petrol),
                        contentAlignment = Alignment.Center
                    ) { Text("SCENA GŁÓWNA", color = Surface, fontSize = 11.sp, fontWeight = FontWeight.Bold) }
                    Box(
                        Modifier.align(Alignment.BottomCenter).padding(bottom = 12.dp).fillMaxWidth(0.5f)
                            .height(26.dp).clip(RoundedCornerShape(9.dp)).background(Grey),
                        contentAlignment = Alignment.Center
                    ) { Text("WEJŚCIE GŁÓWNE", color = Muted, fontSize = 10.sp, fontWeight = FontWeight.SemiBold) }

                    if (booths.isEmpty()) {
                        Text("Rozmieszczenie stoisk pojawi się wkrótce.", color = Muted, fontSize = 13.sp,
                            modifier = Modifier.align(Alignment.Center))
                    } else {
                        // Piny stoisk na STALYCH pozycjach (boothPos). Etykieta = NAZWA wystawcy.
                        booths.forEachIndexed { i, p ->
                            val (fx, fy) = boothPos(i, booths.size)
                            val on = p.id == selectedId
                            Column(
                                Modifier.align(Alignment.TopStart)
                                    .offset(x = w * fx - 34.dp, y = h * fy - 20.dp)
                                    .width(68.dp),
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Box(
                                    Modifier.size(if (on) 30.dp else 24.dp).clip(CircleShape)
                                        .background(if (on) CoralDark else Coral)
                                        .border(if (on) 2.dp else 0.dp, Surface, CircleShape),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Ico(R.drawable.ic_pin, Surface, if (on) 16 else 13)
                                }
                                // NAZWA wystawcy (skrocona jesli za dluga)
                                Text(
                                    p.name,
                                    color = if (on) Ink else Petrol,
                                    fontSize = if (on) 10.sp else 9.sp,
                                    fontWeight = if (on) FontWeight.Bold else FontWeight.SemiBold,
                                    maxLines = 1, overflow = TextOverflow.Ellipsis,
                                    textAlign = TextAlign.Center
                                )
                                // numer stoiska - malutkim drukiem pod spodem
                                Text(
                                    p.boothLocation!!.substringAfterLast(' '),
                                    color = Faint, fontSize = 8.sp, fontWeight = FontWeight.Medium, maxLines = 1
                                )
                            }
                        }
                    }
                }
            }
            Text(
                "Uszczypnij żeby przybliżyć. Przeciągnij aby przesunąć.",
                color = Faint, fontSize = 10.sp, maxLines = 1, overflow = TextOverflow.Ellipsis,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
            )

            // Lista stoisk - klik ZAZNACZA stoisko na planie (nie otwiera karty). Scrolluje z mapa.
            if (booths.isNotEmpty()) {
                Text("Stoiska", fontWeight = FontWeight.Bold, fontSize = 17.sp, color = Ink,
                    modifier = Modifier.padding(horizontal = 20.dp))
                Spacer(Modifier.height(8.dp))
                Column(Modifier.padding(horizontal = 20.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    booths.forEach { p ->
                        val on = p.id == selectedId
                        Row(
                            Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp))
                                .background(if (on) CoralTint else Surface)
                                .border(if (on) 2.dp else 1.dp, if (on) CoralLine else Line, RoundedCornerShape(12.dp))
                                .clickable { selectedId = p.id }.padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Ico(R.drawable.ic_pin, Coral, 20); Spacer(Modifier.width(10.dp))
                            Text(p.name, Modifier.weight(1f), fontWeight = FontWeight.SemiBold, color = Ink, fontSize = 14.sp)
                            Pill(p.boothLocation!!, if (on) Surface else Tint, if (on) CoralDark else Petrol)
                        }
                    }
                }
                Spacer(Modifier.height(16.dp))
            }
        }
    }
}

@Composable
fun ContactScreen(vm: AppViewModel, id: Long) {
    val contacts by vm.repo.dao.contacts(id).collectAsStateWithLifecycle(emptyList())
    val ctx = LocalContext.current
    Column(Modifier.fillMaxSize().background(Bg)) {
        BackTopBar("Kontakt", onBack = { vm.nav.pop() })
        if (contacts.isEmpty()) EmptyHint("Dane kontaktowe pojawią się wkrótce.")
        LazyColumn(contentPadding = PaddingValues(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            items(contacts, key = { it.id }) { c ->
                Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(Surface).border(1.dp, Line, RoundedCornerShape(16.dp)).padding(4.dp)) {
                    if (!c.name.isNullOrBlank())
                        Text(c.name!!, fontWeight = FontWeight.Bold, fontSize = 15.sp, color = Ink, modifier = Modifier.padding(start = 12.dp, top = 12.dp))
                    c.phone?.takeIf { it.isNotBlank() }?.let {
                        ContactRow(R.drawable.ic_phone, "Telefon", it) { ctx.startActivity(Intent(Intent.ACTION_DIAL, Uri.parse("tel:$it"))) }
                    }
                    c.email?.takeIf { it.isNotBlank() }?.let {
                        ContactRow(R.drawable.ic_mail, "E-mail", it) { ctx.startActivity(Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:$it"))) }
                    }
                    c.note?.takeIf { it.isNotBlank() }?.let {
                        ContactRow(R.drawable.ic_globe, c.label ?: "Informacja", it, null)
                    }
                }
            }
        }
    }
}

@Composable
private fun ContactRow(res: Int, label: String, value: String, onClick: (() -> Unit)?) {
    Row(
        Modifier.fillMaxWidth().let { if (onClick != null) it.clickable { onClick() } else it }.padding(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(Modifier.size(40.dp).clip(RoundedCornerShape(11.dp)).background(Tint), contentAlignment = Alignment.Center) { Ico(res, Petrol, 20) }
        Spacer(Modifier.width(13.dp))
        Column(Modifier.weight(1f)) {
            Text(label, fontSize = 12.sp, color = Faint)
            Text(value, fontWeight = FontWeight.SemiBold, fontSize = 15.sp, color = Ink)
        }
        if (onClick != null) Ico(R.drawable.ic_chevron, Line, 18)
    }
}

@Composable
fun NewsScreen(vm: AppViewModel, id: Long) {
    val news by vm.repo.dao.news(id).collectAsStateWithLifecycle(emptyList())
    // Wejscie w aktualnosci = oznacz wszystkie jako przeczytane (badge znika).
    LaunchedEffect(news) { vm.markNewsRead(id, news.map { it.id }) }
    Column(Modifier.fillMaxSize().background(Bg)) {
        BackTopBar("Aktualności", onBack = { vm.nav.pop() })
        if (news.isEmpty()) EmptyHint("Brak aktualności. Wrócimy tu ze zmianami i ogłoszeniami.")
        LazyColumn(Modifier.weight(1f), contentPadding = PaddingValues(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            items(news, key = { it.id }) { n ->
                Row(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(Surface)
                        .border(1.dp, if (n.pinned == 1) CoralLine else Line, RoundedCornerShape(16.dp)).padding(14.dp)
                ) {
                    Box(Modifier.size(38.dp).clip(RoundedCornerShape(10.dp)).background(if (n.pinned == 1) Coral else Tint), contentAlignment = Alignment.Center) {
                        Ico(R.drawable.ic_bell, if (n.pinned == 1) Ink else Petrol, 20)
                    }
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f)) {
                        Text(n.title, fontWeight = FontWeight.SemiBold, fontSize = 15.sp, color = Ink)
                        if (!n.body.isNullOrBlank()) Text(n.body!!, fontSize = 13.sp, color = Muted, modifier = Modifier.padding(top = 3.dp))
                        Text(hhmm(n.publishedAt), fontSize = 11.sp, color = Faint, modifier = Modifier.padding(top = 6.dp))
                    }
                }
            }
        }
    }
}

@Composable
fun MoreScreen(vm: AppViewModel, id: Long) {
    var confirmDelete by remember { mutableStateOf(false) }
    Column(Modifier.fillMaxSize().background(Bg)) {
        BackTopBar("Więcej", onBack = { vm.nav.pop() })
        Column(Modifier.weight(1f).padding(20.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            MoreRow(R.drawable.ic_phone, "Kontakt") { vm.nav.section(Screen.Contact(id)) }
            MoreRow(R.drawable.ic_calendar, "Lista wydarzeń") { vm.nav.setStack(Screen.Events) }
            Spacer(Modifier.height(8.dp))
            MoreRow(R.drawable.ic_back, "Usuń to wydarzenie", danger = true) { confirmDelete = true }
        }
    }
    if (confirmDelete) {
        AlertDialog(
            onDismissRequest = { confirmDelete = false },
            title = { Text("Usunąć wydarzenie?", fontWeight = FontWeight.Bold, color = Ink) },
            text = { Text("Wydarzenie zniknie z listy. Mozesz dodac je ponownie kodem od organizatora.", color = Muted) },
            confirmButton = {
                TextButton(onClick = {
                    confirmDelete = false
                    vm.deleteEvent(id); vm.nav.setStack(Screen.Events)
                }) { Text("Usuń", color = CoralDark, fontWeight = FontWeight.SemiBold) }
            },
            dismissButton = {
                TextButton(onClick = { confirmDelete = false }) { Text("Anuluj", color = Muted) }
            },
            containerColor = Surface,
        )
    }
}

@Composable
private fun MoreRow(res: Int, label: String, danger: Boolean = false, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(Surface)
            .border(1.dp, Line, RoundedCornerShape(14.dp)).clickable { onClick() }.padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Ico(res, if (danger) CoralDark else Petrol, 22)
        Spacer(Modifier.width(13.dp))
        Text(label, Modifier.weight(1f), fontWeight = FontWeight.SemiBold, color = if (danger) CoralDark else Ink, fontSize = 15.sp)
        if (!danger) Ico(R.drawable.ic_chevron, Line, 18)
    }
}

@Composable
private fun ColumnScope.EmptyHint(text: String) {
    Box(Modifier.weight(1f).fillMaxWidth().padding(32.dp), contentAlignment = Alignment.Center) {
        Text(text, color = Muted, fontSize = 14.sp, fontWeight = FontWeight.Medium)
    }
}

@Composable
fun PartnerDetailScreen(vm: AppViewModel, partnerId: Long, eventId: Long) {
    val partner by vm.repo.dao.partner(partnerId).collectAsStateWithLifecycle(null)
    val ctx = LocalContext.current
    val p = partner ?: return
    Column(Modifier.fillMaxSize().background(Bg)) {
        BackTopBar("Partner", onBack = { vm.nav.pop() })
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(20.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(72.dp).clip(RoundedCornerShape(18.dp)).background(Tint), contentAlignment = Alignment.Center) {
                    Text(p.name.take(2), color = Petrol, fontWeight = FontWeight.ExtraBold, fontSize = 26.sp)
                }
                Spacer(Modifier.width(16.dp))
                Column(Modifier.weight(1f)) {
                    Text(p.name, fontWeight = FontWeight.Bold, fontSize = 20.sp, color = Ink, lineHeight = 24.sp)
                    if (!p.tier.isNullOrBlank()) {
                        Spacer(Modifier.height(6.dp))
                        Pill(p.tier!!.uppercase(), Tint, Petrol)
                    }
                }
            }
            if (!p.description.isNullOrBlank()) {
                Spacer(Modifier.height(18.dp))
                Text(p.description!!, fontSize = 15.sp, color = Muted, lineHeight = 22.sp)
            }
            if (!p.boothLocation.isNullOrBlank()) {
                Spacer(Modifier.height(18.dp))
                Row(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(Surface)
                        .border(1.dp, Line, RoundedCornerShape(14.dp)).padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(Modifier.size(40.dp).clip(RoundedCornerShape(11.dp)).background(Tint), contentAlignment = Alignment.Center) { Ico(R.drawable.ic_pin, Petrol, 20) }
                    Spacer(Modifier.width(13.dp))
                    Column(Modifier.weight(1f)) {
                        Text("Stoisko", fontSize = 12.sp, color = Faint)
                        Text(p.boothLocation!!, fontWeight = FontWeight.SemiBold, fontSize = 15.sp, color = Ink)
                    }
                    Text("Zobacz na mapie", color = Petrol, fontSize = 13.sp, fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.clickable { vm.nav.push(Screen.MapS(eventId, partnerId)) })
                }
            }
            if (!p.website.isNullOrBlank()) {
                Spacer(Modifier.height(12.dp))
                Row(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(Surface)
                        .border(1.dp, Line, RoundedCornerShape(14.dp))
                        .clickable {
                            val u = if (p.website!!.startsWith("http")) p.website!! else "https://" + p.website
                            ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(u)))
                        }.padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(Modifier.size(40.dp).clip(RoundedCornerShape(11.dp)).background(Tint), contentAlignment = Alignment.Center) { Ico(R.drawable.ic_globe, Petrol, 20) }
                    Spacer(Modifier.width(13.dp))
                    Column(Modifier.weight(1f)) {
                        Text("Strona", fontSize = 12.sp, color = Faint)
                        Text(p.website!!, fontWeight = FontWeight.SemiBold, fontSize = 15.sp, color = Ink)
                    }
                    Ico(R.drawable.ic_chevron, Line, 18)
                }
            }
        }
    }
}

@Composable
fun SpeakerDetailScreen(vm: AppViewModel, speakerId: Long, eventId: Long) {
    val speaker by vm.repo.dao.speaker(speakerId).collectAsStateWithLifecycle(null)
    val talks by vm.repo.dao.talksForSpeaker(speakerId).collectAsStateWithLifecycle(emptyList())
    val rooms by vm.repo.dao.rooms(eventId).collectAsStateWithLifecycle(emptyList())
    val s = speaker ?: return
    Column(Modifier.fillMaxSize().background(Bg)) {
        BackTopBar("Prelegent", onBack = { vm.nav.pop() })
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(20.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(72.dp).clip(CircleShape).background(Tint), contentAlignment = Alignment.Center) {
                    Text(initials(s.firstName, s.lastName), color = Petrol, fontWeight = FontWeight.Bold, fontSize = 26.sp)
                }
                Spacer(Modifier.width(16.dp))
                Column(Modifier.weight(1f)) {
                    Text((s.firstName + " " + s.lastName).trim(), fontWeight = FontWeight.Bold, fontSize = 20.sp, color = Ink, lineHeight = 24.sp)
                    if (!s.title.isNullOrBlank()) {
                        Spacer(Modifier.height(4.dp))
                        Text(s.title!!, fontSize = 13.sp, color = Muted)
                    }
                }
            }
            if (!s.bio.isNullOrBlank()) {
                Spacer(Modifier.height(18.dp))
                Text(s.bio!!, fontSize = 15.sp, color = Muted, lineHeight = 22.sp)
            }
            if (talks.isNotEmpty()) {
                Spacer(Modifier.height(20.dp))
                Text("Wystąpienia", fontWeight = FontWeight.SemiBold, color = Ink, fontSize = 15.sp)
                Spacer(Modifier.height(8.dp))
                talks.forEach { t ->
                    val room = rooms.firstOrNull { it.id == t.roomId }?.name
                    val sub = listOfNotNull(dayShort(t.startsAt?.substring(0, 10)).ifBlank { null }, hhmm(t.startsAt).ifBlank { null }, room).joinToString(" · ")
                    Row(
                        Modifier.fillMaxWidth().padding(vertical = 5.dp).clip(RoundedCornerShape(12.dp))
                            .background(Surface).border(1.dp, Line, RoundedCornerShape(12.dp))
                            .clickable { vm.nav.push(Screen.Talk(t.id, eventId)) }.padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(Modifier.weight(1f)) {
                            Text(t.title, fontWeight = FontWeight.SemiBold, fontSize = 14.sp, color = Ink, lineHeight = 18.sp)
                            if (sub.isNotBlank()) Text(sub, fontSize = 12.sp, color = Muted, modifier = Modifier.padding(top = 3.dp))
                        }
                        Ico(R.drawable.ic_chevron, Line, 18)
                    }
                }
            }
        }
    }
}
