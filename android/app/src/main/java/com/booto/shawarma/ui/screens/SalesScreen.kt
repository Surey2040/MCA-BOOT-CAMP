package com.booto.shawarma.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.booto.shawarma.ui.theme.DarkBackground
import com.booto.shawarma.ui.theme.DarkCard
import com.booto.shawarma.ui.theme.GoldAccent
import com.booto.shawarma.ui.theme.TextMuted
import com.booto.shawarma.viewmodel.SalesViewModel

@Composable
fun SalesScreen(
    viewModel: SalesViewModel
) {
    val salesOrders by viewModel.salesOrders.collectAsState()

    val totalRevenue = salesOrders.sumOf { it.order.total }
    val totalSalesCount = salesOrders.size

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBackground)
            .padding(16.dp)
    ) {
        Text(
            text = "Sales & Reports",
            fontSize = 28,
            fontWeight = FontWeight.Bold,
            color = Color.White,
            modifier = Modifier.padding(bottom = 16.dp)
        )

        // Summary Card
        Card(
            colors = CardDefaults.cardColors(containerColor = DarkCard),
            shape = RoundedCornerShape(12.dp),
            modifier = Modifier.fillMaxWidth().padding(bottom = 20.dp)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text("TODAY'S REVENUE SUMMARY", fontSize = 12.sp, color = TextMuted, fontWeight = FontWeight.Bold)
                Spacer(modifier = Modifier.height(10.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column {
                        Text("Gross Revenue", fontSize = 13.sp, color = TextMuted)
                        Text("₹${totalRevenue.toInt()}", fontSize = 24.sp, color = GoldAccent, fontWeight = FontWeight.Bold)
                    }
                    Column {
                        Text("Orders Count", fontSize = 13.sp, color = TextMuted)
                        Text("$totalSalesCount", fontSize = 24.sp, color = Color.White, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }

        Text(
            text = "Order Transaction History",
            fontSize = 18,
            fontWeight = FontWeight.Bold,
            color = Color.White,
            modifier = Modifier.padding(bottom = 12.dp)
        )

        LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            items(salesOrders) { order ->
                Row(
                    modifier = Modifier.fillMaxWidth().background(DarkCard, shape = RoundedCornerShape(8.dp)).padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column {
                        Text(order.order.id, color = Color.White, fontWeight = FontWeight.Bold)
                        Text("Type: ${order.order.type} • Status: ${order.order.status.uppercase()}", color = TextMuted, fontSize = 12.sp)
                    }
                    Text("₹${order.order.total.toInt()}", color = GoldAccent, fontWeight = FontWeight.Bold)
                }
            }
            if (salesOrders.isEmpty()) {
                item {
                    Text("No transactions logged today.", color = TextMuted, modifier = Modifier.padding(vertical = 12.dp))
                }
            }
        }
    }
}
