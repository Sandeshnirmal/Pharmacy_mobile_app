// Prescription Models for Flutter Pharmacy App

// Helper function to safely parse double from various types
import 'package:pharmacy/models/prescription_detail_model.dart';

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}

class PrescriptionUploadResponse {
  final bool success;
  final String prescriptionId; // Changed to String
  final String message;
  final String status;
  final double? ocrConfidence; // Added ocrConfidence
  final int? medicinesFound; // Added medicinesFound
  final Map<String, dynamic>? processingSummary; // Added processingSummary
  final bool? canProceedToOrder; // Added canProceedToOrder

  PrescriptionUploadResponse({
    required this.success,
    required this.prescriptionId,
    required this.message,
    required this.status,
    this.ocrConfidence,
    this.medicinesFound,
    this.processingSummary,
    this.canProceedToOrder,
  });

  factory PrescriptionUploadResponse.fromJson(Map<String, dynamic> json) {
    return PrescriptionUploadResponse(
      success: json['success'] ?? false,
      prescriptionId: json['prescription_id'] ?? '', // Handle as String
      message: json['message'] ?? '',
      status: json['status'] ?? '',
      ocrConfidence: _parseDouble(json['ocr_confidence']),
      medicinesFound: json['medicines_found'],
      processingSummary: json['processing_summary'],
      canProceedToOrder: json['can_proceed_to_order'],
    );
  }
}

class PrescriptionStatusResponse {
  final String status;
  final bool processed;
  final bool isReady;
  final String? prescriptionId; // Added prescriptionId for consistency

  PrescriptionStatusResponse({
    required this.status,
    required this.processed,
    required this.isReady,
    this.prescriptionId,
  });

  factory PrescriptionStatusResponse.fromJson(Map<String, dynamic> json) {
    return PrescriptionStatusResponse(
      status: json['status'] ?? '',
      processed: json['processed'] ?? json['ai_processed'] ?? false,
      isReady: json['is_ready'] ?? false,
      prescriptionId: json['prescription_id'],
    );
  }
}

class PrescriptionSuggestionsResponse {
  final String prescriptionId; // Changed to String
  final String status;
  final PrescriptionSummary summary;
  final List<MedicineModel> medicines;
  final PricingModel pricing;
  final bool canOrder;

  PrescriptionSuggestionsResponse({
    required this.prescriptionId,
    required this.status,
    required this.summary,
    required this.medicines,
    required this.pricing,
    required this.canOrder,
  });

  factory PrescriptionSuggestionsResponse.fromJson(Map<String, dynamic> json) {
    return PrescriptionSuggestionsResponse(
      prescriptionId: json['prescription_id'] ?? '', // Handle as String
      status: json['status'] ?? '',
      summary: PrescriptionSummary.fromJson(json['summary'] ?? {}),
      medicines: (json['medicines'] as List? ?? [])
          .map((medicine) => MedicineModel.fromJson(medicine))
          .toList(),
      pricing: PricingModel.fromJson(json['pricing'] ?? {}),
      canOrder: json['can_order'] ?? false,
    );
  }
}

class PrescriptionSummary {
  final int totalMedicines;
  final int availableMedicines;
  final int unavailableMedicines;

  PrescriptionSummary({
    required this.totalMedicines,
    required this.availableMedicines,
    required this.unavailableMedicines,
  });

  factory PrescriptionSummary.fromJson(Map<String, dynamic> json) {
    return PrescriptionSummary(
      totalMedicines: json['total_medicines'] ?? 0,
      availableMedicines: json['available_medicines'] ?? 0,
      unavailableMedicines: json['unavailable_medicines'] ?? 0,
    );
  }
}

class MedicineModel {
  final int id;
  final String medicineName;
  final String? dosage;
  final String? quantity;
  final String? instructions;
  final double confidenceScore;
  final bool isAvailable;
  final ProductInfo? productInfo;
  int selectedQuantity;

