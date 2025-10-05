// Order Model for Enhanced Order Management
class OrderModel {
  final int id;
  final String orderNumber;
  final DateTime orderDate;
  final String status;
  final String statusDisplayName;
  final double totalAmount;
  final int totalItems;
  final String paymentStatus;
  final String paymentMethod;
  final List<OrderItemModel> items;
  final AddressModel? shippingAddress;
  final String? notes;
  final String? trackingNumber;
  final DateTime? estimatedDelivery;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.orderDate,
    required this.status,
    required this.statusDisplayName,
    required this.totalAmount,
    required this.totalItems,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.items,
    this.shippingAddress,
    this.notes,
    this.trackingNumber,
    this.estimatedDelivery,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    print(
      'OrderModel.fromJson: Called for ID: ${json['id']}',
    ); // Unique debug print
    return OrderModel(
      id: json['id'] ?? 0,
      orderNumber: json['order_number'] ?? json['id']?.toString() ?? '0',
      orderDate: json['order_date'] != null
          ? DateTime.parse(json['order_date'])
          : DateTime.now(),
      status: _parseOrderStatus(json['order_status'] ?? json['status']),
      statusDisplayName: _getStatusDisplayName(
        _parseOrderStatus(json['order_status'] ?? json['status']),
      ),
      totalAmount: _parseDouble(json['total_amount']),
      totalItems:
          _parseInt(json['total_items']) ??
          _calculateItemsFromList(json['items']),
      paymentStatus: json['payment_status'] ?? 'pending',
      paymentMethod: json['payment_method'] ?? 'unknown',
      items: _parseItems(json['items']),
      shippingAddress: json['address'] != null
          ? AddressModel.fromJson(json['address'])
          : null,
      notes: json['notes'],
      trackingNumber: json['tracking_number'],
      estimatedDelivery: json['estimated_delivery_date'] != null
          ? DateTime.parse(json['estimated_delivery_date'])
          : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static int _calculateItemsFromList(dynamic items) {
    if (items is List) return items.length;
    return 0;
  }

  static String _parseOrderStatus(dynamic statusValue) {
    print(
      'OrderModel._parseOrderStatus: Received statusValue: $statusValue (Type: ${statusValue.runtimeType})',
    );
    String status = (statusValue ?? 'pending').toString().toLowerCase();
    if (status.isEmpty) {
      print(
        'OrderModel._parseOrderStatus: Status was empty, defaulting to "pending"',
      );
      return 'pending';
    }
    print('OrderModel._parseOrderStatus: Returning status: $status');
    return status;
  }

  static String _getStatusDisplayName(String status) {
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
      case 'payment_completed': // Map backend status to a displayable status
        return 'Processing';
      default:
        return status;
    }
  }

  static List<OrderItemModel> _parseItems(dynamic items) {
    if (items is List) {
      return items.map((item) => OrderItemModel.fromJson(item)).toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'order_date': orderDate.toIso8601String(),
      'status': status,
      'total_amount': totalAmount,
      'total_items': totalItems,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'items': items.map((item) => item.toJson()).toList(),
      'shipping_address': shippingAddress?.toJson(),
      'notes': notes,
      'tracking_number': trackingNumber,
      'estimated_delivery': estimatedDelivery?.toIso8601String(),
    };
  }
}

class OrderItemModel {
  final int id;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? productImage;

  OrderItemModel({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.productImage,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final quantity = OrderModel._parseInt(json['quantity']) ?? 1;
    final unitPrice = OrderModel._parseDouble(
      json['unit_price_at_order'] ?? json['unit_price'],
    );

    return OrderItemModel(
      id: json['id'] ?? 0,
      productName:
          json['product']?['name'] ?? json['product_name'] ?? 'Unknown Product',
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: quantity * unitPrice,
      productImage: json['product']?['image_url'] ?? json['product_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'product_image': productImage,
    };
  }
}

class AddressModel {
  final int id;
  final String fullName;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String? phone;

  AddressModel({
    required this.id,
    required this.fullName,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.phone,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? json['name'] ?? '',
      addressLine1: json['address_line_1'] ?? json['address'] ?? '',
      addressLine2: json['address_line_2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postal_code'] ?? json['zip_code'] ?? '',
      country: json['country'] ?? 'India',
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'phone': phone,
    };
  }

  String get fullAddress {
    final parts = [
      addressLine1,
      if (addressLine2?.isNotEmpty == true) addressLine2,
      city,
      state,
      postalCode,
      country,
    ];
    return parts.join(', ');
  }
}
