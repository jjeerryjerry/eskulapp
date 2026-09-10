package pl.eskulapp.mobile.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import pl.eskulapp.mobile.ui.Seal
import pl.eskulapp.mobile.ui.theme.*

@Composable
fun EntryScreen(
    loading: Boolean,
    error: String?,
    onSubmit: (String) -> Unit,
    onHasEvents: (() -> Unit)?,
) {
    var code by remember { mutableStateOf("") }
    Column(
        Modifier.fillMaxSize().background(Bg).padding(24.dp).padding(top = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(Modifier.height(20.dp))
        Seal(72)
        Spacer(Modifier.height(22.dp))
        Text("Dołącz do wydarzenia", fontSize = 24.sp, fontWeight = FontWeight.Bold, color = Ink)
        Spacer(Modifier.height(10.dp))
        Text(
            "Wpisz kod od organizatora, a pobierzemy cala agende na telefon. Dziala tez offline.",
            fontSize = 14.sp, color = Muted, textAlign = TextAlign.Center,
            modifier = Modifier.widthIn(max = 300.dp)
        )
        Spacer(Modifier.height(26.dp))
        OutlinedTextField(
            value = code,
            onValueChange = { code = it.uppercase().filter { c -> c.isLetterOrDigit() }.take(32) },
            singleLine = true,
            placeholder = { Text("np. FND2027") },
            keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Characters, imeAction = ImeAction.Go),
            textStyle = LocalTextStyle.current.copy(fontSize = 22.sp, fontWeight = FontWeight.Bold, letterSpacing = 3.sp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = Petrol, unfocusedBorderColor = Line,
                focusedContainerColor = Surface, unfocusedContainerColor = Surface,
            ),
            shape = RoundedCornerShape(12.dp),
            modifier = Modifier.fillMaxWidth()
        )
        if (error != null) {
            Spacer(Modifier.height(12.dp))
            Text(error, color = CoralDark, fontSize = 13.sp, textAlign = TextAlign.Center)
        }
        Spacer(Modifier.height(18.dp))
        Button(
            onClick = { onSubmit(code) },
            enabled = !loading,
            colors = ButtonDefaults.buttonColors(containerColor = Petrol),
            shape = RoundedCornerShape(14.dp),
            modifier = Modifier.fillMaxWidth().height(54.dp)
        ) {
            if (loading) CircularProgressIndicator(color = Surface, strokeWidth = 2.dp, modifier = Modifier.size(22.dp))
            else Text("Pobierz wydarzenie", fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
        }
        if (onHasEvents != null) {
            Spacer(Modifier.height(16.dp))
            TextButton(onClick = onHasEvents) { Text("Moje wydarzenia", color = Petrol) }
        }
    }
}
