package com.booto.shawarma.viewmodel

import androidx.compose.runtime.State
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.booto.shawarma.data.*
import com.booto.shawarma.repository.POSRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

// ==========================================
// 1. Dashboard View Model
// ==========================================
@HiltViewModel
class DashboardViewModel @Inject constructor(
    private val repository: POSRepository
) : ViewModel() {

    private val _isLoading = mutableStateOf(false)
    val isLoading: State<Boolean> = _isLoading

    private val _revenue = mutableStateOf(0.0)
    val revenue: State<Double> = _revenue

    private val _totalOrders = mutableStateOf(0)
    val totalOrders: State<Int> = _totalOrders

    private val _pendingCount = mutableStateOf(0)
    val pendingCount: State<Int> = _pendingCount

    private val _readyCount = mutableStateOf(0)
    val readyCount: State<Int> = _readyCount

    private val _averageOrder = mutableStateOf("0.0")
    val averageOrder: State<String> = _averageOrder

    private val _topItems = mutableStateOf<List<TopItemData>>(emptyList())
    val topItems: State<List<TopItemData>> = _topItems

    private val _hourlySales = mutableStateOf<List<HourlySalesData>>(emptyList())
    val hourlySales: State<List<HourlySalesData>> = _hourlySales

    init {
        refreshDashboard()
    }

    fun refreshDashboard() {
        viewModelScope.launch {
            _isLoading.value = true
            val response = repository.getReports()
            if (response != null) {
                _revenue.value = response.revenue
                _totalOrders.value = response.totalOrders
                _pendingCount.value = response.pendingOrdersCount
                _readyCount.value = response.readyOrdersCount
                _averageOrder.value = response.averageOrder
                _topItems.value = response.topItems
                _hourlySales.value = response.hourlySales
            } else {
                calculateLocalDashboard()
            }
            _isLoading.value = false
        }
    }

    private suspend fun calculateLocalDashboard() {
        repository.orders.collect { orderList ->
            val todayOrders = orderList.filter { it.order.status != "cancelled" }
            val total = todayOrders.sumOf { it.order.total }
            _revenue.value = total
            _totalOrders.value = todayOrders.size
            _pendingCount.value = orderList.count { it.order.status == "pending" }
            _readyCount.value = orderList.count { it.order.status == "ready" }
            _averageOrder.value = if (todayOrders.isNotEmpty()) (total / todayOrders.size).toString() else "0.0"
        }
    }
}

// ==========================================
// 2. New Order View Model
// ==========================================
data class CartItem(
    val menuItem: MenuItemEntity,
    val quantity: Int,
    val selectedExtras: List<ExtraEntity>,
    val specialNote: String
) {
    val totalItemPrice: Double
        get() = (menuItem.price + selectedExtras.sumOf { it.price }) * quantity
}

@HiltViewModel
class NewOrderViewModel @Inject constructor(
    private val repository: POSRepository
) : ViewModel() {

    val menuItems: StateFlow<List<MenuItemEntity>> = repository.menuItems
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    val extras: StateFlow<List<ExtraEntity>> = repository.extras
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    val cart = mutableStateListOf<CartItem>()

    private val _selectedCategory = mutableStateOf("Shawarma")
    val selectedCategory: State<String> = _selectedCategory

    private val _customerName = mutableStateOf("")
    val customerName: State<String> = _customerName

    private val _customerMobile = mutableStateOf("")
    val customerMobile: State<String> = _customerMobile

    val cartTotal: Double
        get() = cart.sumOf { it.totalItemPrice }

    fun setCategory(category: String) {
        _selectedCategory.value = category
    }

    fun setCustomerInfo(name: String, mobile: String) {
        _customerName.value = name
        _customerMobile.value = mobile
    }

    fun addToCart(item: MenuItemEntity, qty: Int, selectedExtras: List<ExtraEntity>, note: String) {
        cart.add(CartItem(item, qty, selectedExtras, note))
    }

    fun removeFromCart(index: Int) {
        cart.removeAt(index)
    }

    fun clearCart() {
        cart.clear()
        _customerName.value = ""
        _customerMobile.value = ""
    }

    fun placeOrder(orderType: String, onComplete: (Boolean) -> Unit) {
        if (cart.isEmpty()) {
            onComplete(false)
            return
        }
        viewModelScope.launch {
            val requests = cart.map {
                OrderItemRequest(
                    menuItemId = it.menuItem.id,
                    itemName = it.menuItem.name,
                    quantity = it.quantity,
                    price = it.menuItem.price + it.selectedExtras.sumOf { ex -> ex.price },
                    extras = it.selectedExtras.map { ex -> ExtraItem(name = ex.name, price = ex.price) }
                )
            }
            val success = repository.placeOrder(
                type = orderType,
                total = cartTotal,
                note = cart.firstOrNull()?.specialNote ?: "",
                items = requests,
                customerName = _customerName.value.ifBlank { "Walk-in Customer" },
                customerMobile = _customerMobile.value.ifBlank { null }
            )
            if (success) {
                clearCart()
            }
            onComplete(success)
        }
    }
}

// ==========================================
// 3. Orders View Model
// ==========================================
@HiltViewModel
class OrdersViewModel @Inject constructor(
    private val repository: POSRepository
) : ViewModel() {

    val orders: StateFlow<List<OrderWithItems>> = repository.orders
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    val pendingOrders: StateFlow<List<OrderWithItems>> = repository.orders
        .map { list -> list.filter { it.order.status == "pending" } }
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    val readyOrders: StateFlow<List<OrderWithItems>> = repository.orders
        .map { list -> list.filter { it.order.status == "ready" } }
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    fun updateStatus(orderId: String, newStatus: String) {
        viewModelScope.launch {
            repository.updateStatus(orderId, newStatus)
        }
    }
}

// ==========================================
// 4. Sales View Model
// ==========================================
@HiltViewModel
class SalesViewModel @Inject constructor(
    private val repository: POSRepository
) : ViewModel() {

    val salesOrders: StateFlow<List<OrderWithItems>> = repository.orders
        .map { list -> list.filter { it.order.status == "completed" || it.order.status == "ready" } }
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    val cancelledOrders: StateFlow<List<OrderWithItems>> = repository.orders
        .map { list -> list.filter { it.order.status == "cancelled" } }
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())
}

// ==========================================
// 5. Menu View Model
// ==========================================
@HiltViewModel
class MenuViewModel @Inject constructor(
    private val repository: POSRepository
) : ViewModel() {

    val menuItems: StateFlow<List<MenuItemEntity>> = repository.menuItems
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    init {
        viewModelScope.launch {
            repository.refreshMenu()
        }
    }
}
