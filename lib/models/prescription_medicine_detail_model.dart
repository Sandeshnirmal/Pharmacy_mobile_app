import 'package:pharmacy/models/product_model.dart';

class PrescriptionMedicineDetailModel {
  final String id; // Changed to String
  final String? recognizedTextRaw;
  final String? extractedMedicineName;
  final String? extractedDosage;
  final String? extractedFrequency;
  final String? extractedForm;
  final String? extractedDuration;
  final String? extractedInstructions;
  final double? aiConfidenceScore;
  final bool? isValidForOrder;
  final String? verifiedMedicineName;
  final String? verifiedDosage;
  final String? verifiedForm;
  final ProductModel? mappedProduct;
  final List<ProductModel>? suggestedProducts;
  final String? productName;
  final double? productPrice;
  final String? productStrength;
  final String? productForm;
  final String? verificationStatusDisplay;

  // New fields from API response
  final int? quantityPrescribed;
  final int? quantityDispensed;
  final double? unitPrice;
  final double? totalPrice;
  final bool? customerApproved;
  final String? pharmacistComment;
  final String? clarificationNotes;
  final String? verifiedFrequency;
  final String? verifiedDuration;
  final int? verifiedQuantity;
  final String? verifiedInstructions;
  final int? lineNumber;
  final bool? isPrescriptionRequired;

  PrescriptionMedicineDetailModel({
    required this.id,
    this.recognizedTextRaw,
    this.extractedMedicineName,
    this.extractedDosage,
    this.extractedFrequency,
    this.extractedForm,
    this.extractedDuration,
    this.extractedInstructions,
    this.aiConfidenceScore,
    this.isValidForOrder,
    this.verifiedMedicineName,
    this.verifiedDosage,
    this.verifiedForm,
    this.mappedProduct,
    this.suggestedProducts,
    this.productName,
    this.productPrice,
    this.productStrength,
    this.productForm,
    this.verificationStatusDisplay,
    this.quantityPrescribed,
    this.quantityDispensed,
    this.unitPrice,
    this.totalPrice,
    this.customerApproved,
    this.pharmacistComment,
    this.clarificationNotes,
    this.verifiedFrequency,
    this.verifiedDuration,
    this.verifiedQuantity,
    this.verifiedInstructions,
    this.lineNumber,
    this.isPrescriptionRequired,
  });

  factory PrescriptionMedicineDetailModel.fromJson(Map<String, dynamic> json) {
    List<ProductModel>? suggestedProductsList;
    if (json['suggested_products'] != null) {
      suggestedProductsList = (json['suggested_products'] as List)
          .map((i) => ProductModel.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    ProductModel? mappedProductModel;
    if (json['mapped_product'] != null &&
        json['mapped_product'] is Map<String, dynamic>) {
      mappedProductModel = ProductModel.fromJson(
        json['mapped_product'] as Map<String, dynamic>,
      );
    }

    return PrescriptionMedicineDetailModel(
      id: json['id']?.toString() ?? '', // Handle as String
      recognizedTextRaw: json['recognized_text_raw'] as String?,
      extractedMedicineName: json['extracted_medicine_name'] as String?,
      extractedDosage: json['extracted_dosage'] as String?,
      extractedFrequency: json['extracted_frequency'] as String?,
      extractedForm: json['extracted_form'] as String?,
      extractedDuration: json['extracted_duration'] as String?,
      extractedInstructions: json['extracted_instructions'] as String?,
      aiConfidenceScore: json['ai_confidence_score'] is String
          ? double.tryParse(json['ai_confidence_score'])
          : (json['ai_confidence_score'] as num?)?.toDouble(),
      isValidForOrder: json['is_valid_for_order'] as bool?,
      verifiedMedicineName: json['verified_medicine_name'] as String?,
      verifiedDosage: json['verified_dosage'] as String?,
      verifiedForm: json['verified_form'] as String?,
      mappedProduct: mappedProductModel,
      suggestedProducts: suggestedProductsList,
      productName: json['product_name'] as String?,
      productPrice: json['product_price'] is String
          ? double.tryParse(json['product_price'])
          : (json['product_price'] as num?)?.toDouble(),
      productStrength: json['product_strength'] as String?,
      productForm: json['product_form'] as String?,
      verificationStatusDisplay: json['verification_status'] as String?,
      quantityPrescribed: json['quantity_prescribed'] as int?,
      quantityDispensed: json['quantity_dispensed'] as int?,
      unitPrice: json['unit_price'] is String
          ? double.tryParse(json['unit_price'])
          : (json['unit_price'] as num?)?.toDouble(),
      totalPrice: json['total_price'] is String
          ? double.tryParse(json['total_price'])
          : (json['total_price'] as num?)?.toDouble(),
      customerApproved: json['customer_approved'] as bool?,
      pharmacistComment: json['pharmacist_comment'] as String?,
      clarificationNotes: json['clarification_notes'] as String?,
      verifiedFrequency: json['verified_frequency'] as String?,
      verifiedDuration: json['verified_duration'] as String?,
      verifiedQuantity: json['verified_quantity'] as int?,
      verifiedInstructions: json['verified_instructions'] as String?,
      lineNumber: json['line_number'] as int?,
      isPrescriptionRequired: json['is_prescription_required'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recognized_text_raw': recognizedTextRaw,
      'extracted_medicine_name': extractedMedicineName,
      'extracted_dosage': extractedDosage,
      'extracted_frequency': extractedFrequency,
      'extracted_form': extractedForm,
      'extracted_duration': extractedDuration,
      'extracted_instructions': extractedInstructions,
      'ai_confidence_score': aiConfidenceScore,
      'is_valid_for_order': isValidForOrder,
      'verified_medicine_name': verifiedMedicineName,
      'verified_dosage': verifiedDosage,
      'verified_form': verifiedForm,
      'mapped_product': mappedProduct?.toJson(),
      'suggested_products': suggestedProducts
          ?.map((ProductModel e) => e.toJson())
          .toList(),
      'product_name': productName,
      'product_price': productPrice,
      'product_strength': productStrength,
      'product_form': productForm,
      'verification_status': verificationStatusDisplay,
      'quantity_prescribed': quantityPrescribed,
      'quantity_dispensed': quantityDispensed,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'customer_approved': customerApproved,
      'pharmacist_comment': pharmacistComment,
      'clarification_notes': clarificationNotes,
      'verified_frequency': verifiedFrequency,
      'verified_duration': verifiedDuration,
      'verified_quantity': verifiedQuantity,
      'verified_instructions': verifiedInstructions,
      'line_number': lineNumber,
      'is_prescription_required': isPrescriptionRequired,
    };
  }
}
