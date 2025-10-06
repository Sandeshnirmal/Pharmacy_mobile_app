class BatchModel {
  final int id;
  final String batchNumber;
  final DateTime? manufacturingDate;
  final DateTime expiryDate;
  final int quantity;
  final int currentQuantity;
  final double costPrice;
  final double sellingPrice;
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
      'mfg_license_number': mfgLicenseNumber,
    };
  }
}
