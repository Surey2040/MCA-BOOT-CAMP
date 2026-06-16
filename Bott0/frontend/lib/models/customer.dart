class Customer {
  final int? id;
  final String name;
  final String? mobile;
  final DateTime? createdAt;

  Customer({
    this.id,
    required this.name,
    this.mobile,
    this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int?,
      name: json['name'] as String,
      mobile: json['mobile'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (mobile != null) 'mobile': mobile,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      mobile: map['mobile'] as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'mobile': mobile,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }
}
