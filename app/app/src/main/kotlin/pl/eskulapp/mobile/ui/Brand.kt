package pl.eskulapp.mobile.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import pl.eskulapp.mobile.R
import pl.eskulapp.mobile.ui.theme.*

@Composable
fun Seal(size: Int = 36) {
    Box(
        Modifier.size(size.dp).clip(CircleShape).background(Petrol),
        contentAlignment = Alignment.Center
    ) {
        Image(
            painterResource(R.drawable.ic_launcher_foreground),
            contentDescription = "Eskulapp",
            contentScale = ContentScale.Fit,
            modifier = Modifier.size((size * 0.92).dp)
        )
    }
}

@Composable
fun BackTopBar(title: String, onBack: () -> Unit, trailing: @Composable (() -> Unit)? = null) {
    Row(
        Modifier.fillMaxWidth().background(Surface).padding(start = 20.dp, end = 20.dp, top = 14.dp, bottom = 16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(Modifier.clickable { onBack() }) { Ico(R.drawable.ic_back, Ink, 22) }
        Spacer(Modifier.width(10.dp))
        Text(title, fontSize = 22.sp, fontWeight = FontWeight.ExtraBold, color = Ink)
        if (trailing != null) { Spacer(Modifier.weight(1f)); trailing() }
    }
}
