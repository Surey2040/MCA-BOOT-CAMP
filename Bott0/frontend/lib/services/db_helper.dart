import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/menu_item.dart';
import '../models/customer.dart';
import '../models/order.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  // Web in-memory mock database cache
  final List<Category> _webCategories = [];
  final List<MenuItem> _webMenuItems = [];
  final List<Customer> _webCustomers = [];
  final List<Order> _webOrders = [];
  final List<OrderItem> _webOrderItems = [];
  final List<Map<String, dynamic>> _webAdmins = [];

  DbHelper._init() {
    if (kIsWeb) {
      _seedWebData();
    }
  }

  // Seeding Web cache
  void _seedWebData() {
    _webAdmins.addAll([
      {'id': 1, 'name': 'Admin', 'pin': '1234'},
    ]);

    _webCategories.addAll([
      Category(id: 1, name: 'Shawarma', slug: 'shawarma'),
      Category(id: 2, name: 'Lays Shawarma', slug: 'lays-shawarma'),
      Category(id: 3, name: 'Plate Shawarma', slug: 'plate-shawarma'),
      Category(id: 4, name: 'Mug Shawarma', slug: 'mug-shawarma'),
      Category(id: 5, name: 'Special Shawarma', slug: 'special-shawarma'),
    ]);

    _webMenuItems.addAll([
      // Category 1 (Shawarma)
      MenuItem(id: 1, categoryId: 1, name: 'Classic Shawarma', price: 120.0, description: 'Original chicken shawarma with garlic mayonnaise.'),
      MenuItem(id: 2, categoryId: 1, name: 'Spicy Shawarma', price: 130.0, description: 'Chicken shawarma loaded with red hot chilli & jalapenos.'),
      MenuItem(id: 3, categoryId: 1, name: 'Tandoori Shawarma', price: 140.0, description: 'Tandoori chicken wrapped with mint yogurt sauce.'),
      MenuItem(id: 4, categoryId: 1, name: 'Mexican Shawarma', price: 140.0, description: 'Fajita seasoned chicken with bell peppers and salsa.'),

      // Category 2 (Lays Shawarma)
      MenuItem(id: 5, categoryId: 2, name: 'Lays Classic', price: 130.0, description: 'Crispy Classic Lays chips with chicken shawarma.'),
      MenuItem(id: 6, categoryId: 2, name: 'Lays Spanish', price: 140.0, description: 'Sweet and spicy Tomato Lays inside chicken shawarma.'),
      MenuItem(id: 7, categoryId: 2, name: 'Lays Cream & Onion', price: 140.0, description: 'Cream & Onion Lays paired with shredded garlic chicken.'),
      MenuItem(id: 8, categoryId: 2, name: 'Lays Chili Limón', price: 140.0, description: 'Zesty Chili Limón Lays added to chicken shawarma.'),
      MenuItem(id: 9, categoryId: 2, name: 'Lays BBQ', price: 140.0, description: 'Smoky Lays BBQ crunch combined with chicken shawarma.'),

      // Category 3 (Plate Shawarma)
      MenuItem(id: 10, categoryId: 3, name: 'Plate Classic Shawarma', price: 160.0, description: 'Deconstructed chicken shawarma served on a plate.'),
      MenuItem(id: 11, categoryId: 3, name: 'Plate Special Shawarma', price: 180.0, description: 'Plate shawarma with loaded fries and signature dip.'),
      MenuItem(id: 12, categoryId: 3, name: 'Plate Cheese Blast Shawarma', price: 200.0, description: 'Plate shawarma topped with melted Cheddar cheese.'),

      // Category 4 (Mug Shawarma)
      MenuItem(id: 13, categoryId: 4, name: 'Mug Classic', price: 150.0, description: 'Layers of chicken shawarma, fries and dips in a mug.'),
      MenuItem(id: 14, categoryId: 4, name: 'Mug Spicy', price: 160.0, description: 'Layered chicken shawarma with peri peri in a mug.'),
      MenuItem(id: 15, categoryId: 4, name: 'Mug Peri Peri', price: 160.0, description: 'Fiery peri-peri chicken and fries in a mug.'),
      MenuItem(id: 16, categoryId: 4, name: 'Mug BBQ', price: 160.0, description: 'Barbecue chicken shawarma layered with cheese in a mug.'),
      MenuItem(id: 17, categoryId: 4, name: 'Mug Schezwan', price: 160.0, description: 'Spicy Schezwan chicken and fries layered in a mug.'),
      MenuItem(id: 18, categoryId: 4, name: 'Mug Mexican', price: 160.0, description: 'Mexican chicken, salsa and nacho crumbles in a mug.'),

      // Category 5 (Special Shawarma)
      MenuItem(id: 19, categoryId: 5, name: 'Booto Special Shawarma', price: 190.0, description: 'Secret double chicken shawarma loaded with double cheese.'),
      MenuItem(id: 20, categoryId: 5, name: 'Monster Shawarma', price: 220.0, description: 'Triple chicken, fries, cabbage and signature sauces.'),
      MenuItem(id: 21, categoryId: 5, name: 'Cheese Loader Shawarma', price: 210.0, description: 'Mozzarella inside and melted cheese poured on top.'),
    ]);
  }

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite database is not supported on web. Use web fallback methods.');
    }
    if (_database != null) return _database!;
    _database = await _initDB('booto_shawarma.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE admin (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          pin TEXT NOT NULL
        )
      ''');
      await db.execute("INSERT INTO admin (name, pin) VALUES ('Admin', '1234')");
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // 0. admin table
    await db.execute('''
      CREATE TABLE admin (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        pin TEXT NOT NULL
      )
    ''');

    // 1. categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        slug TEXT NOT NULL
      )
    ''');

    // 2. menu_items table
    await db.execute('''
      CREATE TABLE menu_items (
        id INTEGER PRIMARY KEY,
        category_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        description TEXT,
        image_url TEXT,
        is_available INTEGER DEFAULT 1
      )
    ''');

    // 3. customers table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        mobile TEXT UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    // 4. orders table
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        customer_id INTEGER,
        customer_name TEXT,
        customer_mobile TEXT,
        order_number TEXT,
        order_type TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL DEFAULT 0.0,
        total REAL NOT NULL,
        status TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // 5. order_items table
    await db.execute('''
      CREATE TABLE order_items (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        menu_item_id INTEGER NOT NULL,
        item_name TEXT,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        extras TEXT DEFAULT '[]',
        special_instructions TEXT,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');

    // Seed SQLite Data
    final batch = db.batch();
    
    // Seed Admin
    batch.execute("INSERT INTO admin (name, pin) VALUES ('Admin', '1234')");
    
    // Seed Categories
    batch.execute("INSERT INTO categories (id, name, slug) VALUES (1, 'Shawarma', 'shawarma')");
    batch.execute("INSERT INTO categories (id, name, slug) VALUES (2, 'Lays Shawarma', 'lays-shawarma')");
    batch.execute("INSERT INTO categories (id, name, slug) VALUES (3, 'Plate Shawarma', 'plate-shawarma')");
    batch.execute("INSERT INTO categories (id, name, slug) VALUES (4, 'Mug Shawarma', 'mug-shawarma')");
    batch.execute("INSERT INTO categories (id, name, slug) VALUES (5, 'Special Shawarma', 'special-shawarma')");

    // Seed Menu Items
    // Category 1
    batch.execute("INSERT INTO menu_items (id, category_id, name, price, description, is_available) VALUES (1, 1, 'Classic Shawarma', 120.0, 'Original chicken shawarma with garlic mayonnaise.', 1)");
    batch.execute("INSERT INTO menu_items (id, category_id, name, price, description, is_available) VALUES (2, 1, 'Spicy Shawarma', 130.0, 'Chicken shawarma loaded with red hot chilli & jalapenos.', 1)");
    batch.execute("INSERT INTO menu_items (id, category_id, name, price, description, is_available) VALUES (3, 1, 'Tandoori Shawarma', 140.0, 'Tandoori chicken wrapped with mint yogurt sauce.', 1)");
    batch.execute("INSERT INTO menu_items (id, category_id, name, price, description, is_available) VALUES (4, 1, 'Mexican Shawarma', 140.0, 'Fajita seasoned chicken with bell peppers and salsa.', 1)");

    // Category 2
    batch.execute("INSERT INTO menu_items (id, category_id, name, price, description, is_available) VALUES (5, 2, 'Lays Classic', 130.0, 'Crispy Classic Lays chips with chicken shawarma.', 1)");
    batch.execute("INSERT INTO menu_items (id, category_id, name, price, description, is_available) VALUES (6, 2, 'Lays Spanish', 140.0, 'Sweet and spicy Tomato Lays inside chicken shawarma.', 1)");
    batch.execute("INSERT INTO menu_items (id, category_id, name, price, description, is_available) VALUES (7, 2, 'Lays Cream & Onion', 140.0, 'Cream & Onion Lays paired with shredded garlic chicken.', 1)");
    batch.execute("INSERT INTO menu_items (id, category_id, name, price, description, is_available) VALUES (8, 2, 'Lays Chili Limón', 140.0, 'Zesty Chili Limón Lays added to chicken shawarma.', 1)");
    batch.execute("INSERT INTO menu_items (id, category_id, name, price, description, is_available) VALUES (9, 2, 'Lays BBQ', 140.0, 'Smoky Lays BBQ crunch combined with chicken shawarma.', 1)");

    // Category 3
    batch.execute("INSERT INTO menu_items (id, category_id, name, price, description, is_available) VALUES (10, 3, 'Plate Classic Shawarma', 160.0, 'Deconstructed chicken shawarma served on a plate.', 1)");
    batch.execute("INSERT INTO menu_items (id, category_id, name, price, description, is_available) VALUES (11, 3, 'Plate Special Shawarma', 180.0, 'Plate shawarma with loaded fries and signature dip.', 1)");
    batch.execute("INSERT INTO menu_items (id, category_id, name, price, description, is_available) VALUES (12, 3, 'Plate Cheese Blast Shawarma', 200.0, 'Plate shawarma topped with melted Cheddar cheese.', 1)");

    // Category 4
    batch.execute("INSERT INTO menu_items (id, category_id, name, price, description, is_available) VALUES (13, 4, 'Mug Classic', 150.0, 'Layers of chicken shawarma, fries and dips in a mug.', 1)");
    batch.execute("INSERT INTO menu_items (id, category_id, name, price, description, is_available) VALUES (14, 4, 'Mug Spicy', 160.0, 'Layered chicken shawarma with peri peri in a mug.', 1)");
    batch.execute("INSERT INTO menu_items (id, category_id, name, price, description, is_available) VALUES (15, 4, 'Mug Peri Peri', 160.0, 'Fiery peri-peri chicken and fries in a mug.', 1)");
    batch.execute("INSERT INTO menu_items (id, category_id, name, price, description, is_available) VALUES (16, 4, 'Mug BBQ', 160.0, 'Barbecue chicken shawarma layered with cheese in a mug.', 1)");
    batch.execute("INSERT INTO menu_items (id, category_id, name, price, description, is_available) VALUES (17, 4, 'Mug Schezwan', 160.0, 'Spicy Schezwan chicken and fries layered in a mug.', 1)");
    batch.execute("INSERT INTO menu_items (id, category_id, name, price, description, is_available) VALUES (18, 4, 'Mug Mexican', 160.0, 'Mexican chicken, salsa and nacho crumbles in a mug.', 1)");

    // Category 5
    batch.execute("INSERT INTO menu_items (id, category_id, name, price, description, is_available) VALUES (19, 5, 'Booto Special Shawarma', 190.0, 'Secret double chicken shawarma loaded with double cheese.', 1)");
    batch.execute("INSERT INTO menu_items (id, category_id, name, price, description, is_available) VALUES (20, 5, 'Monster Shawarma', 220.0, 'Triple chicken, fries, cabbage and signature sauces.', 1)");
    batch.execute("INSERT INTO menu_items (id, category_id, name, price, description, is_available) VALUES (21, 5, 'Cheese Loader Shawarma', 210.0, 'Mozzarella inside and melted cheese poured on top.', 1)");

    await batch.commit(noResult: true);
  }

  // --- Category Operations ---
  Future<void> saveCategories(List<Category> categories) async {
    if (kIsWeb) {
      _webCategories.clear();
      _webCategories.addAll(categories);
      return;
    }
    final db = await instance.database;
    final batch = db.batch();
    
    batch.delete('categories');
    for (var cat in categories) {
      batch.insert('categories', cat.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<Category>> getCategories() async {
    if (kIsWeb) {
      return List.from(_webCategories);
    }
    final db = await instance.database;
    final maps = await db.query('categories', orderBy: 'id ASC');
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  // --- Menu Item Operations ---
  Future<void> saveMenuItems(List<MenuItem> items) async {
    if (kIsWeb) {
      _webMenuItems.clear();
      _webMenuItems.addAll(items);
      return;
    }
    final db = await instance.database;
    final batch = db.batch();
    
    batch.delete('menu_items');
    for (var item in items) {
      batch.insert('menu_items', item.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<MenuItem>> getMenuItems() async {
    if (kIsWeb) {
      return List.from(_webMenuItems);
    }
    final db = await instance.database;
    final maps = await db.query('menu_items', orderBy: 'name ASC');
    return maps.map((map) => MenuItem.fromMap(map)).toList();
  }

  Future<List<MenuItem>> getMenuItemsByCategory(int categoryId) async {
    if (kIsWeb) {
      return _webMenuItems.where((item) => item.categoryId == categoryId).toList();
    }
    final db = await instance.database;
    final maps = await db.query(
      'menu_items',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'name ASC',
    );
    return maps.map((map) => MenuItem.fromMap(map)).toList();
  }

  // --- Customer Operations ---
  Future<Customer> getOrCreateCustomer(String name, String? mobile) async {
    if (kIsWeb) {
      if (mobile != null && mobile.isNotEmpty) {
        final matches = _webCustomers.where((c) => c.mobile == mobile);
        if (matches.isNotEmpty) return matches.first;
      }
      final newCust = Customer(id: _webCustomers.length + 1, name: name, mobile: mobile, createdAt: DateTime.now());
      _webCustomers.add(newCust);
      return newCust;
    }
    final db = await instance.database;
    
    if (mobile != null && mobile.isNotEmpty) {
      final maps = await db.query(
        'customers',
        where: 'mobile = ?',
        whereArgs: [mobile],
      );
      if (maps.isNotEmpty) {
        return Customer.fromMap(maps.first);
      }
    }

    final id = await db.insert('customers', {
      'name': name,
      'mobile': mobile,
      'created_at': DateTime.now().toIso8601String(),
    });
    return Customer(id: id, name: name, mobile: mobile);
  }

  Future<List<Customer>> getCustomers() async {
    if (kIsWeb) {
      return List.from(_webCustomers);
    }
    final db = await instance.database;
    final maps = await db.query('customers', orderBy: 'name ASC');
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  // --- Order Operations ---
  Future<void> insertOrder(Order order) async {
    if (kIsWeb) {
      _webOrders.removeWhere((o) => o.id == order.id);
      _webOrders.add(order);
      _webOrderItems.addAll(order.items);
      return;
    }
    final db = await instance.database;
    
    await db.transaction((txn) async {
      await txn.insert('orders', order.toMap());
      for (var item in order.items) {
        await txn.insert('order_items', item.toMap());
      }
    });
  }

  Future<List<Order>> getOrders({String? status}) async {
    if (kIsWeb) {
      var list = List<Order>.from(_webOrders);
      if (status != null) {
        list = list.where((o) => o.status == status).toList();
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }
    
    final db = await instance.database;
    String? whereClause;
    List<dynamic>? whereArgs;
    
    if (status != null) {
      whereClause = 'status = ?';
      whereArgs = [status];
    }

    final orderMaps = await db.query(
      'orders',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    final orders = <Order>[];

    for (var map in orderMaps) {
      final orderId = map['id'] as String;
      
      final itemMaps = await db.rawQuery('''
        SELECT oi.*, mi.name as item_name 
        FROM order_items oi
        LEFT JOIN menu_items mi ON oi.menu_item_id = mi.id
        WHERE oi.order_id = ?
      ''', [orderId]);

      final items = itemMaps.map((itemMap) => OrderItem.fromMap(itemMap)).toList();
      
      orders.add(Order(
        id: orderId,
        customerId: map['customer_id'] as int?,
        customerName: map['customer_name'] as String?,
        customerMobile: map['customer_mobile'] as String?,
        orderNumber: map['order_number'] as String?,
        orderType: map['order_type'] as String,
        subtotal: (map['subtotal'] as num).toDouble(),
        discount: (map['discount'] as num? ?? 0.0).toDouble(),
        total: (map['total'] as num).toDouble(),
        status: map['status'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        synced: map['synced'] == 1,
        items: items,
      ));
    }

    return orders;
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    if (kIsWeb) {
      final index = _webOrders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _webOrders[index] = _webOrders[index].copyWith(status: status, synced: false);
      }
      return;
    }
    final db = await instance.database;
    await db.update(
      'orders',
      {
        'status': status,
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // --- Synchronization Queries ---
  Future<List<Order>> getUnsyncedOrders() async {
    if (kIsWeb) {
      return _webOrders.where((o) => !o.synced).toList();
    }
    final db = await instance.database;
    
    final orderMaps = await db.query(
      'orders',
      where: 'synced = ?',
      whereArgs: [0],
    );

    final orders = <Order>[];

    for (var map in orderMaps) {
      final orderId = map['id'] as String;
      final itemMaps = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );
      final items = itemMaps.map((itemMap) => OrderItem.fromMap(itemMap)).toList();

      orders.add(Order(
        id: orderId,
        customerId: map['customer_id'] as int?,
        customerName: map['customer_name'] as String?,
        customerMobile: map['customer_mobile'] as String?,
        orderNumber: map['order_number'] as String?,
        orderType: map['order_type'] as String,
        subtotal: (map['subtotal'] as num).toDouble(),
        discount: (map['discount'] as num? ?? 0.0).toDouble(),
        total: (map['total'] as num).toDouble(),
        status: map['status'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        synced: false,
        items: items,
      ));
    }

    return orders;
  }

  Future<void> markOrdersAsSynced(List<String> orderIds) async {
    if (orderIds.isEmpty) return;
    if (kIsWeb) {
      for (var id in orderIds) {
        final index = _webOrders.indexWhere((o) => o.id == id);
        if (index != -1) {
          _webOrders[index] = _webOrders[index].copyWith(synced: true);
        }
      }
      return;
    }
    
    final db = await instance.database;
    final batch = db.batch();
    for (var id in orderIds) {
      batch.update(
        'orders',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }

  // Reset Daily Sales Locally
  Future<void> resetDailySalesLocally() async {
    if (kIsWeb) {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      _webOrders.removeWhere((o) => o.createdAt.toIso8601String().startsWith(todayStr));
      return;
    }
    final db = await instance.database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    
    await db.transaction((txn) async {
      await txn.delete(
        'order_items',
        where: 'order_id IN (SELECT id FROM orders WHERE created_at LIKE ?)',
        whereArgs: ['$todayStr%'],
      );
      await txn.delete(
        'orders',
        where: 'created_at LIKE ?',
        whereArgs: ['$todayStr%'],
      );
    });
  }

  // --- Admin Operations ---
  Future<Map<String, dynamic>?> authenticateAdmin(String pin) async {
    if (kIsWeb) {
      final matches = _webAdmins.where((a) => a['pin'] == pin);
      if (matches.isNotEmpty) return matches.first;
      return null;
    }
    final db = await instance.database;
    final maps = await db.query(
      'admin',
      where: 'pin = ?',
      whereArgs: [pin],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // --- Dashboard Local Queries ---
  Future<List<Map<String, dynamic>>> getLocalCategorySales() async {
    if (kIsWeb) {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final todayOrders = _webOrders.where((o) => o.createdAt.toIso8601String().startsWith(todayStr) && o.status != 'cancelled');
      final catSales = <String, double>{};
      for (var o in todayOrders) {
        for (var item in o.items) {
          final miMatches = _webMenuItems.where((mi) => mi.id == item.menuItemId);
          if (miMatches.isNotEmpty) {
            final categoryId = miMatches.first.categoryId;
            final catMatches = _webCategories.where((c) => c.id == categoryId);
            if (catMatches.isNotEmpty) {
              final catName = catMatches.first.name;
              catSales[catName] = (catSales[catName] ?? 0.0) + (item.quantity * item.price);
            }
          }
        }
      }
      return catSales.entries.map((e) => {'category_name': e.key, 'revenue': e.value}).toList();
    }

    final db = await instance.database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    
    final results = await db.rawQuery('''
      SELECT 
        c.name as category_name,
        SUM(oi.quantity) as quantity_sold,
        SUM(oi.quantity * oi.price) as revenue
      FROM order_items oi
      JOIN menu_items mi ON oi.menu_item_id = mi.id
      JOIN categories c ON mi.category_id = c.id
      JOIN orders o ON oi.order_id = o.id
      WHERE o.created_at LIKE ? AND o.status != 'cancelled'
      GROUP BY c.name
      ORDER BY revenue DESC
    ''', ['$todayStr%']);

    return results;
  }

  Future<List<Map<String, dynamic>>> getLocalTopItems() async {
    if (kIsWeb) {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final todayOrders = _webOrders.where((o) => o.createdAt.toIso8601String().startsWith(todayStr) && o.status != 'cancelled');
      final itemCounts = <String, int>{};
      final itemRevenues = <String, double>{};
      for (var o in todayOrders) {
        for (var item in o.items) {
          final name = item.itemName ?? 'Unknown Item';
          itemCounts[name] = (itemCounts[name] ?? 0) + item.quantity;
          itemRevenues[name] = (itemRevenues[name] ?? 0.0) + (item.quantity * item.price);
        }
      }
      final list = itemCounts.entries.map((e) => {
        'item_name': e.key,
        'quantity_sold': e.value,
        'revenue': itemRevenues[e.key] ?? 0.0
      }).toList();
      list.sort((a, b) => (b['quantity_sold'] as int).compareTo(a['quantity_sold'] as int));
      return list.take(5).toList();
    }

    final db = await instance.database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    final results = await db.rawQuery('''
      SELECT 
        mi.name as item_name,
        SUM(oi.quantity) as quantity_sold,
        SUM(oi.quantity * oi.price) as revenue
      FROM order_items oi
      JOIN menu_items mi ON oi.menu_item_id = mi.id
      JOIN orders o ON oi.order_id = o.id
      WHERE o.created_at LIKE ? AND o.status != 'cancelled'
      GROUP BY mi.name
      ORDER BY quantity_sold DESC, revenue DESC
      LIMIT 5
    ''', ['$todayStr%']);

    return results;
  }

  // Wipe database tables
  Future<void> wipeAllTables() async {
    if (kIsWeb) {
      _webCategories.clear();
      _webMenuItems.clear();
      _webCustomers.clear();
      _webOrders.clear();
      _webOrderItems.clear();
      _webAdmins.clear();
      _webAdmins.add({'id': 1, 'name': 'Admin', 'pin': '1234'});
      return;
    }
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('order_items');
      await txn.delete('orders');
      await txn.delete('menu_items');
      await txn.delete('categories');
      await txn.delete('customers');
      await txn.delete('admin');
      await txn.insert('admin', {'name': 'Admin', 'pin': '1234'});
    });
  }
}
