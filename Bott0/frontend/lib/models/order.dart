import 'dart:convert';

class ExtraItem {
  final String name;
  final double price;

  ExtraItem({
    required this.name,
    required this.price,
  });

  factory ExtraItem.fromJson(Map<String, dynamic> json) {
    return ExtraItem(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
  };
}

class OrderItem {
  final String id;
  final String orderId;
  final int menuItemId;
  final String? itemName;
  final int quantity;
  final double price; // price per unit (base + extras)
  final List<ExtraItem> extras;
  final String specialInstructions;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    this.itemName,
    required this.quantity,
    required this.price,
    this.extras = const [],
    this.specialInstructions = '',
  });

  // Calculate total price of item (quantity * unit price)
  double get total => quantity * price;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    var extList = <ExtraItem>[];
    if (json['extras'] != null) {
      final parsed = json['extras'] is String 
          ? jsonDecode(json['extras'] as String) 
          : json['extras'];
      if (parsed is List) {
        extList = parsed.map((e) => ExtraItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    }

    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      menuItemId: json['menu_item_id'] is String ? int.parse(json['menu_item_id']) : json['menu_item_id'] as int,
      itemName: json['item_name'] as String?,
      quantity: json['quantity'] is String ? int.parse(json['quantity']) : json['quantity'] as int,
      price: json['price'] is String ? double.parse(json['price']) : (json['price'] as num).toDouble(),
      extras: extList,
      specialInstructions: (json['special_instructions'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'menu_item_id': menuItemId,
      'quantity': quantity,
      'price': price,
      'extras': extras.map((e) => e.toJson()).toList(),
      'special_instructions': specialInstructions,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    var extList = <ExtraItem>[];
    if (map['extras'] != null && (map['extras'] as String).isNotEmpty) {
      final parsed = jsonDecode(map['extras'] as String);
      if (parsed is List) {
        extList = parsed.map((e) => ExtraItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    }

    return OrderItem(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      menuItemId: map['menu_item_id'] as int,
      itemName: map['item_name'] as String?,
      quantity: map['quantity'] as int,
      price: (map['price'] as num).toDouble(),
      extras: extList,
      specialInstructions: (map['special_instructions'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'menu_item_id': menuItemId,
      'quantity': quantity,
      'price': price,
      'extras': jsonEncode(extras.map((e) => e.toJson()).toList()),
      'special_instructions': specialInstructions,
    };
  }
}

class Order {
  final String id;
  final int? customerId;
  final String? customerName;
  final String? customerMobile;
  final String? orderNumber;
  final String orderType; // 'Dine In' or 'Take Away'
  final double subtotal;
  final double discount;
  final double total;
  final String status; // 'pending', 'ready', 'completed', 'cancelled'
  final DateTime createdAt;
  final bool synced;
  final List<OrderItem> items;

  Order({
    required this.id,
    this.customerId,
    this.customerName,
    this.customerMobile,
    this.orderNumber,
    required this.orderType,
    required this.subtotal,
    this.discount = 0.0,
    required this.total,
    required this.status,
    required this.createdAt,
    this.synced = false,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsList = <OrderItem>[];
    if (json['items'] != null) {
      final parsed = json['items'] as List;
      itemsList = parsed.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList();
    }

    return Order(
      id: json['id'] as String,
      customerId: json['customer_id'] is String ? int.parse(json['customer_id']) : json['customer_id'] as int?,
      customerName: json['customer_name'] as String?,
      customerMobile: json['customer_mobile'] as String?,
      orderNumber: json['order_number'] as String?,
      orderType: (json['order_type'] as String?) ?? 'Dine In',
      subtotal: json['subtotal'] is String ? double.parse(json['subtotal']) : (json['subtotal'] as num).toDouble(),
      discount: json['discount'] is String ? double.parse(json['discount']) : (json['discount'] as num? ?? 0.0).toDouble(),
      total: json['total'] is String ? double.parse(json['total']) : (json['total'] as num).toDouble(),
      status: (json['status'] as String?) ?? 'pending',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      synced: json['synced'] == 1 || (json['synced'] as bool? ?? true),
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (customerId != null) 'customer_id': customerId,
      'customer_name': customerName,
      'customer_mobile': customerMobile,
      if (orderNumber != null) 'order_number': orderNumber,
      'order_type': orderType,
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'synced': synced ? 1 : 0,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as String,
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String?,
      customerMobile: map['customer_mobile'] as String?,
      orderNumber: map['order_number'] as String?,
      orderType: (map['order_type'] as String?) ?? 'Dine In',
      subtotal: (map['subtotal'] as num).toDouble(),
      discount: (map['discount'] as num? ?? 0.0).toDouble(),
      total: (map['total'] as num).toDouble(),
      status: (map['status'] as String?) ?? 'pending',
      createdAt: DateTime.parse(map['created_at'] as String),
      synced: map['synced'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_mobile': customerMobile,
      'order_number': orderNumber,
      'order_type': orderType,
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  // Helper copyWith method
  Order copyWith({
    String? id,
    int? customerId,
    String? customerName,
    String? customerMobile,
    String? orderNumber,
    String? orderType,
    double? subtotal,
    double? discount,
    double? total,
    String? status,
    DateTime? createdAt,
    bool? synced,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerMobile: customerMobile ?? this.customerMobile,
      orderNumber: orderNumber ?? this.orderNumber,
      orderType: orderType ?? this.orderType,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
      items: items ?? this.items,
    );
  }
}
