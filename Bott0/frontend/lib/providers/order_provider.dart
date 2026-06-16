import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/order.dart';
import '../services/db_helper.dart';
import '../services/sync_service.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;

  List<Order> get pendingOrders => _orders.where((o) => o.status == 'pending').toList();
  List<Order> get preparingOrders => _orders.where((o) => o.status == 'preparing').toList();
  List<Order> get readyOrders => _orders.where((o) => o.status == 'ready').toList();
  List<Order> get completedOrders => _orders.where((o) => o.status == 'completed').toList();
  List<Order> get cancelledOrders => _orders.where((o) => o.status == 'cancelled').toList();

  // Load orders from local SQLite database
  Future<void> loadOrdersLocal() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = DbHelper.instance;
      _orders = await db.getOrders();
    } catch (e) {
      print('Error loading orders: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update status (mark ready / cancel)
  Future<bool> updateStatus(String orderId, String newStatus) async {
    try {
      final db = DbHelper.instance;
      final isOnline = await SyncService.isServerOnline();

      // 1. Update SQLite locally first
      await db.updateOrderStatus(orderId, newStatus);
      
      // Update in our memory list
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(status: newStatus, synced: false);
      }
      notifyListeners();

      // 2. If online, sync status modification immediately to server
      if (isOnline) {
        final baseUrl = await SyncService.getBaseUrl();
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');

        final response = await http.put(
          Uri.parse('$baseUrl/orders/$orderId/status'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'status': newStatus}),
        );

        if (response.statusCode == 200) {
          // Mark as synced in SQLite since server acknowledged
          await db.markOrdersAsSynced([orderId]);
          if (index != -1) {
            _orders[index] = _orders[index].copyWith(synced: true);
          }
          notifyListeners();
          return true;
        }
      }
      
      // Attempt background synchronisation
      SyncService.synchronize();
      return true;
    } catch (e) {
      print('Status change failure: $e');
    }
    return false;
  }

  // Reload and Sync
  Future<void> refreshOrders() async {
    _isLoading = true;
    notifyListeners();

    // Trigger sync
    await SyncService.synchronize();
    
    // Reload local files
    await loadOrdersLocal();

    _isLoading = false;
    notifyListeners();
  }

  // --- Local Dashboard Analytical Calculations (For Offline Support) ---
  
  double get todaySales {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final todayOrders = _orders.where((o) => 
        o.createdAt.toIso8601String().startsWith(todayStr) && 
        o.status != 'cancelled'
    );
    return todayOrders.fold(0.0, (sum, o) => sum + o.total);
  }

  int get todayOrdersCount {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    return _orders.where((o) => 
        o.createdAt.toIso8601String().startsWith(todayStr) && 
        o.status != 'cancelled'
    ).length;
  }

  int get pendingOrdersCount => pendingOrders.length;
  int get preparingOrdersCount => preparingOrders.length;
  int get readyOrdersCount => readyOrders.length;
  int get cancelledOrdersCount => cancelledOrders.length;

  double get averageOrderValue {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final todayOrders = _orders.where((o) => 
        o.createdAt.toIso8601String().startsWith(todayStr) && 
        o.status != 'cancelled'
    ).toList();
    
    if (todayOrders.isEmpty) return 0.0;
    return todaySales / todayOrders.length;
  }

  // Local calculation of Top Selling Items (reads from local memory orders)
  List<Map<String, dynamic>> get localTopSellingItems {
    final itemQuantities = <String, int>{};
    
    for (var o in _orders) {
      if (o.status == 'cancelled') continue;
      for (var item in o.items) {
        final name = item.itemName ?? 'Unknown Item';
        itemQuantities[name] = (itemQuantities[name] ?? 0) + item.quantity;
      }
    }

    final sortedList = itemQuantities.entries.map((e) => {
      'name': e.key,
      'quantity': e.value,
    }).toList();

    sortedList.sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));
    return sortedList.take(5).toList();
  }
}
