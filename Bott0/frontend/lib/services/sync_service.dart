import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'db_helper.dart';
import '../models/category.dart';
import '../models/menu_item.dart';

class SyncService {
  static const String defaultApiUrl = 'http://10.0.2.2:5001/api'; // Android Emulator default host mapping

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_url') ?? defaultApiUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_url', url);
  }

  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Check backend server connection
  static Future<bool> isServerOnline() async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['status'] == 'healthy';
      }
    } catch (_) {}
    return false;
  }

  // Main Sync Operation: SQLite -> PostgreSQL & PostgreSQL -> SQLite
  static Future<bool> synchronize() async {
    try {
      final db = DbHelper.instance;
      
      // 1. Fetch unsynced local orders
      final unsyncedOrders = await db.getUnsyncedOrders();
      
      // Separate orders list and order items list for the REST payload
      final List<Map<String, dynamic>> ordersJson = [];
      final List<Map<String, dynamic>> itemsJson = [];

      for (var order in unsyncedOrders) {
        ordersJson.add(order.toMap());
        for (var item in order.items) {
          itemsJson.add(item.toMap());
        }
      }

      // 2. Send payload to Backend `/api/sync`
      final baseUrl = await getBaseUrl();
      final token = await _getAuthToken();

      final response = await http.post(
        Uri.parse('$baseUrl/sync'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'orders': ordersJson,
          'order_items': itemsJson,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          // A. Mark local orders as synced in SQLite
          final List<dynamic> syncedIds = result['synced_order_ids'];
          final List<String> orderIdsToMark = syncedIds.map((e) => e.toString()).toList();
          await db.markOrdersAsSynced(orderIdsToMark);

          // B. Sync categories down to SQLite
          final List<dynamic> catList = result['categories'];
          final categories = catList.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
          await db.saveCategories(categories);

          // C. Sync menu items down to SQLite
          final List<dynamic> itemList = result['menu_items'];
          final menuItems = itemList.map((e) => MenuItem.fromJson(e as Map<String, dynamic>)).toList();
          await db.saveMenuItems(menuItems);

          print('Synchronization completed successfully: Synced ${orderIdsToMark.length} orders.');
          return true;
        }
      }
    } catch (e) {
      print('Sync failure details: $e');
    }
    return false;
  }
}
