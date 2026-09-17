package pl.eskulapp.mobile.ui

import androidx.compose.runtime.Composable
import pl.eskulapp.mobile.R

@Composable
fun eventTabs(id: Long, mapEnabled: Boolean = true): List<NavTab> = listOfNotNull(
    NavTab(R.drawable.ic_home, "Wydarzenie", Screen.Event(id)),
    NavTab(R.drawable.ic_calendar, "Agenda", Screen.Agenda(id)),
    NavTab(R.drawable.ic_store, "Partnerzy", Screen.Partners(id)),
    // Event bez mapki (wylaczona w CMS): zakladka Mapa znika z menu
    if (mapEnabled) NavTab(R.drawable.ic_pin, "Mapa", Screen.MapS(id)) else null,
    NavTab(R.drawable.ic_more, "Więcej", Screen.More(id)),
)
