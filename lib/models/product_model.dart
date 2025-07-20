// Product Model for Flutter Pharmacy App
import 'user_model.dart';

class ProductModel {
  final int id;
  final String name;
  final String? description;
  final String? strength;
  final String? form;
  final double price;
  final double mrp;
  final String manufacturer;
  final String? category;
  final String? genericName;
  final bool requiresPrescription;
  final int stockQuantity;
  final bool isActive;
  final String? imageUrl;
  final DateTime? expiryDate;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    this.strength,
    this.form,
    required this.price,
    required this.mrp,
    required this.manufacturer,
    this.category,
    this.genericName,
    required this.requiresPrescription,
    required this.stockQuantity,
    required this.isActive,
    this.imageUrl,
    this.expiryDate,
  });

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

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      strength: json['strength'],
      form: json['form'],
      price: _parseDouble(json['price']),
      mrp: _parseDouble(json['mrp']),
      manufacturer: json['manufacturer'] ?? '',
      category: json['category'] is Map ? json['category']['name'] : json['category'],
      genericName: json['generic_name'] is Map ? json['generic_name']['name'] : json['generic_name'],
      requiresPrescription: json['is_prescription_required'] ?? false,
      stockQuantity: json['stock_quantity'] ?? 0,
      isActive: json['is_active'] ?? true,
      imageUrl: json['image_url'],
      expiryDate: json['expiry_date'] != null 
          ? DateTime.parse(json['expiry_date']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'strength': strength,
      'form': form,
      'price': price,
      'mrp': mrp,
      'manufacturer': manufacturer,
      'category': category,
      'generic_name': genericName,
      'requires_prescription': requiresPrescription,
      'stock_quantity': stockQuantity,
      'is_active': isActive,
      'image_url': imageUrl,
      'expiry_date': expiryDate?.toIso8601String(),
    };
  }

  bool get isInStock => stockQuantity > 0;
  bool get isOnSale => price < mrp;
  double get discountPercentage => mrp > 0 ? ((mrp - price) / mrp) * 100 : 0;
  double get savings => mrp - price;

  String get displayName {
    if (strength != null && form != null) {
      return '$name $strength $form';
    } else if (strength != null) {
      return '$name $strength';
    } else if (form != null) {
      return '$name $form';
    }
    return name;
  }
}

class OrderModel {
  final int id;
  final String orderNumber;
  final DateTime orderDate;
  final String status;
  final double totalAmount;
  final String paymentMethod;
  final String? paymentStatus;
  final AddressModel? deliveryAddress;
  final List<OrderItemModel> items;
  final int? prescriptionId;
  final DateTime? estimatedDelivery;
  final String? trackingNumber;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.orderDate,
    required this.status,
    required this.totalAmount,
    required this.paymentMethod,
    this.paymentStatus,
    this.deliveryAddress,
    required this.items,
    this.prescriptionId,
    this.estimatedDelivery,
    this.trackingNumber,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? 0,
      orderNumber: json['order_number'] ?? '',
      orderDate: DateTime.parse(json['order_date'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? '',
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      paymentMethod: json['payment_method'] ?? '',
      paymentStatus: json['payment_status'],
      deliveryAddress: json['delivery_address'] != null
          ? AddressModel.fromJson(json['delivery_address'])
          : null,
      items: (json['items'] as List? ?? [])
          .map((item) => OrderItemModel.fromJson(item))
          .toList(),
      prescriptionId: json['prescription_id'],
      estimatedDelivery: json['estimated_delivery'] != null
          ? DateTime.parse(json['estimated_delivery'])
          : null,
      trackingNumber: json['tracking_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'order_date': orderDate.toIso8601String(),
      'status': status,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'delivery_address': deliveryAddress?.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'prescription_id': prescriptionId,
      'estimated_delivery': estimatedDelivery?.toIso8601String(),
      'tracking_number': trackingNumber,
    };
  }

  bool get isPrescriptionOrder => prescriptionId != null;
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  
  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Order Placed';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

class OrderItemModel {
  final int id;
  final ProductModel product;
  final int quantity;
  final double price;
  final double totalPrice;

  OrderItemModel({
    required this.id,
    required this.product,
    required this.quantity,
    required this.price,
    required this.totalPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] ?? 0,
      product: ProductModel.fromJson(json['product'] ?? {}),
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
      totalPrice: (json['total_price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'price': price,
      'total_price': totalPrice,
    };
  }
}

class OrderResponse {
  final bool success;
  final int orderId;
  final String orderNumber;
  final double totalAmount;
  final String orderStatus;
  final String? estimatedDelivery;
  final String message;

  OrderResponse({
    required this.success,
    required this.orderId,
    required this.orderNumber,
    required this.totalAmount,
    required this.orderStatus,
    this.estimatedDelivery,
    required this.message,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      success: json['success'] ?? false,
      orderId: json['order_id'] ?? 0,
      orderNumber: json['order_number'] ?? '',
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      orderStatus: json['order_status'] ?? '',
      estimatedDelivery: json['estimated_delivery'],
      message: json['message'] ?? '',
    );
  }
}


