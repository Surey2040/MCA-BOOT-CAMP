package com.booto.shawarma.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.booto.shawarma.data.*
import com.booto.shawarma.ui.theme.DarkBackground
import com.booto.shawarma.ui.theme.DarkCard
import com.booto.shawarma.ui.theme.GoldAccent
import com.booto.shawarma.ui.theme.TextMuted
import com.booto.shawarma.viewmodel.NewOrderViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NewOrderScreen(
    viewModel: NewOrderViewModel,
    onNavigateToOrders: () -> Unit
) {
    val menuItems by viewModel.menuItems.collectAsState()
    val extrasList by viewModel.extras.collectAsState()
    val selectedCategory by viewModel.selectedCategory
    val cart = viewModel.cart

    // State for temporary item customization
    var selectedItem by remember { mutableStateOf<MenuItemEntity?>(null) }
    var quantity by remember { mutableIntStateOf(1) }
    val selectedExtras = remember { mutableStateListOf<ExtraEntity>() }
    var specialNote by remember { mutableStateOf("") }
    
    var orderType by remember { mutableStateOf("Dine In") }
    var customerNameInput by remember { mutableStateOf("") }
    var customerMobileInput by remember { mutableStateOf("") }

    val filteredItems = remember(menuItems, selectedCategory) {
        menuItems.filter { it.category == selectedCategory }
    }
    val chunkedItems = remember(filteredItems) {
        filteredItems.chunked(2)
    }
    val isKeyboardOpen = WindowInsets.ime.calculateBottomPadding() > 0.dp
    val scrollState = rememberScrollState()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBackground)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(scrollState)
                .padding(16.dp)
                .padding(bottom = 120.dp) // Leave space for bottom summary sheet
        ) {
            // 1. Customer Details Card
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 16.dp),
                colors = CardDefaults.cardColors(containerColor = DarkCard),
                shape = RoundedCornerShape(12.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "Customer Details",
                        color = Color.White,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 0.5.sp,
                        modifier = Modifier.padding(bottom = 12.dp)
                    )
                    OutlinedTextField(
                        value = customerNameInput,
                        onValueChange = { customerNameInput = it },
                        label = { Text("Customer Name", color = TextMuted) },
                        singleLine = true,
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedTextColor = Color.White,
                            unfocusedTextColor = Color.White,
                            focusedBorderColor = GoldAccent,
                            unfocusedBorderColor = Color.Gray,
                            cursorColor = GoldAccent
                        ),
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 8.dp)
                    )
                    OutlinedTextField(
                        value = customerMobileInput,
                        onValueChange = { customerMobileInput = it },
                        label = { Text("Mobile Number (Optional)", color = TextMuted) },
                        singleLine = true,
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedTextColor = Color.White,
                            unfocusedTextColor = Color.White,
                            focusedBorderColor = GoldAccent,
                            unfocusedBorderColor = Color.Gray,
                            cursorColor = GoldAccent
                        ),
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }

            // 2. Select Item Type Row
            Text(
                text = "SELECT ITEM TYPE",
                color = TextMuted,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.sp,
                modifier = Modifier.padding(bottom = 12.dp)
            )
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 20.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                listOf(
                    Triple("Shawarma", "SHAWARMA", Color(0xFFF3D19E)),
                    Triple("Lays Shawarma", "LAYS SHAWARMA", Color(0xFFFFCC00)),
                    Triple("Mug Shawarma", "MUG SHAWARMA", Color(0xFF8D6E63))
                ).forEach { (catId, label, color) ->
                    val isSelected = selectedCategory == catId
                    Card(
                        modifier = Modifier
                            .weight(1f)
                            .clickable {
                                viewModel.setCategory(catId)
                                selectedItem = null // reset selection
                                quantity = 1
                                selectedExtras.clear()
                                specialNote = ""
                            }
                            .border(
                                border = BorderStroke(
                                    width = if (isSelected) 2.dp else 1.dp,
                                    color = if (isSelected) GoldAccent else Color.Transparent
                                ),
                                shape = RoundedCornerShape(12.dp)
                            ),
                        colors = CardDefaults.cardColors(containerColor = DarkCard),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(12.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center
                        ) {
                            // Render item type visual representation
                            TypeThumbnail(category = catId, color = color)
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = label,
                                color = if (isSelected) GoldAccent else Color.White,
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Bold,
                                textAlign = TextAlign.Center
                            )
                        }
                    }
                }
            }

            // 3. Choose Variant Grid
            val typeTitle = selectedCategory.uppercase()
            Text(
                text = "CHOOSE $typeTitle TYPE",
                color = TextMuted,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.sp,
                modifier = Modifier.padding(bottom = 12.dp)
            )

            if (filteredItems.isEmpty()) {
                Text(
                    text = "No variants found under this category.",
                    color = TextMuted,
                    fontSize = 13.sp,
                    modifier = Modifier.padding(bottom = 20.dp)
                )
            } else {
                // Display items in structured grid rows of 2
                val chunked = chunkedItems
                Column(
                    modifier = Modifier.fillMaxWidth().padding(bottom = 20.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    chunked.forEach { rowItems ->
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            rowItems.forEach { item ->
                                val isSelected = selectedItem?.id == item.id
                                Box(
                                    modifier = Modifier
                                        .weight(1f)
                                        .clickable {
                                            selectedItem = item
                                            quantity = 1
                                            selectedExtras.clear()
                                        }
                                        .background(DarkCard, shape = RoundedCornerShape(12.dp))
                                        .border(
                                            border = BorderStroke(
                                                width = if (isSelected) 2.dp else 1.dp,
                                                color = if (isSelected) GoldAccent else Color.Transparent
                                            ),
                                            shape = RoundedCornerShape(12.dp)
                                        )
                                        .padding(12.dp)
                                ) {
                                    Column(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalAlignment = Alignment.CenterHorizontally
                                    ) {
                                        VariantThumbnail(category = selectedCategory, name = item.name)
                                        Spacer(modifier = Modifier.height(6.dp))
                                        Text(
                                            text = item.name,
                                            color = Color.White,
                                            fontSize = 12.sp,
                                            fontWeight = FontWeight.Bold,
                                            textAlign = TextAlign.Center,
                                            maxLines = 1,
                                            overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis
                                        )
                                        Text(
                                            text = "₹${item.price.toInt()}",
                                            color = GoldAccent,
                                            fontSize = 13.sp,
                                            fontWeight = FontWeight.Bold
                                        )
                                    }

                                    // Selection badge
                                    if (isSelected) {
                                        Box(
                                            modifier = Modifier
                                                .size(16.dp)
                                                .background(GoldAccent, CircleShape)
                                                .align(Alignment.TopEnd),
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Icon(
                                                imageVector = Icons.Default.Check,
                                                contentDescription = "Selected",
                                                tint = Color.Black,
                                                modifier = Modifier.size(10.dp)
                                            )
                                        }
                                    }
                                }
                            }
                            // Pad remaining cells if chunk is incomplete
                            if (rowItems.size < 2) {
                                repeat(2 - rowItems.size) {
                                    Spacer(modifier = Modifier.weight(1f))
                                }
                            }
                        }
                    }
                }
            }

            // 4. Quantity Selector Row
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 12.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "QUANTITY",
                    color = Color.White,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold
                )
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    IconButton(
                        onClick = { if (quantity > 1) quantity-- },
                        modifier = Modifier
                            .size(36.dp)
                            .background(DarkCard, RoundedCornerShape(8.dp))
                    ) {
                        Text("-", color = GoldAccent, fontSize = 20.sp, fontWeight = FontWeight.Bold)
                    }
                    Text(
                        text = "$quantity",
                        color = Color.White,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold
                    )
                    IconButton(
                        onClick = { quantity++ },
                        modifier = Modifier
                            .size(36.dp)
                            .background(DarkCard, RoundedCornerShape(8.dp))
                    ) {
                        Text("+", color = GoldAccent, fontSize = 20.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }

            // Divider
            HorizontalDivider(color = Color(0xFF222222), thickness = 1.dp, modifier = Modifier.padding(vertical = 12.dp))

            // 5. Extras Checklist
            Text(
                text = "EXTRAS",
                color = Color.White,
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(bottom = 8.dp)
            )
            extrasList.forEach { extra ->
                val isChecked = selectedExtras.any { it.id == extra.id }
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable {
                            if (isChecked) selectedExtras.removeAll { it.id == extra.id }
                            else selectedExtras.add(extra)
                        }
                        .padding(vertical = 8.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = extra.name,
                        color = Color.White,
                        fontSize = 13.sp
                    )
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = "₹${extra.price.toInt()}",
                            color = TextMuted,
                            fontSize = 12.sp,
                            modifier = Modifier.padding(right = 12.dp)
                        )
                        Checkbox(
                            checked = isChecked,
                            onCheckedChange = {
                                if (isChecked) selectedExtras.removeAll { it.id == extra.id }
                                else selectedExtras.add(extra)
                            },
                            colors = CheckboxDefaults.colors(
                                checkedColor = GoldAccent,
                                uncheckedColor = Color.Gray,
                                checkmarkColor = Color.Black
                            )
                        )
                    }
                }
            }

            // Divider
            HorizontalDivider(color = Color(0xFF222222), thickness = 1.dp, modifier = Modifier.padding(vertical = 12.dp))

            // 6. Special Instructions Note
            Text(
                text = "SPECIAL INSTRUCTIONS (Optional)",
                color = Color.White,
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(bottom = 8.dp)
            )
            OutlinedTextField(
                value = specialNote,
                onValueChange = { specialNote = it },
                placeholder = { Text("Add special requests...", color = TextMuted) },
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = Color.White,
                    unfocusedTextColor = Color.White,
                    focusedBorderColor = GoldAccent,
                    unfocusedBorderColor = Color.Gray,
                    cursorColor = GoldAccent
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 24.dp)
            )

            // 7. Order Cart Overview (If Cart is not empty)
            if (cart.isNotEmpty()) {
                HorizontalDivider(color = Color(0xFF222222), thickness = 1.dp, modifier = Modifier.padding(vertical = 12.dp))
                Text(
                    text = "ORDER CART (${cart.size} ITEMS)",
                    color = Color.White,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(bottom = 12.dp)
                )

                cart.forEachIndexed { index, cartItem ->
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 8.dp),
                        colors = CardDefaults.cardColors(containerColor = DarkCard),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Row(
                            modifier = Modifier.padding(12.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            alignment = Alignment.CenterVertically
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = "${cartItem.quantity}x ${cartItem.menuItem.name}",
                                    color = Color.White,
                                    fontSize = 13.sp,
                                    fontWeight = FontWeight.Bold
                                )
                                if (cartItem.selectedExtras.isNotEmpty()) {
                                    Text(
                                        text = "Extras: " + cartItem.selectedExtras.joinToString { it.name },
                                        color = TextMuted,
                                        fontSize = 11.sp
                                    )
                                }
                                if (cartItem.specialNote.isNotBlank()) {
                                    Text(
                                        text = "Note: ${cartItem.specialNote}",
                                        color = GoldAccent,
                                        fontSize = 11.sp
                                    )
                                }
                            }
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = "₹${cartItem.totalItemPrice.toInt()}",
                                    color = Color.White,
                                    fontSize = 13.sp,
                                    fontWeight = FontWeight.Bold
                                )
                                IconButton(
                                    onClick = { viewModel.removeFromCart(index) },
                                    modifier = Modifier.padding(left = 8.dp)
                                ) {
                                    Text("✕", color = Color.Red, fontWeight = FontWeight.Bold)
                                }
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Order Mode Toggle
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 16.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    listOf("Dine In", "Take Away").forEach { mode ->
                        val isSelected = orderType == mode
                        Button(
                            onClick = { orderType = mode },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = if (isSelected) GoldAccent else DarkCard
                            ),
                            shape = RoundedCornerShape(8.dp),
                            modifier = Modifier.weight(1f)
                        ) {
                            Text(
                                text = mode,
                                color = if (isSelected) Color.Black else Color.White,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }

                // Final Order Placement
                Button(
                    onClick = {
                        viewModel.setCustomerInfo(customerNameInput, customerMobileInput)
                        viewModel.placeOrder(orderType) { success ->
                            if (success) {
                                customerNameInput = ""
                                customerMobileInput = ""
                                onNavigateToOrders()
                            }
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = GoldAccent),
                    shape = RoundedCornerShape(8.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(50.dp)
                ) {
                    Text(
                        text = "PLACE ORDER (₹${viewModel.cartTotal.toInt()})",
                        color = Color.Black,
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp
                    )
                }
                
                TextButton(
                    onClick = { viewModel.clearCart() },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 8.dp)
                ) {
                    Text("Discard Order", color = Color.Red, fontWeight = FontWeight.Bold)
                }
            }
        }

        // 8. Sticky Bottom Product Summary Card
        if (selectedItem != null && !isKeyboardOpen) {
            val item = selectedItem!!
            val extrasCost = selectedExtras.sumOf { it.price }
            val totalItemCost = (item.price + extrasCost) * quantity

            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .align(Alignment.BottomCenter)
                    .padding(16.dp),
                colors = CardDefaults.cardColors(containerColor = DarkCard),
                shape = RoundedCornerShape(16.dp),
                elevation = CardDefaults.cardElevation(defaultElevation = 12.dp)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    // Item Info Row
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Box(
                            modifier = Modifier
                                .size(40.dp)
                                .background(Color(0xFF222222), RoundedCornerShape(8.dp)),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = when (selectedCategory) {
                                    "Shawarma" -> "🌯"
                                    "Lays Shawarma" -> "🍟"
                                    else -> "🍲"
                                },
                                fontSize = 20.sp
                            )
                        }
                        Spacer(modifier = Modifier.width(10.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = item.name,
                                color = Color.White,
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold,
                                maxLines = 1,
                                overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis
                            )
                            Text(
                                text = "Qty: $quantity   Extras: ${selectedExtras.size}",
                                color = TextMuted,
                                fontSize = 12.sp
                            )
                        }
                        Text(
                            text = "₹${totalItemCost.toInt()}",
                            color = GoldAccent,
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }

                    // Action Buttons Row
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Button(
                            onClick = {
                                selectedItem = null
                                quantity = 1
                                selectedExtras.clear()
                                specialNote = ""
                            },
                            colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.Red),
                            border = BorderStroke(1.dp, Color.Red),
                            shape = RoundedCornerShape(8.dp),
                            modifier = Modifier
                                .weight(1f)
                                .height(42.dp),
                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)
                        ) {
                            Text("CANCEL", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                        }
                        
                        Button(
                            onClick = {
                                viewModel.addToCart(item, quantity, selectedExtras.toList(), specialNote)
                                selectedItem = null
                                quantity = 1
                                selectedExtras.clear()
                                specialNote = ""
                            },
                            colors = ButtonDefaults.buttonColors(containerColor = GoldAccent),
                            shape = RoundedCornerShape(8.dp),
                            modifier = Modifier
                                .weight(1.5f)
                                .height(42.dp),
                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)
                        ) {
                            Text("ADD TO ORDER", color = Color.Black, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun TypeThumbnail(category: String, color: Color) {
    Box(
        modifier = Modifier
            .size(50.dp)
            .background(color.copy(alpha = 0.05f), RoundedCornerShape(10.dp)),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = when (category) {
                "Shawarma" -> "🌯"
                "Lays Shawarma" -> "🍟"
                else -> "🍲"
            },
            fontSize = 26.sp
        )
    }
}

@Composable
fun VariantThumbnail(category: String, name: String) {
    Box(
        modifier = Modifier
            .size(44.dp)
            .background(Color(0xFF222222), CircleShape),
        contentAlignment = Alignment.Center
    ) {
        // Render detailed variant representations matching the color schemes in the screenshot
        Text(
            text = when (category) {
                "Shawarma" -> "🌯"
                "Lays Shawarma" -> {
                    // Different colored bags
                    when {
                        name.contains("Classic", ignoreCase = true) -> "🥔" // Yellow classic bag
                        name.contains("Spanish", ignoreCase = true) -> "🍟" // Red packet
                        name.contains("Cream", ignoreCase = true) -> "🥗" // Green packet
                        else -> "🌶️" // Chili bag
                    }
                }
                else -> {
                    // Mug configurations
                    when {
                        name.contains("Spicy", ignoreCase = true) -> "🍜"
                        name.contains("Peri Peri", ignoreCase = true) -> "🍲"
                        else -> "🍛"
                    }
                }
            },
            fontSize = 22.sp
        )
    }
}
