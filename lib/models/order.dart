class Order {
  final int id;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double totalAmount;
  final double? discountAmount;
  final double? taxAmount;
  final double? shippingAmount;
  final String? paymentMethod;
  final String? paymentStatus;
  final List<OrderItem> items;
  final Address? shippingAddress;
  final Address? billingAddress;
  final String? notes;
  final String? trackingNumber;
  final DateTime? estimatedDelivery;
  final int userId;

  Order({
    required this.id,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.totalAmount,
    this.discountAmount,
    this.taxAmount,
    this.shippingAmount,
    this.paymentMethod,
    this.paymentStatus,
    required this.items,
    this.shippingAddress,
    this.billingAddress,
    this.notes,
    this.trackingNumber,
    this.estimatedDelivery,
    required this.userId,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Handle potential 'order_status' from Django
    String orderStatus = json['order_status'] ?? json['status'] ?? 'pending';
    // Handle potential 'order_date' from Django
    DateTime orderCreatedAt = json['created_at'] != null
        ? DateTime.parse(json['created_at'])
        : (json['order_date'] != null
              ? DateTime.parse(json['order_date'])
              : DateTime.now());

    // Handle delivery_address as shippingAddress
    Address? shippingAddress;
    if (json['delivery_address'] != null && json['delivery_address'] is Map) {
      // Create a dummy ID for the address if not provided by Django's JSONField
      // This is a workaround as Django's JSONField for address doesn't have an ID
      final Map<String, dynamic> addressJson = Map<String, dynamic>.from(
        json['delivery_address'],
      );
      addressJson['id'] = 0; // Assign a dummy ID
      addressJson['created_at'] = orderCreatedAt
          .toIso8601String(); // Use order creation date
      addressJson['updated_at'] = orderCreatedAt
          .toIso8601String(); // Use order creation date
      addressJson['type'] = 'delivery'; // Default type
      addressJson['street'] =
          addressJson['address_line_1'] ?? ''; // Map address_line_1 to street
      addressJson['pincode'] =
          addressJson['pincode']?.toString() ?? ''; // Ensure pincode is string
      shippingAddress = Address.fromJson(addressJson);
    } else if (json['address'] != null && json['address'] is Map) {
      // If Django sends a nested Address object (less likely with current serializer)
      shippingAddress = Address.fromJson(json['address']);
    }

    return Order(
      id: json['id'] ?? 0,
      status: orderStatus,
      createdAt: orderCreatedAt,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      totalAmount: _parseDouble(json['total_amount']),
      discountAmount: _parseDouble(json['discount_amount']),
      taxAmount: _parseDouble(
        json['tax_amount'],
      ), // Django doesn't provide this directly
      shippingAmount: _parseDouble(
        json['shipping_fee'],
      ), // Map shipping_fee to shippingAmount
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'],
      items: json['items'] != null
          ? (json['items'] as List)
                .map((item) => OrderItem.fromJson(item))
                .toList()
          : [],
      shippingAddress: shippingAddress,
      billingAddress: null, // Django doesn't provide this directly
      notes: json['notes'],
      trackingNumber: json['tracking_number'],
      estimatedDelivery: json['expected_delivery_date'] != null
          ? DateTime.parse(json['expected_delivery_date'])
          : null,
      userId: json['user'] ?? 0, // Map 'user' (ID) to 'userId'
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'total_amount': totalAmount,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'shipping_amount': shippingAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'items': items.map((item) => item.toJson()).toList(),
      'shipping_address': shippingAddress?.toJson(),
      'billing_address': billingAddress?.toJson(),
      'notes': notes,
      'tracking_number': trackingNumber,
      'estimated_delivery': estimatedDelivery?.toIso8601String(),
      'user_id': userId,
    };
  }

  Order copyWith({
    int? id,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? totalAmount,
    double? discountAmount,
    double? taxAmount,
    double? shippingAmount,
    String? paymentMethod,
    String? paymentStatus,
    List<OrderItem>? items,
    Address? shippingAddress,
    Address? billingAddress,
    String? notes,
    String? trackingNumber,
    DateTime? estimatedDelivery,
    int? userId,
  }) {
    return Order(
      id: id ?? this.id,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      shippingAmount: shippingAmount ?? this.shippingAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      items: items ?? this.items,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      billingAddress: billingAddress ?? this.billingAddress,
      notes: notes ?? this.notes,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    return 'Order(id: $id, status: $status, totalAmount: $totalAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Additional getters for compatibility
  String get orderNumber => id.toString().padLeft(6, '0');

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
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

class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Extract product details from nested 'product' object
    final productJson = json['product'] as Map<String, dynamic>?;
    final productId = productJson?['id'] ?? json['product_id'] ?? 0;
    final productName = productJson?['name'] ?? json['product_name'] ?? '';
    final productImage = productJson?['image_url'] ?? json['product_image'];

    return OrderItem(
      id: json['id'] ?? 0,
      productId: productId,
      productName: productName,
      productImage: productImage,
      quantity: json['quantity'] ?? 1,
      unitPrice: _parseDouble(
        json['unit_price_at_order'] ?? json['unit_price'],
      ), // Prefer unit_price_at_order
      totalPrice: _parseDouble(json['total_price']),
      notes: json['notes'], // Django OrderItemSerializer doesn't have 'notes'
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'notes': notes,
    };
  }

  OrderItem copyWith({
    int? id,
    int? productId,
    String? productName,
    String? productImage,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    String? notes,
  }) {
    return OrderItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'OrderItem(id: $id, productName: $productName, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

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

class Address {
  final int id;
  final String type;
  final String street;
  final String city;
  final String state;
  final String pincode;
  final String? landmark;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Address({
    required this.id,
    required this.type,
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullAddress {
    final parts = [street, city, state, pincode];
    return parts.where((part) => part.isNotEmpty).join(', ');
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? 0,
      type:
          json['address_type'] ??
          json['type'] ??
          'home', // Handle both 'address_type' and 'type'
      street:
          json['address_line_1'] ??
          json['street'] ??
          '', // Handle both 'address_line_1' and 'street'
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode']?.toString() ?? '', // Ensure pincode is string
      landmark: json['landmark'],
      isDefault: json['is_default'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'street': street,
      'city': city,
      'state': state,
      'pincode': pincode,
      'landmark': landmark,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Address(id: $id, type: $type, fullAddress: $fullAddress)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
