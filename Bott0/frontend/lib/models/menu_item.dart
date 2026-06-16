class MenuItem {
  final int id;
  final int categoryId;
  final String name;
  final double price;
  final String description;
  final String? imageUrl;
  final bool isAvailable;

  MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.description,
    this.imageUrl,
    this.isAvailable = true,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      categoryId: json['category_id'] is String ? int.parse(json['category_id']) : json['category_id'] as int,
      name: json['name'] as String,
      price: json['price'] is String ? double.parse(json['price']) : (json['price'] as num).toDouble(),
      description: (json['description'] as String?) ?? '',
      imageUrl: json['image_url'] as String?,
      isAvailable: json['is_available'] is int 
          ? (json['is_available'] == 1) 
          : (json['is_available'] as bool? ?? true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'price': price,
      'description': description,
      'image_url': imageUrl,
      'is_available': isAvailable ? 1 : 0,
    };
  }

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'] as int,
      categoryId: map['category_id'] as int,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      description: (map['description'] as String?) ?? '',
      imageUrl: map['image_url'] as String?,
      isAvailable: map['is_available'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'price': price,
      'description': description,
      'image_url': imageUrl,
      'is_available': isAvailable ? 1 : 0,
    };
  }
}
