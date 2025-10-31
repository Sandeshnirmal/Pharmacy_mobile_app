// Order Model for Enhanced Order Management
class Order {
  final int id;
  final String orderNumber;
  final DateTime orderDate;
  final String status;
  final String statusDisplayName;
  final double totalAmount;
  final int totalItems;
  final String paymentStatus;
  final String paymentMethod;
  final List<OrderItem> items;
  final Map<String, dynamic>? deliveryAddress; // Changed to Map for JSONField
  final bool isPrescriptionOrder; // New field
  final int? prescriptionId; // New field
  final String? notes;
  final String? trackingNumber;
  final DateTime? estimatedDelivery;

  Order({
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
    this.deliveryAddress, // Updated field
    required this.isPrescriptionOrder, // New field
    this.prescriptionId, // New field
    this.notes,
    this.trackingNumber,
    this.estimatedDelivery,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    print(
      'Order.fromJson: Raw JSON for ID ${json['id']}: ${json.toString()}',
    ); // Added for extreme debugging
    print(
      'Order.fromJson: Value of json[\'order_status\'] for ID ${json['id']}: ${json['order_status']}',
    ); // Added for extreme debugging

    String orderStatus;
    dynamic rawOrderStatus = json['order_status'];
    dynamic rawStatus = json['status'];

    if (rawOrderStatus is String && rawOrderStatus.trim().isNotEmpty) {
      orderStatus = rawOrderStatus.trim().toLowerCase();
    } else if (rawStatus is String && rawStatus.trim().isNotEmpty) {
      orderStatus = rawStatus.trim().toLowerCase();
    } else {
      orderStatus = 'pending';
    }

    print(
      'Order.fromJson: Final determined status for ID ${json['id']}: $orderStatus',
    ); // Added for extreme debugging

    return Order(
      id: json['id'] ?? 0,
      orderNumber: json['order_number'] ?? json['id']?.toString() ?? '0',
      orderDate: json['order_date'] != null
          ? DateTime.parse(json['order_date'])
          : DateTime.now(),
      status: orderStatus,
      statusDisplayName: _getStatusDisplayName(
        orderStatus,
      ), // Use the parsed status
      totalAmount: _parseDouble(json['total_amount']),
      totalItems:
          _parseInt(json['total_items']) ??
          _calculateItemsFromList(json['items']),
      paymentStatus: json['payment_status'] ?? 'pending',
      paymentMethod: json['payment_method'] ?? 'unknown',
      items: _parseItems(json['items']),
      deliveryAddress:
          json['delivery_address']
              as Map<String, dynamic>?, // Map delivery_address JSONField
      isPrescriptionOrder: json['is_prescription_order'] ?? false,
      prescriptionId: json['prescription_id'] as int?,
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

  static List<OrderItem> _parseItems(dynamic items) {
    if (items is List) {
      return items.map((item) => OrderItem.fromJson(item)).toList();
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
      'delivery_address': deliveryAddress, // Use deliveryAddress
      'is_prescription_order': isPrescriptionOrder,
      'prescription_id': prescriptionId,
      'notes': notes,
      'tracking_number': trackingNumber,
      'estimated_delivery': estimatedDelivery?.toIso8601String(),
    };
  }
}

class OrderItem {
  final int id;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? productImage;
  final int? productId; // New field
  final int? batchId; // New field

  OrderItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.productImage,
    this.productId, // New field
    this.batchId, // New field
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final quantity = Order._parseInt(json['quantity']) ?? 1;
    final unitPrice = Order._parseDouble(
      json['unit_price_at_order'] ?? json['unit_price'],
    );

    return OrderItem(
      id: json['id'] ?? 0,
      productName:
          json['product']?['name'] ?? json['product_name'] ?? 'Unknown Product',
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: quantity * unitPrice,
      productImage: json['product']?['image_url'] ?? json['product_image'],
      productId: json['product_id'] as int?, // Parse product_id
      batchId: json['batch_id'] as int?, // Parse batch_id
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
      'product_id': productId, // Include product_id
      'batch_id': batchId, // Include batch_id
    };
  }
}
