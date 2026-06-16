package com.booto.shawarma.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import com.booto.shawarma.ui.theme.DarkBackground
import com.booto.shawarma.ui.theme.DarkCard
import com.booto.shawarma.ui.theme.GoldAccent
import com.booto.shawarma.ui.theme.TextMuted
import com.booto.shawarma.viewmodel.DashboardViewModel
import com.github.mikephil.charting.charts.LineChart
import com.github.mikephil.charting.components.XAxis
import com.github.mikephil.charting.data.Entry
import com.github.mikephil.charting.data.LineData
import com.github.mikephil.charting.data.LineDataSet

@Composable
fun DashboardScreen(
    viewModel: DashboardViewModel,
    onNavigateToNewOrder: () -> Unit,
    onNavigateToOrders: () -> Unit
) {
    val revenue by viewModel.revenue
    val totalOrders by viewModel.totalOrders
    val pendingCount by viewModel.pendingCount
    val averageOrder by viewModel.averageOrder
    val topItems by viewModel.topItems
    val hourlySales by viewModel.hourlySales
    val isLoading by viewModel.isLoading

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBackground)
            .padding(16.dp)
            .verticalScroll(rememberScrollState())
    ) {
        // Title Header
        Text(
            text = "Dashboard",
            fontSize = 28,
            fontWeight = FontWeight.Bold,
            color = Color.White,
            modifier = Modifier.padding(bottom = 16.dp)
        )

        if (isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = GoldAccent)
            }
        } else {
            // 4 Stats Cards Grid
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                StatCard(
                    title = "Today's Sales",
                    value = "₹${revenue.toInt()}",
                    modifier = Modifier.weight(1f)
                )
                StatCard(
                    title = "Total Orders",
                    value = "$totalOrders",
                    modifier = Modifier.weight(1f)
                )
            }
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 24.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                StatCard(
                    title = "Pending Orders",
                    value = "$pendingCount",
                    modifier = Modifier.weight(1f)
                )
                StatCard(
                    title = "Avg Ticket",
                    value = "₹${averageOrder.substringBefore('.')}",
                    modifier = Modifier.weight(1f)
                )
            }

            // Sales Line Chart (MPAndroidChart integration)
            Text(
                text = "Sales Trend Today",
                fontSize = 18,
                fontWeight = FontWeight.Bold,
                color = Color.White,
                modifier = Modifier.padding(bottom = 12.dp)
            )

            Card(
                colors = CardDefaults.cardColors(containerColor = DarkCard),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(220.dp)
                    .padding(bottom = 24.dp)
            ) {
                Box(modifier = Modifier.padding(12.dp)) {
                    AndroidView(
                        factory = { context ->
                            LineChart(context).apply {
                                description.isEnabled = false
                                legend.isEnabled = false
                                setTouchEnabled(false)
                                setDrawGridBackground(false)
                                
                                xAxis.apply {
                                    position = XAxis.XAxisPosition.BOTTOM
                                    textColor = android.graphics.Color.WHITE
                                    setDrawGridLines(false)
                                    granularity = 1f
                                }
                                axisLeft.apply {
                                    textColor = android.graphics.Color.WHITE
                                    setDrawGridLines(true)
                                    gridColor = android.graphics.Color.DKGRAY
                                }
                                axisRight.isEnabled = false
                            }
                        },
                        update = { chart ->
                            val entries = hourlySales.map { Entry(it.hour.toFloat(), it.sales.toFloat()) }
                            if (entries.isNotEmpty()) {
                                val dataSet = LineDataSet(entries, "Today's Sales").apply {
                                    color = android.graphics.Color.parseColor("#F5A623")
                                    valueTextColor = android.graphics.Color.WHITE
                                    lineWidth = 2f
                                    setDrawCircles(true)
                                    setCircleColor(android.graphics.Color.parseColor("#F5A623"))
                                    circleRadius = 3f
                                    setDrawFilled(true)
                                    fillColor = android.graphics.Color.parseColor("#33F5A623")
                                }
                                chart.data = LineData(dataSet)
                                chart.invalidate()
                            }
                        },
                        modifier = Modifier.fillMaxSize()
                    )
                }
            }

            // Top 5 Selling Items List
            Text(
                text = "Top Selling Items",
                fontSize = 18,
                fontWeight = FontWeight.Bold,
                color = Color.White,
                modifier = Modifier.padding(bottom = 12.dp)
            )

            Card(
                colors = CardDefaults.cardColors(containerColor = DarkCard),
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 24.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    if (topItems.isEmpty()) {
                        Text(
                            text = "No items sold yet.",
                            color = TextMuted,
                            fontSize = 14
                        )
                    } else {
                        topItems.forEachIndexed { index, item ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 6.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                alignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "${index + 1}. ${item.itemName}",
                                    color = Color.White,
                                    fontSize = 15,
                                    fontWeight = FontWeight.Medium
                                )
                                Text(
                                    text = "${item.quantitySold} Qty",
                                    color = GoldAccent,
                                    fontSize = 14,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                        }
                    }
                }
            }

            // Quick Action Buttons
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Button(
                    onClick = onNavigateToNewOrder,
                    colors = ButtonDefaults.buttonColors(containerColor = GoldAccent),
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Text("New Order", color = Color.Black, fontWeight = FontWeight.Bold)
                }
                Button(
                    onClick = onNavigateToOrders,
                    colors = ButtonDefaults.buttonColors(containerColor = GoldAccent),
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Text("View Orders", color = Color.Black, fontWeight = FontWeight.Bold)
                }
            }
            Spacer(modifier = Modifier.height(24.dp))
        }
    }
}

@Composable
fun StatCard(title: String, value: String, modifier: Modifier = Modifier) {
    Card(
        colors = CardDefaults.cardColors(containerColor = DarkCard),
        shape = RoundedCornerShape(12.dp),
        modifier = modifier
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(text = title, fontSize = 12, color = TextMuted)
            Spacer(modifier = Modifier.height(8.dp))
            Text(text = value, fontSize = 22, color = Color.White, fontWeight = FontWeight.Bold)
        }
    }
}
