import 'nutrition.dart';

class FoodItem {
  FoodItem({
    this.id,
    required this.name,
    required this.category,
    required this.quantityLabel,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.barcode,
    this.brand,
    this.expiryDate,
    this.imageUrl,
    this.nutrition = const Nutrition(),
    this.isInInventory = true,
  });

  final int? id;
  final String name;
  final String category;
  final String quantityLabel;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? barcode;
  final String? brand;
  final String? expiryDate;
  final String? imageUrl;
  final Nutrition nutrition;
  final bool isInInventory;

  int get stockCount {
    final match = RegExp(
      r'^\s*(\d+)\s*x\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(quantityLabel);
    if (match == null) {
      final plainCount = int.tryParse(quantityLabel.trim());
      return plainCount == null || plainCount < 1 ? 1 : plainCount;
    }
    return int.tryParse(match.group(1) ?? '') ?? 1;
  }

  String get packageDetail {
    if (int.tryParse(quantityLabel.trim()) != null) {
      return 'item';
    }
    final match = RegExp(
      r'^\s*\d+\s*x\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(quantityLabel);
    final value = match?.group(1)?.trim() ?? quantityLabel.trim();
    if (value.isEmpty || value == 'Quantity not provided') {
      return 'Item detail not set';
    }
    return value;
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? 'Unknown item',
      category: (map['category'] as String?) ?? 'Uncategorized',
      quantityLabel: (map['quantity_label'] as String?) ?? 'Not specified',
      source: (map['source'] as String?) ?? 'manual',
      createdAt:
          DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse((map['updated_at'] as String?) ?? '') ??
          DateTime.now(),
      barcode: map['barcode'] as String?,
      brand: map['brand'] as String?,
      expiryDate: map['expiry_date'] as String?,
      imageUrl: map['image_url'] as String?,
      nutrition: Nutrition.fromMap(map),
      isInInventory: (map['is_in_inventory'] as int? ?? 1) == 1,
    );
  }

  factory FoodItem.fromOpenFoodFacts({
    required String barcode,
    required Map<String, dynamic> product,
  }) {
    return FoodItem(
      name:
          _readString(product['product_name']) ??
          _readString(product['generic_name']) ??
          'Unknown item',
      barcode: barcode,
      brand: _readString(product['brands']),
      category: _resolveCategory(product),
      quantityLabel:
          _readString(product['quantity']) ?? 'Quantity not provided',
      expiryDate: null,
      imageUrl:
          _readString(product['image_front_url']) ??
          _readString(product['image_url']),
      nutrition: Nutrition.fromOpenFoodFacts(
        product['nutriments'] as Map<String, dynamic>?,
      ),
      isInInventory: true,
      source: 'open_food_facts',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  FoodItem copyWith({
    int? id,
    String? name,
    String? category,
    String? quantityLabel,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? barcode,
    String? brand,
    String? expiryDate,
    String? imageUrl,
    Nutrition? nutrition,
    bool? isInInventory,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantityLabel: quantityLabel ?? this.quantityLabel,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      barcode: barcode ?? this.barcode,
      brand: brand ?? this.brand,
      expiryDate: expiryDate ?? this.expiryDate,
      imageUrl: imageUrl ?? this.imageUrl,
      nutrition: nutrition ?? this.nutrition,
      isInInventory: isInInventory ?? this.isInInventory,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'brand': brand,
      'category': category,
      'quantity_label': quantityLabel,
      'expiry_date': expiryDate,
      'image_url': imageUrl,
      'calories': nutrition.calories,
      'protein': nutrition.protein,
      'carbs': nutrition.carbs,
      'fat': nutrition.fat,
      'is_in_inventory': isInInventory ? 1 : 0,
      'source': source,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static String _resolveCategory(Map<String, dynamic> product) {
    final categories = _readString(product['categories']);
    if (categories != null && categories.isNotEmpty) {
      return categories.split(',').first.trim();
    }

    final tags = product['categories_tags'];
    if (tags is List && tags.isNotEmpty) {
      return tags.first.toString().replaceAll('en:', '').trim();
    }

    return 'Uncategorized';
  }

  static String? _readString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}
