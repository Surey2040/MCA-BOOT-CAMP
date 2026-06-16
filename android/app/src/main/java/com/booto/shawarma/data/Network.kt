package com.booto.shawarma.data

import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.PUT
import retrofit2.http.Path

interface ApiService {
    @GET("menu")
    suspend fun getMenu(): List<MenuItemResponse>

    @POST("orders")
    suspend fun createOrder(@Body request: OrderRequest): OrderResponse

    @PUT("orders/{id}/status")
    suspend fun updateOrderStatus(@Path("id") id: String, @Body body: Map<String, String>): OrderResponse

    @GET("reports")
    suspend fun getReports(): ReportsResponse
}

data class MenuItemResponse(
    val id: Int,
    val category: String,
    val name: String,
    val price: Double,
    val imageUrl: String?
)

data class OrderRequest(
    val type: String,
    val total: Double,
    val note: String?,
    val items: List<OrderItemRequest>,
    val customerName: String?,
    val customerMobile: String?
)

data class OrderItemRequest(
    val menuItemId: Int,
    val itemName: String,
    val quantity: Int,
    val price: Double,
    val extras: List<ExtraItem>
)

data class OrderResponse(
    val id: String,
    val customerId: Int?,
    val type: String,
    val status: String,
    val total: Double,
    val note: String?,
    val createdAt: String
)

data class ReportsResponse(
    val revenue: Double,
    val totalOrders: Int,
    val pendingOrdersCount: Int,
    val readyOrdersCount: Int,
    val averageOrder: String,
    val hourlySales: List<HourlySalesData>,
    val topItems: List<TopItemData>
)

data class HourlySalesData(
    val hour: Int,
    val sales: Double
)

data class TopItemData(
    val itemName: String,
    val quantitySold: Int,
    val revenue: Double
)
