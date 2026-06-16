package com.booto.shawarma.repository

import com.booto.shawarma.data.*
import com.google.gson.Gson
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class POSRepository @Inject constructor(
    private val appDao: AppDao,
    private val apiService: ApiService
) {
    val menuItems: Flow<List<MenuItemEntity>> = appDao.getAllMenuItems()
    val extras: Flow<List<ExtraEntity>> = appDao.getAllExtras()
    val orders: Flow<List<OrderWithItems>> = appDao.getAllOrders()

    private val gson = Gson()

    suspend fun refreshMenu() {
        try {
            val remoteMenu = apiService.getMenu()
            val entities = remoteMenu.map {
                MenuItemEntity(
                    category = it.category,
                    name = it.name,
                    price = it.price,
                    imageUrl = it.imageUrl
                )
            }
            if (entities.isNotEmpty()) {
                appDao.insertMenuItems(entities)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    suspend fun placeOrder(
        type: String,
        total: Double,
        note: String?,
        items: List<OrderItemRequest>,
        customerName: String?,
        customerMobile: String?
    ): Boolean {
        try {
            // 1. Generate local ORD code (read orders length + 1001)
            val currentOrders = appDao.getAllOrders().first()
            val nextNum = 1001 + currentOrders.size
            val orderId = "ORD$nextNum"

            // 2. Insert customer if needed
            var customerId: Int? = null
            if (customerName != null) {
                val existing = customerMobile?.let { appDao.getCustomerByMobile(it) }
                if (existing != null) {
                    customerId = existing.id
                } else {
                    customerId = appDao.insertCustomer(
                        CustomerEntity(name = customerName, mobile = customerMobile)
                    ).toInt()
                }
            }

            // 3. Save order and items locally first
            appDao.insertOrder(
                OrderEntity(
                    id = orderId,
                    type = type,
                    status = "pending",
                    total = total,
                    note = note
                )
            )

            val orderItems = items.map {
                OrderItemEntity(
                    orderId = orderId,
                    menuItemId = it.menuItemId,
                    itemName = it.itemName,
                    quantity = it.quantity,
                    price = it.price,
                    extrasJson = gson.toJson(it.extras)
                )
            }
            appDao.insertOrderItems(orderItems)

            // 4. Send network request
            val networkRequest = OrderRequest(
                type = type,
                total = total,
                note = note,
                items = items,
                customerName = customerName,
                customerMobile = customerMobile
            )
            apiService.createOrder(networkRequest)
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return true 
        }
    }

    suspend fun updateStatus(orderId: String, newStatus: String): Boolean {
        try {
            appDao.updateOrderStatus(orderId, newStatus)
            apiService.updateOrderStatus(orderId, mapOf("status" to newStatus))
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    suspend fun getReports(): ReportsResponse? {
        return try {
            apiService.getReports()
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    suspend fun verifyAdminPin(pin: String): AdminEntity? {
        return try {
            appDao.getAdminByPin(pin)
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}
