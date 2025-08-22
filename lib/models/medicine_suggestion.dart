class MedicineSuggestion {
  final int productId;
  final String name;
  final String brandName;
  final String genericName;
  final String manufacturer;
  final String category;
  final List<CompositionInfo> compositions;
  final double price;
  final double mrp;
  final bool isPrescriptionRequired;
  final int stockQuantity;
  final String? imageUrl;
  final String matchType;
  final double confidenceScore;

  MedicineSuggestion({
    required this.productId,
    required this.name,
    required this.brandName,
    required this.genericName,
    required this.manufacturer,
    required this.category,
    required this.compositions,
    required this.price,
    required this.mrp,
    required this.isPrescriptionRequired,
    required this.stockQuantity,
    this.imageUrl,
    required this.matchType,
    required this.confidenceScore,
  });

  factory MedicineSuggestion.fromJson(Map<String, dynamic> json) {
    return MedicineSuggestion(
      productId: json['product_id'] ?? 0,
      name: json['name'] ?? '',
      brandName: json['brand_name'] ?? '',
      genericName: json['generic_name'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      category: json['category'] ?? '',
      compositions: (json['compositions'] as List<dynamic>?)
              ?.map((comp) => CompositionInfo.fromJson(comp))
              .toList() ??
          [],
      price: (json['price'] ?? 0).toDouble(),
      mrp: (json['mrp'] ?? 0).toDouble(),
      isPrescriptionRequired: json['is_prescription_required'] ?? false,
      stockQuantity: json['stock_quantity'] ?? 0,
      imageUrl: json['image_url'],
      matchType: json['match_type'] ?? '',
      confidenceScore: (json['confidence_score'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'brand_name': brandName,
      'generic_name': genericName,
      'manufacturer': manufacturer,
      'category': category,
      'compositions': compositions.map((comp) => comp.toJson()).toList(),
      'price': price,
      'mrp': mrp,
      'is_prescription_required': isPrescriptionRequired,
      'stock_quantity': stockQuantity,
      'image_url': imageUrl,
      'match_type': matchType,
      'confidence_score': confidenceScore,
    };
  }
}

class CompositionInfo {
  final String name;
  final String strength;
  final String unit;
  final bool isPrimary;

  CompositionInfo({
    required this.name,
    required this.strength,
    required this.unit,
    required this.isPrimary,
  });

  factory CompositionInfo.fromJson(Map<String, dynamic> json) {
    return CompositionInfo(
      name: json['name'] ?? '',
      strength: json['strength'] ?? '',
      unit: json['unit'] ?? '',
      isPrimary: json['is_primary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'strength': strength,
      'unit': unit,
      'is_primary': isPrimary,
    };
  }

  String get displayText => '$name $strength$unit';
}
