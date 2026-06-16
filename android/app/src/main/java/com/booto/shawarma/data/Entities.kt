package com.booto.shawarma.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "customers")
data class CustomerEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val name: String,
    val mobile: String?
)

@Entity(tableName = "menu_items")
data class MenuItemEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val category: String, 
    val name: String,
    val price: Double,
    val imageUrl: String? = null
)

@Entity(tableName = "extras")
data class ExtraEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val name: String,
    val price: Double
)

@Entity(tableName = "orders")
data class OrderEntity(
    @PrimaryKey val id: String, 
    val type: String, 
    val status: String, 
    val total: Double,
    val note: String?,
    val timestamp: Long = System.currentTimeMillis()
)

@Entity(tableName = "order_items")
data class OrderItemEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val orderId: String,
    val menuItemId: Int,
    val itemName: String,
    val quantity: Int,
    val price: Double,
    val extrasJson: String 
)

data class ExtraItem(
    val name: String,
    val price: Double
)

@Entity(tableName = "admin")
data class AdminEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val name: String,
    val pin: String
)

