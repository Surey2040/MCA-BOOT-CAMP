import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../services/db_helper.dart';
import '../services/sync_service.dart';

class CartProvider extends ChangeNotifier {
  // Current Cart Composition
  final List<OrderItem> _cartItems = [];
  String _orderType = 'Dine In'; // 'Dine In', 'Take Away'
  double _discount = 0.0;
  String _customerName = '';
  String _customerMobile = '';

  // Active item configurations (for the "Choose Variant / Quantity / Extras" pane)
  MenuItem? _activeMenuItem;
  int _activeQuantity = 1;
  final List<ExtraItem> _activeExtras = [];
  String _activeSpecialInstructions = '';

  List<OrderItem> get cartItems => _cartItems;
  String get orderType => _orderType;
  double get discount => _discount;
  String get customerName => _customerName;
  String get customerMobile => _customerMobile;

  MenuItem? get activeMenuItem => _activeMenuItem;
  int get activeQuantity => _activeQuantity;
  List<ExtraItem> get activeExtras => _activeExtras;
  String get activeSpecialInstructions => _activeSpecialInstructions;

  // Static Extras list for Booto Shawarma
  final List<ExtraItem> availableExtras = [
    ExtraItem(name: 'Extra Cheese', price: 20.0),
    ExtraItem(name: 'Extra Mayo', price: 10.0),
    ExtraItem(name: 'Extra Peri Peri', price: 10.0),
  ];

  // Active configurations helpers
  void configureActiveItem(MenuItem item) {
    _activeMenuItem = item;
    _activeQuantity = 1;
    _activeExtras.clear();
    _activeSpecialInstructions = '';
    notifyListeners();
  }

  void updateActiveQuantity(int qty) {
    if (qty >= 1) {
      _activeQuantity = qty;
      notifyListeners();
    }
  }

  void toggleActiveExtra(ExtraItem extra) {
    final index = _activeExtras.indexWhere((e) => e.name == extra.name);
    if (index != -1) {
      _activeExtras.removeAt(index);
    } else {
      _activeExtras.add(extra);
    }
    notifyListeners();
  }

  void updateActiveSpecialInstructions(String notes) {
    _activeSpecialInstructions = notes;
    notifyListeners();
  }

  double get activeItemUnitPrice {
    if (_activeMenuItem == null) return 0.0;
    double extrasPrice = _activeExtras.fold(0.0, (sum, extra) => sum + extra.price);
    return _activeMenuItem!.price + extrasPrice;
  }

  double get activeItemTotal {
    return _activeQuantity * activeItemUnitPrice;
  }

  // Cart modifications
  void addActiveItemToCart() {
    if (_activeMenuItem == null) return;

    final id = 'OI-${DateTime.now().millisecondsSinceEpoch}-${_cartItems.length}';
    final unitPrice = activeItemUnitPrice;

    final item = OrderItem(
      id: id,
      orderId: '', // Filled during checkout
      menuItemId: _activeMenuItem!.id,
      itemName: _activeMenuItem!.name,
      quantity: _activeQuantity,
      price: unitPrice,
      extras: List.from(_activeExtras),
      specialInstructions: _activeSpecialInstructions,
    );

    _cartItems.add(item);
    
    // Reset configurations
    _activeMenuItem = null;
    _activeQuantity = 1;
    _activeExtras.clear();
    _activeSpecialInstructions = '';
    notifyListeners();
  }

  void removeCartItem(String itemId) {
    _cartItems.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  void setOrderType(String type) {
    _orderType = type;
    notifyListeners();
  }

  void setDiscount(double amount) {
    _discount = amount;
    notifyListeners();
  }

  void setCustomerDetails(String name, String mobile) {
    _customerName = name;
    _customerMobile = mobile;
    notifyListeners();
  }

  // Aggregation properties
  double get subtotal {
    return _cartItems.fold(0.0, (sum, item) => sum + item.total);
  }

  double get total {
    double res = subtotal - _discount;
    return res < 0 ? 0.0 : res;
  }

  void clearCart() {
    _cartItems.clear();
    _orderType = 'Dine In';
    _discount = 0.0;
    _customerName = '';
    _customerMobile = '';
    _activeMenuItem = null;
    notifyListeners();
  }

  // Submit/Checkout POS Order
  Future<Order?> checkout() async {
    if (_cartItems.isEmpty) return null;

    try {
      final db = DbHelper.instance;
      
      // Get or register customer in SQLite
      int? dbCustomerId;
      if (_customerName.isNotEmpty) {
        final cust = await db.getOrCreateCustomer(_customerName, _customerMobile.isNotEmpty ? _customerMobile : null);
        dbCustomerId = cust.id;
      }

      final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}-${hashCode.toString().substring(0, 4)}';
      
      // Build order number locally
      final formattedDate = DateTime.now().toIso8601String().substring(2, 10).replaceAll('-', '');
      final orderNumber = '#ORD$formattedDate-${(DateTime.now().millisecond).toString().padLeft(3, '0')}';

      final List<OrderItem> finalizedItems = _cartItems.map((item) {
        return OrderItem(
          id: item.id,
          orderId: orderId,
          menuItemId: item.menuItemId,
          itemName: item.itemName,
          quantity: item.quantity,
          price: item.price,
          extras: item.extras,
          specialInstructions: item.specialInstructions,
        );
      }).toList();

      final order = Order(
        id: orderId,
        customerId: dbCustomerId,
        customerName: _customerName.isNotEmpty ? _customerName : null,
        customerMobile: _customerMobile.isNotEmpty ? _customerMobile : null,
        orderNumber: orderNumber,
        orderType: _orderType,
        subtotal: subtotal,
        discount: _discount,
        total: total,
        status: 'pending',
        createdAt: DateTime.now(),
        synced: false,
        items: finalizedItems,
      );

      // Save to SQLite
      await db.insertOrder(order);

      // Trigger sync in background asynchronously
      SyncService.synchronize().then((success) {
        if (success) {
          print('Background sync after checkout completed successfully.');
        }
      });

      // Clear local cart
      clearCart();
      return order;
    } catch (e) {
      print('Checkout transaction failure: $e');
    }
    return null;
  }
}
