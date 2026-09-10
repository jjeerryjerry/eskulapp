package pl.eskulapp.mobile.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import pl.eskulapp.mobile.R
import pl.eskulapp.mobile.ui.theme.*

@Composable
fun Ico(res: Int, tint: Color = Ink, size: Int = 22) =
    Icon(painterResource(res), contentDescription = null, tint = tint, modifier = Modifier.size(size.dp))

fun hhmm(dt: String?): String = if (dt != null && dt.length >= 16) dt.substring(11, 16) else ""
fun dayShort(date: String?): String {
    if (date == null || date.length < 10) return ""
    return date.substring(8, 10) + "." + date.substring(5, 7)
}
fun speakerName(first: String, last: String, title: String?): String {
    val base = (first.trim() + " " + last.trim()).trim()
    return if (!title.isNullOrBlank()) "$title $base".trim() else base
}
/** Czy wydarzenie jeszcze się nie zaczęło (data startu w przyszłości). */
fun isUpcoming(startsAt: String?): Boolean {
    if (startsAt == null || startsAt.length < 19) return false
    val now = java.time.LocalDateTime.now()
        .format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"))
    return startsAt > now
}
fun initials(first: String, last: String): String {
    val a = first.trim().firstOrNull()?.uppercaseChar()
    val b = last.trim().firstOrNull()?.uppercaseChar()
    return listOfNotNull(a, b).joinToString("").ifEmpty { "?" }
}

data class NavTab(val res: Int, val label: String, val screen: Screen, val dot: Boolean = false)

@Composable
fun BottomBar(current: Screen, tabs: List<NavTab>, onNav: (Screen, Boolean) -> Unit) {
    val currentIdx = tabs.indexOfFirst { it.screen::class == current::class }
    Row(
        Modifier.fillMaxWidth().background(Surface).padding(top = 10.dp, bottom = 10.dp),
        verticalAlignment = Alignment.Top
    ) {
        tabs.forEachIndexed { targetIdx, t ->
            val active = current::class == t.screen::class
            Column(
                // kierunek wg kolejnosci zakladek: cel na prawo = w przod, na lewo = wstecz
                Modifier.weight(1f).clickable { onNav(t.screen, targetIdx >= currentIdx) },
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Box {
                    Ico(t.res, tint = if (active) Petrol else Faint, size = 22)
                    if (t.dot) Box(
                        Modifier.size(8.dp).background(Coral, androidx.compose.foundation.shape.CircleShape)
                            .align(Alignment.TopEnd)
                    )
                }
                Text(
                    t.label, fontSize = 10.sp,
                    color = if (active) Petrol else Faint,
                    fontWeight = if (active) FontWeight.SemiBold else FontWeight.Medium,
                    modifier = Modifier.padding(top = 3.dp)
                )
            }
        }
    }
}
