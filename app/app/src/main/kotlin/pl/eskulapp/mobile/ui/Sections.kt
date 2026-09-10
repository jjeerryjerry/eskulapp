package pl.eskulapp.mobile.ui

import androidx.compose.runtime.Composable
import pl.eskulapp.mobile.R

@Composable
fun eventTabs(id: Long): List<NavTab> = listOf(
    NavTab(R.drawable.ic_home, "Wydarzenie", Screen.Event(id)),
    NavTab(R.drawable.ic_calendar, "Agenda", Screen.Agenda(id)),
    NavTab(R.drawable.ic_store, "Partnerzy", Screen.Partners(id)),
    NavTab(R.drawable.ic_pin, "Mapa", Screen.MapS(id)),
    NavTab(R.drawable.ic_more, "Więcej", Screen.More(id)),
)
