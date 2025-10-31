class BatchModel {
  final int id;
  final String batchNumber;
  final DateTime? manufacturingDate;
  final DateTime expiryDate;
  final int quantity;
  final int currentQuantity;
  final double costPrice;
  final double sellingPrice;
  final double mrp; // Added MRP
  final double discountPercentage; // Added Discount Percentage
  final double onlineMrpPrice; // Added online_mrp_price
  final double onlineDiscountPercentage; // Added online_discount_percentage
  final double onlineSellingPrice; // Added online_selling_price
  final String? mfgLicenseNumber;

  BatchModel({
    required this.id,
    required this.batchNumber,
    this.manufacturingDate,
    required this.expiryDate,
    required this.quantity,
    required this.currentQuantity,
    required this.costPrice,
    required this.sellingPrice,
    required this.mrp, // Added MRP
    required this.discountPercentage, // Added Discount Percentage
    required this.onlineMrpPrice, // Added online_mrp_price
    required this.onlineDiscountPercentage, // Added online_discount_percentage
    required this.onlineSellingPrice, // Added online_selling_price
    this.mfgLicenseNumber,
  });

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    return BatchModel(
      id: json['id'] ?? 0,
      batchNumber: json['batch_number'] ?? '',
      manufacturingDate: json['manufacturing_date'] != null
          ? DateTime.tryParse(json['manufacturing_date'].toString())
          : null,
      expiryDate: DateTime.parse(json['expiry_date'].toString()),
      quantity: json['quantity'] ?? 0,
      currentQuantity: json['current_quantity'] ?? 0,
      costPrice:
          double.tryParse(json['cost_price']?.toString() ?? '0.0') ?? 0.0,
      sellingPrice:
          double.tryParse(json['selling_price']?.toString() ?? '0.0') ?? 0.0,
      mrp:
          double.tryParse(json['mrp_price']?.toString() ?? '0.0') ??
          0.0, // Parse MRP from mrp_price
      discountPercentage:
          double.tryParse(json['discount_percentage']?.toString() ?? '0.0') ??
          0.0, // Parse Discount Percentage
      onlineMrpPrice:
          double.tryParse(json['online_mrp_price']?.toString() ?? '0.0') ??
          0.0, // Parse online_mrp_price
      onlineDiscountPercentage:
          double.tryParse(
            json['online_discount_percentage']?.toString() ?? '0.0',
          ) ??
          0.0, // Parse online_discount_percentage
      onlineSellingPrice:
          double.tryParse(json['online_selling_price']?.toString() ?? '0.0') ??
          0.0, // Parse online_selling_price
      mfgLicenseNumber: json['mfg_license_number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_number': batchNumber,
      'manufacturing_date': manufacturingDate?.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
      'quantity': quantity,
      'current_quantity': currentQuantity,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'mrp': mrp, // Include MRP
      'discount_percentage': discountPercentage, // Include Discount Percentage
      'online_mrp_price': onlineMrpPrice, // Include online_mrp_price
      'online_discount_percentage':
          onlineDiscountPercentage, // Include online_discount_percentage
      'online_selling_price':
          onlineSellingPrice, // Include online_selling_price
      'mfg_license_number': mfgLicenseNumber,
    };
  }
}