  MedicineModel({
    required this.id,
    required this.medicineName,
    this.dosage,
    this.quantity,
    this.instructions,
    required this.confidenceScore,
    required this.isAvailable,
    this.productInfo,
    this.selectedQuantity = 1,
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel(
      id: json['id'] ?? 0,
      medicineName: json['medicine_name'] ?? '',
      dosage: json['dosage'],
      quantity: json['quantity'],
      instructions: json['instructions'],
      confidenceScore: _parseDouble(json['confidence_score']),
      isAvailable: json['is_available'] ?? false,
      productInfo: json['product_info'] != null
          ? ProductInfo.fromJson(json['product_info'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicine_name': medicineName,
      'dosage': dosage,
      'quantity': quantity,
      'instructions': instructions,
      'confidence_score': confidenceScore,
      'is_available': isAvailable,
      'product_info': productInfo?.toJson(),
      'selected_quantity': selectedQuantity,
    };
  }

  String get confidenceLevel {
    if (confidenceScore >= 0.9) return 'Excellent';
    if (confidenceScore >= 0.8) return 'Very Good';
    if (confidenceScore >= 0.7) return 'Good';
    if (confidenceScore >= 0.6) return 'Fair';
    return 'Poor';
  }

  MedicineModel copyWith({int? selectedQuantity}) {
    return MedicineModel(
      id: id,
      medicineName: medicineName,
      dosage: dosage,
      quantity: quantity,
      instructions: instructions,
      confidenceScore: confidenceScore,
      isAvailable: isAvailable,
      productInfo: productInfo,
      selectedQuantity: selectedQuantity ?? this.selectedQuantity,
    );
  }
}

class ProductInfo {
  final int productId;
  final String name;
  final double currentSellingPrice;
  final double discountPercentage;
  final bool inStock;
  final String manufacturer;
  final int stockQuantity;

  ProductInfo({
    required this.productId,
    required this.name,
    required this.currentSellingPrice,
    required this.discountPercentage,
    required this.inStock,
    required this.manufacturer,
    required this.stockQuantity,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      productId: json['product_id'] ?? 0,
      name: json['name'] ?? '',
      currentSellingPrice: _parseDouble(json['current_selling_price']),
      discountPercentage: _parseDouble(json['discount_percentage']),
      inStock: json['in_stock'] ?? false,
      manufacturer: json['manufacturer'] ?? '',
      stockQuantity: json['stock_quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'current_selling_price': currentSellingPrice,
      'discount_percentage': discountPercentage,
      'in_stock': inStock,
      'manufacturer': manufacturer,
      'stock_quantity': stockQuantity,
    };
  }

  double get savings => currentSellingPrice * (discountPercentage / 100);
  double get savingsPercentage => discountPercentage;
}

class PricingModel {
  final double subtotal;
  final double shipping;
  final double discount;
  final double total;

  PricingModel({
    required this.subtotal,
    required this.shipping,
    required this.discount,
    required this.total,
  });

  factory PricingModel.fromJson(Map<String, dynamic> json) {
    return PricingModel(
      subtotal: _parseDouble(json['subtotal']),
      shipping: _parseDouble(json['shipping']),
      discount: _parseDouble(json['discount']),
      total: _parseDouble(json['total']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subtotal': subtotal,
      'shipping': shipping,
      'discount': discount,
      'total': total,
    };
  }

  bool get hasFreeShipping => shipping == 0;
  bool get hasDiscount => discount > 0;
}

class PrescriptionModel {
  final String id;
  final String imageUrl;
  final String verificationStatus;
  final DateTime uploadDate;
  final bool aiProcessed;
  final double? aiConfidenceScore;
  final List<PrescriptionDetailModel>?
  details; // Assuming PrescriptionDetailModel is defined elsewhere

  PrescriptionModel({
    required this.id,
    required this.imageUrl,
    required this.verificationStatus,
    required this.uploadDate,
    required this.aiProcessed,
    this.aiConfidenceScore,
    this.details,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id'] as String,
      imageUrl: json['image_url'] as String,
      verificationStatus: json['verification_status'] as String,
      uploadDate: DateTime.parse(json['upload_date'] as String),
      aiProcessed: json['ai_processed'] as bool,
      aiConfidenceScore: _parseDouble(json['ai_confidence_score']),
      details: (json['details'] as List?)
          ?.map(
            (e) => PrescriptionDetailModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'verification_status': verificationStatus,
      'upload_date': uploadDate.toIso8601String(),
      'ai_processed': aiProcessed,
      'ai_confidence_score': aiConfidenceScore,
      'details': details?.map((e) => e.toJson()).toList(),
    };
  }
}
