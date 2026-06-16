package com.booto.shawarma.ui.theme

import androidx.compose.material3.DarkColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val DarkBackground = Color(0xFF0D0D0D)
val DarkCard = Color(0xFF1A1A1A)
val GoldAccent = Color(0xFFF5A623)
val TextWhite = Color(0xFFFFFFFF)
val TextMuted = Color(0xFFAAAAAA)
val StatusCancelled = Color(0xFFE53935)
val StatusReady = Color(0xFF4CAF50)

private val CustomColorScheme = DarkColorScheme(
    primary = GoldAccent,
    background = DarkBackground,
    surface = DarkCard,
    onPrimary = Color.Black,
    onBackground = TextWhite,
    onSurface = TextWhite,
    error = StatusCancelled
)

@Composable
fun BooToTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = CustomColorScheme,
        content = content
    )
}
