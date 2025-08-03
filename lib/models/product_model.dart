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

  // Helper method to safely parse int from various types
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  // Helper method to safely parse string from various types
  static String _parseString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int || value is double) return value.toString();
    return value.toString();
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: _parseInt(json['id']),
      name: _parseString(json['name']),
      description: json['description']?.toString(),
      strength: json['strength']?.toString(),
      form: json['form']?.toString(),
      price: _parseDouble(json['price']),
      mrp: _parseDouble(json['mrp']),
      manufacturer: _parseString(json['manufacturer']),
      category: _parseCategoryName(json),
      genericName: _parseGenericName(json),
      requiresPrescription: json['is_prescription_required'] == true,
      stockQuantity: _parseInt(json['stock_quantity']),
      isActive: json['is_active'] == true,
      imageUrl: json['image_url']?.toString(),
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'].toString())
          : null,
    );
  }

  // Helper method to parse category name from various formats
  static String? _parseCategoryName(Map<String, dynamic> json) {
    final category = json['category'];
    if (category == null) return null;

    if (category is Map<String, dynamic>) {
      return category['name']?.toString();
    } else if (category is String) {
      return category;
    } else if (category is int) {
      // If it's an ID, try to get the category_name field
      return json['category_name']?.toString();
    }
    return category.toString();
  }

  // Helper method to parse generic name from various formats
  static String? _parseGenericName(Map<String, dynamic> json) {
    final genericName = json['generic_name'];
    if (genericName == null) return null;

    if (genericName is Map<String, dynamic>) {
      return genericName['name']?.toString();
    } else if (genericName is String) {
      return genericName;
    } else if (genericName is int) {
      // If it's an ID, try to get the generic_name_display field
      return json['generic_name_display']?.toString();
    }
    return genericName.toString();
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


