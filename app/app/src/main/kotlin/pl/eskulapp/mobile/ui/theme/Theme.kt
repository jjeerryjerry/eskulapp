package pl.eskulapp.mobile.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val Petrol = Color(0xFF0C5A63)
val PetrolDark = Color(0xFF08363B)
val Coral = Color(0xFFFF6B57)
val CoralDark = Color(0xFFD9503B)
val Ink = Color(0xFF0A1B2A)
val Muted = Color(0xFF5B6B72)
val Faint = Color(0xFF9AA7AD)
val Line = Color(0xFFE1E7E9)
val Bg = Color(0xFFF6F8F9)
val Surface = Color(0xFFFFFFFF)
val Tint = Color(0xFFD7EAEC)
val CoralTint = Color(0xFFFDE6E1)
val CoralLine = Color(0xFFFFD2C9)
val Grey = Color(0xFFEDF1F2)
val Petrol2 = Color(0xFF0A464D)
val PetrolText = Color(0xFFBFE0E2)

private val scheme = lightColorScheme(
    primary = Petrol,
    onPrimary = Color.White,
    secondary = Coral,
    onSecondary = Ink,
    background = Bg,
    onBackground = Ink,
    surface = Surface,
    onSurface = Ink,
    surfaceVariant = Tint,
    outline = Line,
)

@Composable
fun EskulappTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = scheme, content = content)
}
