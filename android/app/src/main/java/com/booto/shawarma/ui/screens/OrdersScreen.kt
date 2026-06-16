package com.booto.shawarma.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.booto.shawarma.data.*
import com.booto.shawarma.ui.theme.*
import com.booto.shawarma.viewmodel.OrdersViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OrdersScreen(
    viewModel: OrdersViewModel
) {
    val orders by viewModel.orders.collectAsState()
    val pendingOrders by viewModel.pendingOrders.collectAsState()
    val readyOrders by viewModel.readyOrders.collectAsState()

    var selectedTab by remember { mutableIntStateOf(0) } 
    var activeOrderDetails by remember { mutableStateOf<OrderWithItems?>(null) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBackground)
            .padding(16.dp)
    ) {
        // Header
        Text(
            text = "Active Orders",
            fontSize = 28,
            fontWeight = FontWeight.Bold,
            color = Color.White,
            modifier = Modifier.padding(bottom = 16.dp)
        )

        // Tabs
        TabRow(
            selectedTabIndex = selectedTab,
            containerColor = DarkCard,
            contentColor = GoldAccent,
            modifier = Modifier.padding(bottom = 16.dp)
        ) {
            Tab(
                selected = selectedTab == 0,
                onClick = { selectedTab = 0 },
                text = { Text("Pending (${pendingOrders.size})", fontWeight = FontWeight.Bold) }
            )
            Tab(
                selected = selectedTab == 1,
                onClick = { selectedTab = 1 },
                text = { Text("Ready (${readyOrders.size})", fontWeight = FontWeight.Bold) }
            )
        }

        // List
        val activeList = if (selectedTab == 0) pendingOrders else readyOrders

        if (activeList.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text("No orders in this state.", color = TextMuted)
            }
        } else {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                items(activeList) { item ->
                    OrderCard(orderWithItems = item) {
                        activeOrderDetails = item
                    }
                }
            }
        }

        // Detail Bottom Sheet
        activeOrderDetails?.let { detail ->
            ModalBottomSheet(
                onDismissRequest = { activeOrderDetails = null },
                containerColor = DarkCard
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(24.dp)
                ) {
                    Text(
                        text = "Order Details: ${detail.order.id}",
                        fontSize = 20,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = "Type: ${detail.order.type} • Status: ${detail.order.status.uppercase()}",
                        color = GoldAccent,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 14.sp
                    )
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    Text("Items Ordered", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 15.sp)
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    detail.items.forEach { orderItem ->
                        Row(
                            modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Column {
                                Text("${orderItem.quantity}x ${orderItem.itemName}", color = Color.White, fontSize = 14.sp)
                                if (orderItem.extrasJson.isNotBlank() && orderItem.extrasJson != "[]") {
                                    Text("Extras: ${orderItem.extrasJson}", color = TextMuted, fontSize = 12.sp)
                                }
                            }
                            Text("₹${orderItem.price.toInt() * orderItem.quantity}", color = Color.White, fontSize = 14.sp)
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))
                    HorizontalDivider(color = DarkBackground, thickness = 1.dp)
                    Spacer(modifier = Modifier.height(12.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("Total Bill:", color = Color.White, fontWeight = FontWeight.Bold)
                        Text("₹${detail.order.total.toInt()}", color = GoldAccent, fontWeight = FontWeight.Bold, fontSize = 18.sp)
                    }

                    if (detail.order.note?.isNotBlank() == true) {
                        Text(
                            text = "Special Note: ${detail.order.note}",
                            color = TextMuted,
                            fontSize = 13.sp,
                            modifier = Modifier.padding(top = 12.dp)
                        )
                    }

                    Spacer(modifier = Modifier.height(32.dp))

                    // Buttons Actions
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        if (detail.order.status == "pending") {
                            Button(
                                onClick = {
                                    viewModel.updateStatus(detail.order.id, "ready")
                                    activeOrderDetails = null
                                },
                                colors = ButtonDefaults.buttonColors(containerColor = GoldAccent),
                                shape = RoundedCornerShape(8.dp),
                                modifier = Modifier.weight(1f)
                            ) {
                                Text("MARK READY", color = Color.Black, fontWeight = FontWeight.Bold)
                            }
                        } else if (detail.order.status == "ready") {
                            Button(
                                onClick = {
                                    viewModel.updateStatus(detail.order.id, "completed")
                                    activeOrderDetails = null
                                },
                                colors = ButtonDefaults.buttonColors(containerColor = GoldAccent),
                                shape = RoundedCornerShape(8.dp),
                                modifier = Modifier.weight(1f)
                            ) {
                                Text("COMPLETE", color = Color.Black, fontWeight = FontWeight.Bold)
                            }
                        }

                        Button(
                            onClick = {
                                viewModel.updateStatus(detail.order.id, "cancelled")
                                activeOrderDetails = null
                            },
                            colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.Red),
                            border = BorderStroke(1.dp, Color.Red),
                            shape = RoundedCornerShape(8.dp),
                            modifier = Modifier.weight(1f)
                        ) {
                            Text("CANCEL", fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun OrderCard(
    orderWithItems: OrderWithItems,
    onClick: () -> Unit
) {
    Card(
        colors = CardDefaults.cardColors(containerColor = DarkCard),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() }
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                alignment = Alignment.CenterVertically
            ) {
                Text(
                    text = orderWithItems.order.id,
                    fontWeight = FontWeight.Bold,
                    fontSize = 16.sp,
                    color = GoldAccent
                )
                
                val stat = orderWithItems.order.status
                val badgeColor = when (stat) {
                    "ready" -> StatusReady
                    "cancelled" -> StatusCancelled
                    else -> GoldAccent
                }
                
                Card(
                    colors = CardDefaults.cardColors(containerColor = badgeColor.copy(alpha = 0.15f)),
                    shape = RoundedCornerShape(4.dp)
                ) {
                    Text(
                        text = stat.uppercase(),
                        color = badgeColor,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(10.dp))
            
            Text(
                text = "${orderWithItems.items.sumOf { it.quantity }} items • ₹${orderWithItems.order.total.toInt()}",
                color = Color.White,
                fontWeight = FontWeight.Medium,
                fontSize = 14.sp
            )
            
            Text(
                text = "Type: ${orderWithItems.order.type}",
                color = TextMuted,
                fontSize = 12.sp,
                modifier = Modifier.padding(top = 4.dp)
            )
        }
    }
}
