import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../services/db_helper.dart';
import '../services/sync_service.dart';
import '../models/order.dart';

class DashboardProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isOnline = false;

  double _revenue = 0.0;
  int _totalOrders = 0;
  int _pendingOrders = 0;
  int _readyOrders = 0;
  String _topSellingItem = 'N/A';
  
  List<Map<String, dynamic>> _topItems = [];
  List<Map<String, dynamic>> _categorySales = [];
  List<Order> _recentOrders = [];

  double get revenue => _revenue;
  int get totalOrders => _totalOrders;
  int get pendingOrdersCount => _pendingOrders;
  int get readyOrdersCount => _readyOrders;
  String get topSellingItem => _topSellingItem;
  
  List<Map<String, dynamic>> get topItems => _topItems;
  List<Map<String, dynamic>> get categorySales => _categorySales;
  List<Order> get recentOrders => _recentOrders;
  
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;

  // Collection breakdown (40% Cash, 45% UPI, 15% Card)
  double get cashSales => _revenue * 0.40;
  double get upiSales => _revenue * 0.45;
  double get cardSales => _revenue * 0.15;

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Sync data first so local DB matches server before calculations
      await SyncService.synchronize();

      // 2. Check server connectivity
      _isOnline = await SyncService.isServerOnline();

      // Load recent orders from local DB (for recent orders list)
      final allLocalOrders = await DbHelper.instance.getOrders();
      _recentOrders = allLocalOrders.take(5).toList();

      if (_isOnline) {
        final baseUrl = await SyncService.getBaseUrl();
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');

        final response = await http.get(
          Uri.parse('$baseUrl/reports?range=today'),
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          _revenue = (data['revenue'] as num?)?.toDouble() ?? 0.0;
          _totalOrders = (data['totalOrders'] as num?)?.toInt() ?? 0;
          _pendingOrders = (data['pendingOrders'] as num?)?.toInt() ?? 0;
          _readyOrders = (data['readyOrders'] as num?)?.toInt() ?? 0;
          _topSellingItem = data['topSellingItem'] ?? 'N/A';
          
          // Parse topItems list
          final itemsList = data['topItems'] as List?;
          _topItems = itemsList?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];

          // Parse categorySales list
          final catsList = data['categorySales'] as List?;
          _categorySales = catsList?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];

          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // Offline or API failure: Fallback to local SQLite queries
      await _calculateLocalStats();

    } catch (e) {
      print('Dashboard data fetch failed: $e');
      // If error occurs, fall back to local calculations
      await _calculateLocalStats();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _calculateLocalStats() async {
    try {
      final db = DbHelper.instance;
      final localOrders = await db.getOrders();

      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final todayOrders = localOrders.where((o) => 
        o.createdAt.toIso8601String().startsWith(todayStr) && 
        o.status != 'cancelled'
      ).toList();

      // Today's Sales Revenue
      _revenue = todayOrders.fold(0.0, (sum, o) => sum + o.total);
      
      // Total Orders count
      _totalOrders = todayOrders.length;

      // Pending (pending, preparing) & Ready Counts
      _pendingOrders = localOrders.where((o) => o.status == 'pending' || o.status == 'preparing').length;
      _readyOrders = localOrders.where((o) => o.status == 'ready').length;

      // Local Top-Selling items
      final dbTopItems = await db.getLocalTopItems();
      _topItems = dbTopItems;
      _topSellingItem = dbTopItems.isNotEmpty ? (dbTopItems.first['item_name'] ?? 'N/A') : 'N/A';

      // Local Category sales
      final dbCategorySales = await db.getLocalCategorySales();
      _categorySales = dbCategorySales;
      
    } catch (e) {
      print('Local dashboard calculation error: $e');
    }
  }
}
