class CartItem {
  final int productId;
  final String name;
  final String manufacturer;
  final String? strength;
  final String? form;
  final double price;
  final double mrp;
  final String? imageUrl;
  final bool requiresPrescription;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.manufacturer,
    this.strength,
    this.form,
    required this.price,
    required this.mrp,
    this.imageUrl,
    required this.requiresPrescription,
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;
  double get totalMrp => mrp * quantity;
  double get savings => totalMrp - totalPrice;

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'manufacturer': manufacturer,
      'strength': strength,
      'form': form,
      'price': price,
      'mrp': mrp,
      'image_url': imageUrl,
      'requires_prescription': requiresPrescription,
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['product_id'] ?? 0,
      name: json['name'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      strength: json['strength'],
      form: json['form'],
      price: _parseDouble(json['price']),
      mrp: _parseDouble(json['mrp']),
      imageUrl: json['image_url'],
      requiresPrescription: json['requires_prescription'] ?? false,
      quantity: json['quantity'] ?? 1,
    );
  }

  // Helper method to safely parse double from various types
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}
