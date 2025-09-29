// Cart Models for Flutter Pharmacy App
import 'cart_item.dart';

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
    this.shippingFee = 0.0,
    this.taxRate = 0.18, // 18% GST
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get totalMrp => items.fold(0.0, (sum, item) => sum + item.totalMrp);
  double get productSavings => totalMrp - subtotal;
  double get couponSavings => couponDiscount;
  double get totalSavings => productSavings + couponSavings;
  double get taxAmount => (subtotal - couponDiscount) * taxRate;
  double get finalShipping => 0.0;
  double get total => subtotal - couponDiscount + taxAmount + finalShipping;

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  bool get hasRxItems => items.any((item) => item.requiresPrescription);

  Cart copyWith({
    List<CartItem>? items,
    String? couponCode,
    double? couponDiscount,
    double? taxRate,
  }) {
    return Cart(
      items: items ?? this.items,
      couponCode: couponCode ?? this.couponCode,
      couponDiscount: couponDiscount ?? this.couponDiscount,
      taxRate: taxRate ?? this.taxRate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'coupon_code': couponCode,
      'coupon_discount': couponDiscount,
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
      discountPercentage: CouponResponse._parseDouble(
        json['discount_percentage'],
      ),
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
      'items': items
          .map(
            (item) => {
              'product_id': item.productId,
              'quantity': item.quantity,
              'price': item.price,
            },
          )
          .toList(),
      'coupon_code': couponCode,
      'total_amount': total,
      'delivery_address': deliveryAddress,
      'notes': notes,
    };
  }
}
