package pl.eskulapp.mobile.ui.screens

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import pl.eskulapp.mobile.ui.ConflictPrompt
import pl.eskulapp.mobile.ui.hhmm
import pl.eskulapp.mobile.ui.theme.*

/** Ostrzezenie o konflikcie czasowym przy wlaczaniu przypomnienia. Decyzja u uczestnika. */
@Composable
fun ConflictDialog(prompt: ConflictPrompt, onConfirm: () -> Unit, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = Surface,
        title = { Text("Kolizja czasowa", fontWeight = FontWeight.Bold, color = Ink) },
        text = {
            Column {
                Text("W tym czasie obserwujesz już:", color = Muted, fontSize = 14.sp)
                prompt.conflicts.forEach { c ->
                    val time = listOf(hhmm(c.startsAt), hhmm(c.endsAt)).filter { it.isNotBlank() }.joinToString(" - ")
                    val meta = listOfNotNull(time.ifBlank { null }, c.room).joinToString(" · ")
                    Column(Modifier.padding(top = 10.dp)) {
                        Text((if (c.isSession) "Sesja: " else "") + c.title, color = Ink, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
                        if (meta.isNotBlank()) Text(meta, color = Muted, fontSize = 12.sp)
                    }
                }
                Text("Ustawić przypomnienie mimo to?", color = Muted, fontSize = 14.sp, modifier = Modifier.padding(top = 14.dp))
            }
        },
        confirmButton = { TextButton(onClick = onConfirm) { Text("Ustaw mimo to", color = Petrol, fontWeight = FontWeight.SemiBold) } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Anuluj", color = Muted) } },
    )
}
