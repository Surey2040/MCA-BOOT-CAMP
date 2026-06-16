import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/category.dart';
import '../models/menu_item.dart';
import '../services/db_helper.dart';
import '../services/sync_service.dart';

class MenuProvider extends ChangeNotifier {
  List<Category> _categories = [];
  List<MenuItem> _menuItems = [];
  bool _isLoading = false;
  int? _selectedCategoryId;

  List<Category> get categories => _categories;
  List<MenuItem> get menuItems => _menuItems;
  bool get isLoading => _isLoading;
  int? get selectedCategoryId => _selectedCategoryId;

  // Filtered menu items based on the active category tab
  List<MenuItem> get filteredItems {
    if (_selectedCategoryId == null) return _menuItems;
    return _menuItems.where((item) => item.categoryId == _selectedCategoryId && item.isAvailable).toList();
  }

  void selectCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  // Load menu locally from SQLite database
  Future<void> loadMenuLocal() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = DbHelper.instance;
      _categories = await db.getCategories();
      _menuItems = await db.getMenuItems();

      if (_categories.isNotEmpty && _selectedCategoryId == null) {
        _selectedCategoryId = _categories.first.id;
      }
    } catch (e) {
      print('Failed to load menu from local DB: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Fetch online updates and sync to SQLite
  Future<bool> refreshMenu() async {
    _isLoading = true;
    notifyListeners();

    // Trigger standard sync service which fetches the remote menu and saves to SQLite
    final success = await SyncService.synchronize();
    
    // Reload local files regardless
    await loadMenuLocal();
    
    _isLoading = false;
    notifyListeners();
    return success;
  }

  // Admin menu creation (saves locally and synchronizes)
  Future<bool> addMenuItem(String name, double price, String description, int categoryId) async {
    try {
      final db = DbHelper.instance;
      final isOnline = await SyncService.isServerOnline();
      
      // Temporary or sequential ID
      final tempId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      final newItem = MenuItem(
        id: tempId,
        categoryId: categoryId,
        name: name,
        price: price,
        description: description,
        isAvailable: true,
      );

      // Save locally
      _menuItems.add(newItem);
      await db.saveMenuItems(_menuItems);

      if (isOnline) {
        final baseUrl = await SyncService.getBaseUrl();
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');

        final response = await http.post(
          Uri.parse('$baseUrl/menu'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'category_id': categoryId,
            'name': name,
            'price': price,
            'description': description,
          }),
        );

        if (response.statusCode == 201) {
          // Re-sync to get correct server ID
          await refreshMenu();
          return true;
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding menu item: $e');
    }
    return false;
  }

  // Update item details
  Future<bool> updateMenuItem(int id, String name, double price, String description, int categoryId, bool isAvailable) async {
    try {
      final db = DbHelper.instance;
      final isOnline = await SyncService.isServerOnline();

      // Update in local lists
      final index = _menuItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _menuItems[index] = MenuItem(
          id: id,
          categoryId: categoryId,
          name: name,
          price: price,
          description: description,
          isAvailable: isAvailable,
        );
        await db.saveMenuItems(_menuItems);
      }

      if (isOnline) {
        final baseUrl = await SyncService.getBaseUrl();
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');

        final response = await http.put(
          Uri.parse('$baseUrl/menu/$id'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'category_id': categoryId,
            'name': name,
            'price': price,
            'description': description,
            'is_available': isAvailable,
          }),
        );

        if (response.statusCode == 200) {
          await refreshMenu();
          return true;
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating menu item: $e');
    }
    return false;
  }

  // Delete menu item
  Future<bool> deleteMenuItem(int id) async {
    try {
      final db = DbHelper.instance;
      final isOnline = await SyncService.isServerOnline();

      _menuItems.removeWhere((item) => item.id == id);
      await db.saveMenuItems(_menuItems);

      if (isOnline) {
        final baseUrl = await SyncService.getBaseUrl();
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');

        final response = await http.delete(
          Uri.parse('$baseUrl/menu/$id'),
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          await refreshMenu();
          return true;
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting menu item: $e');
    }
    return false;
  }
}
