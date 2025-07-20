// Cart Models for Flutter Pharmacy App

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
      price: CartItem._parseDouble(json['price']),
      mrp: CartItem._parseDouble(json['mrp']),
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

class Cart {
  final List<CartItem> items;
  final String? couponCode;
  final double couponDiscount;
  final double shippingFee;
  final double taxRate;

  Cart({
    this.items = const [],
    this.couponCode,
    this.couponDiscount = 0.0,
    this.shippingFee = 50.0,
    this.taxRate = 0.18, // 18% GST
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get totalMrp => items.fold(0.0, (sum, item) => sum + item.totalMrp);
  double get productSavings => totalMrp - subtotal;
  double get couponSavings => couponDiscount;
  double get totalSavings => productSavings + couponSavings;
  double get taxAmount => (subtotal - couponDiscount) * taxRate;
  double get finalShipping => subtotal >= 500 ? 0.0 : shippingFee; // Free shipping above ₹500
  double get total => subtotal - couponDiscount + taxAmount + finalShipping;
  
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  bool get hasRxItems => items.any((item) => item.requiresPrescription);

  Cart copyWith({
    List<CartItem>? items,
    String? couponCode,
    double? couponDiscount,
    double? shippingFee,
    double? taxRate,
  }) {
    return Cart(
      items: items ?? this.items,
      couponCode: couponCode ?? this.couponCode,
      couponDiscount: couponDiscount ?? this.couponDiscount,
      shippingFee: shippingFee ?? this.shippingFee,
      taxRate: taxRate ?? this.taxRate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'coupon_code': couponCode,
      'coupon_discount': couponDiscount,
      'shipping_fee': shippingFee,
      'tax_rate': taxRate,
    };
  }
}

class CouponResponse {
  final bool isValid;
  final String message;
  final double discountAmount;
  final double discountPercentage;
  final String? couponCode;

  CouponResponse({
    required this.isValid,
    required this.message,
    this.discountAmount = 0.0,
    this.discountPercentage = 0.0,
    this.couponCode,
  });

  factory CouponResponse.fromJson(Map<String, dynamic> json) {
    return CouponResponse(
      isValid: json['is_valid'] ?? false,
      message: json['message'] ?? '',
      discountAmount: CouponResponse._parseDouble(json['discount_amount']),
      discountPercentage: CouponResponse._parseDouble(json['discount_percentage']),
      couponCode: json['coupon_code'],
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

class OrderRequest {
  final List<CartItem> items;
  final String? couponCode;
  final double total;
  final String? deliveryAddress;
  final String? notes;

  OrderRequest({
    required this.items,
    this.couponCode,
    required this.total,
    this.deliveryAddress,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => {
        'product_id': item.productId,
        'quantity': item.quantity,
        'price': item.price,
      }).toList(),
      'coupon_code': couponCode,
      'total_amount': total,
      'delivery_address': deliveryAddress,
      'notes': notes,
    };
  }
}
