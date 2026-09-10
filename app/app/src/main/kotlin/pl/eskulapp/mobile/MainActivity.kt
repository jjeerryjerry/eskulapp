package pl.eskulapp.mobile

import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.ContentTransform
import androidx.compose.animation.core.tween
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.systemBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.core.view.WindowCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import pl.eskulapp.mobile.reminders.Reminders
import pl.eskulapp.mobile.ui.*
import pl.eskulapp.mobile.ui.screens.*
import pl.eskulapp.mobile.ui.theme.Bg
import pl.eskulapp.mobile.ui.theme.EskulappTheme
import pl.eskulapp.mobile.ui.theme.Petrol

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        WindowCompat.getInsetsController(window, window.decorView).apply {
            isAppearanceLightStatusBars = true; isAppearanceLightNavigationBars = true
        }
        // Tapjacking: odrzucaj dotyk gdy okno jest przeslonite przez obca nakladke.
        // Ustawione globalnie na oknie -> obejmuje wrazliwe akcje (Usun wydarzenie,
        // Dolacz kodem) i cala reszte UI.
        window.decorView.filterTouchesWhenObscured = true
        Reminders.ensureChannel(this)
        setContent {
            EskulappTheme {
                val vm: AppViewModel = viewModel()

                // uprawnienie do powiadomien (Android 13+)
                val perm = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) {}
                LaunchedEffect(Unit) {
                    if (Build.VERSION.SDK_INT >= 33) perm.launch(android.Manifest.permission.POST_NOTIFICATIONS)
                }

                val start = vm.startScreen
                if (start == null) {
                    Box(Modifier.fillMaxSize().background(Bg), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(color = Petrol)
                    }
                } else {
                    val nav = vm.nav
                    BackHandler { if (!nav.pop()) finish() }
                    val current = nav.current
                    // Dolny pasek liczymy RAZ i renderujemy POZA AnimatedContent (statyczny).
                    // Pasek jest obecny na KAZDYM ekranie w obrebie eventu (tez drill-in:
                    // Prelegenci/Prelekcja/Partner/Kontakt), zeby wysokosc obszaru tresci NIE
                    // zmieniala sie przy cofaniu -> animacja back = dokladnie tab-switch.
                    val tabEventId: Long? = when (current) {
                        is Screen.Event -> current.id
                        is Screen.Agenda -> current.id
                        is Screen.Speakers -> current.id
                        is Screen.Partners -> current.id
                        is Screen.MapS -> current.id
                        is Screen.Contact -> current.id
                        is Screen.News -> current.id
                        is Screen.More -> current.id
                        is Screen.Talk -> current.eventId
                        is Screen.PartnerDetail -> current.eventId
                        is Screen.SpeakerDetail -> current.eventId
                        else -> null
                    }
                    Column(Modifier.fillMaxSize().background(Bg).windowInsetsPadding(WindowInsets.systemBars)) {
                      Box(Modifier.weight(1f).fillMaxWidth()) {
                      // Animowana jest WYLACZNIE tresc ekranu (obszar miedzy paskami).
                      AnimatedContent(
                        targetState = nav.current,
                        transitionSpec = {
                            // JEDEN wzorzec dla calej nawigacji, identyczny jak slajd zakladek
                            // dolnego menu: czysty poziomy slajd, BEZ fade, BEZ SizeTransform.
                            // Kierunek z nav.lastForward: w przod = nowa z prawej, stara w lewo;
                            // wstecz = lustro (nowa z lewej, stara w prawo). tween 300 ms.
                            val dir = if (nav.lastForward) 1 else -1
                            val enter = slideInHorizontally(tween(300)) { w -> dir * w }
                            val exit = slideOutHorizontally(tween(300)) { w -> -dir * w }
                            ContentTransform(enter, exit, 0f, null)
                        },
                        label = "screen"
                      ) { s ->
                        // KAZDY slot tresci ma PELNY rozmiar, nawet gdy ekran chwilowo
                        // early-returnuje (dane z Room jeszcze null). Inaczej wchodzaca tresc
                        // ma szerokosc 0 i slideInHorizontally{ w -> dir*w } daje offset 0 =>
                        // BRAK animacji wejscia (efekt "skoku") - to bylo zrodlo braku animacji WSTECZ.
                        Box(Modifier.fillMaxSize().background(Bg)) {
                        when (s) {
                            Screen.Entry -> EntryScreen(vm.entryLoading, vm.entryError, { vm.addEvent(it) }, null)
                            Screen.Events -> {
                                val events by vm.repo.dao.events().collectAsStateWithLifecycle(emptyList())
                                val notifyIds by vm.repo.dao.notifyIds().collectAsStateWithLifecycle(emptyList())
                                EventsScreen(
                                    events, notifyIds,
                                    onOpen = { nav.push(Screen.Event(it)) },
                                    onAdd = { nav.push(Screen.Entry) },
                                    onToggleNotify = { eid, on -> vm.toggleEventNotify(eid, on) },
                                )
                            }
                            is Screen.Event -> EventScreen(vm, s.id)
                            is Screen.Agenda -> AgendaScreen(vm, s.id)
                            is Screen.Speakers -> SpeakersScreen(vm, s.id)
                            is Screen.Partners -> PartnersScreen(vm, s.id)
                            is Screen.MapS -> MapScreen(vm, s.id, s.highlightPartnerId)
                            is Screen.Contact -> ContactScreen(vm, s.id)
                            is Screen.News -> NewsScreen(vm, s.id)
                            is Screen.Talk -> TalkScreen(vm, s.id, s.eventId)
                            is Screen.More -> MoreScreen(vm, s.id)
                            is Screen.PartnerDetail -> PartnerDetailScreen(vm, s.partnerId, s.eventId)
                            is Screen.SpeakerDetail -> SpeakerDetailScreen(vm, s.speakerId, s.eventId)
                        }
                        }
                      }
                      }
                      // Dolny pasek STATYCZNY: poza AnimatedContent - przy kazdym przejsciu
                      // przesuwa sie tylko tresc powyzej, a pasek stoi w miejscu.
                      if (tabEventId != null) {
                          BottomBar(current, eventTabs(tabEventId)) { sc, fwd -> nav.sectionWithDir(sc, fwd) }
                      }
                    }
                }
            }
        }
    }
}
