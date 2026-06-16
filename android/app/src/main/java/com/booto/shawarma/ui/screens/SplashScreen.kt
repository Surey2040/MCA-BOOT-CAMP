package com.booto.shawarma.ui.screens

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.booto.shawarma.ui.theme.DarkBackground
import com.booto.shawarma.ui.theme.GoldAccent
import com.booto.shawarma.viewmodel.LoginViewModel
import kotlinx.coroutines.delay

@Composable
fun SplashScreen(
    viewModel: LoginViewModel,
    onNavigateNext: (isLoggedIn: Boolean) -> Unit
) {
    // Splash duration timer
    LaunchedEffect(key1 = true) {
        delay(2500)
        onNavigateNext(viewModel.isLoggedIn())
    }

    // Scale animation for logo/illustration
    val infiniteTransition = rememberInfiniteTransition(label = "scale")
    val scale by infiniteTransition.animateFloat(
        initialValue = 0.95f,
        targetValue = 1.05f,
        animationSpec = infiniteRepeatable(
            animation = tween(1200, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "scale"
    )

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBackground),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Logo and Illustration Container
        Box(
            modifier = Modifier
                .size(240.dp)
                .padding(16.dp),
            contentAlignment = Alignment.Center
        ) {
            // Background glow effect
            Canvas(modifier = Modifier.fillMaxSize()) {
                drawCircle(
                    color = GoldAccent.copy(alpha = 0.1f * scale),
                    radius = size.width * 0.45f
                )
            }

            // Shawarma Illustration
            Canvas(
                modifier = Modifier
                    .size(160.dp)
                    .offset(y = (-10).dp)
            ) {
                // Steam lines rising from top
                val steamOpacity = 0.4f * scale
                drawArc(
                    color = Color.White.copy(alpha = steamOpacity),
                    startAngle = -120f,
                    sweepAngle = 60f,
                    useCenter = false,
                    topLeft = Offset(size.width * 0.35f, size.height * 0.02f),
                    size = Size(size.width * 0.1f, size.height * 0.1f)
                )
                drawArc(
                    color = Color.White.copy(alpha = steamOpacity),
                    startAngle = -120f,
                    sweepAngle = 60f,
                    useCenter = false,
                    topLeft = Offset(size.width * 0.55f, size.height * 0.05f),
                    size = Size(size.width * 0.1f, size.height * 0.1f)
                )

                // Silver wrapper sleeve (bottom of shawarma)
                val wrapperPath = Path().apply {
                    moveTo(size.width * 0.32f, size.height * 0.48f)
                    lineTo(size.width * 0.68f, size.height * 0.48f)
                    lineTo(size.width * 0.62f, size.height * 0.9f)
                    lineTo(size.width * 0.38f, size.height * 0.9f)
                    close()
                }
                drawPath(wrapperPath, color = Color(0xFF7F8C8D)) // Outer dark metal foil
                
                val innerWrapperPath = Path().apply {
                    moveTo(size.width * 0.35f, size.height * 0.55f)
                    lineTo(size.width * 0.65f, size.height * 0.55f)
                    lineTo(size.width * 0.6f, size.height * 0.85f)
                    lineTo(size.width * 0.4f, size.height * 0.85f)
                    close()
                }
                drawPath(innerWrapperPath, color = GoldAccent) // Gold Accent on the wrap sleeve

                // Wrap flatbread (middle part)
                val breadPath = Path().apply {
                    moveTo(size.width * 0.3f, size.height * 0.5f)
                    quadraticTo(size.width * 0.5f, size.height * 0.44f, size.width * 0.7f, size.height * 0.5f)
                    lineTo(size.width * 0.74f, size.height * 0.22f)
                    quadraticTo(size.width * 0.5f, size.height * 0.16f, size.width * 0.26f, size.height * 0.22f)
                    close()
                }
                drawPath(breadPath, color = Color(0xFFF3D19E)) // Golden brown cooked flatbread

                // Diagonal grill marks on wrap
                rotate(degrees = 12f) {
                    drawLine(
                        color = Color(0xFF5D4037),
                        start = Offset(size.width * 0.36f, size.height * 0.4f),
                        end = Offset(size.width * 0.46f, size.height * 0.28f),
                        strokeWidth = 5f
                    )
                    drawLine(
                        color = Color(0xFF5D4037),
                        start = Offset(size.width * 0.46f, size.height * 0.42f),
                        end = Offset(size.width * 0.56f, size.height * 0.3f),
                        strokeWidth = 5f
                    )
                    drawLine(
                        color = Color(0xFF5D4037),
                        start = Offset(size.width * 0.56f, size.height * 0.44f),
                        end = Offset(size.width * 0.66f, size.height * 0.32f),
                        strokeWidth = 5f
                    )
                }

                // Fillings spilling out of the top
                // Green Lettuce
                drawArc(
                    color = Color(0xFF2E7D32),
                    startAngle = 170f,
                    sweepAngle = 100f,
                    useCenter = true,
                    topLeft = Offset(size.width * 0.24f, size.height * 0.14f),
                    size = Size(size.width * 0.22f, size.height * 0.12f)
                )
                // Red Tomatoes/Chillies
                drawArc(
                    color = Color(0xFFD84315),
                    startAngle = 190f,
                    sweepAngle = 100f,
                    useCenter = true,
                    topLeft = Offset(size.width * 0.38f, size.height * 0.11f),
                    size = Size(size.width * 0.24f, size.height * 0.14f)
                )
                // Creamy Garlic Mayo
                drawArc(
                    color = Color(0xFFFFF9C4),
                    startAngle = 210f,
                    sweepAngle = 90f,
                    useCenter = true,
                    topLeft = Offset(size.width * 0.52f, size.height * 0.13f),
                    size = Size(size.width * 0.2f, size.height * 0.12f)
                )
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Premium Typography for Logo
        Text(
            text = "BOOTO",
            color = GoldAccent,
            fontSize = 42.sp,
            fontWeight = FontWeight.Black,
            fontFamily = FontFamily.SansSerif,
            letterSpacing = 2.sp,
            textAlign = TextAlign.Center
        )
        
        Text(
            text = "SHAWARMA POS",
            color = Color.White,
            fontSize = 16.sp,
            fontWeight = FontWeight.Bold,
            fontFamily = FontFamily.SansSerif,
            letterSpacing = 6.sp,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(top = 4.dp)
        )

        Spacer(modifier = Modifier.height(48.dp))

        // Smooth loading animation in gold color
        CircularProgressIndicator(
            color = GoldAccent,
            strokeWidth = 3.dp,
            modifier = Modifier.size(36.dp)
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "Loading POS Terminal...",
            color = Color.Gray,
            fontSize = 12.sp,
            fontFamily = FontFamily.SansSerif
        )
    }
}
