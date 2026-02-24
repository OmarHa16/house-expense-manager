class Item {
  final int id;
  final String name;
  final double? defaultPrice;
  final String? category;
  final DateTime? createdAt;

  Item({
    required this.id,
    required this.name,
    this.defaultPrice,
    this.category,
    this.createdAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      name: json['name'],
      defaultPrice: json['default_price'] != null 
          ? (json['default_price'] as num).toDouble() 
          : null,
      category: json['category'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'default_price': defaultPrice,
      'category': category,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Item copyWith({
    int? id,
    String? name,
    double? defaultPrice,
    String? category,
    DateTime? createdAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultPrice: defaultPrice ?? this.defaultPrice,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => name;
}
