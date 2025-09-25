import 'package:pharmacy/models/product_model.dart';
import 'package:pharmacy/config/api_config.dart';

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
  final String? mappingStatus;
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
  final String? mappingStatusDisplay;

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
    this.mappingStatus,
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
    this.mappingStatusDisplay,
  });

  factory PrescriptionMedicineDetailModel.fromJson(Map<String, dynamic> json) {
    List<ProductModel>? suggestedProductsList;
    if (json['suggested_products'] != null) {
      suggestedProductsList = (json['suggested_products'] as List)
          .map((i) => ProductModel.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    ProductModel? mappedProductModel;
    if (json['mapped_product'] != null && json['mapped_product'] is Map<String, dynamic>) {
      mappedProductModel = ProductModel.fromJson(json['mapped_product'] as Map<String, dynamic>);
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
      mappingStatus: json['mapping_status'] as String?,
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
      mappingStatusDisplay: json['mapping_status_display'] as String?,
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
      'mapping_status': mappingStatus,
      'is_valid_for_order': isValidForOrder,
      'verified_medicine_name': verifiedMedicineName,
      'verified_dosage': verifiedDosage,
      'verified_form': verifiedForm,
      'mapped_product': mappedProduct?.toJson(),
      'suggested_products': suggestedProducts?.map((ProductModel e) => e.toJson()).toList(),
      'product_name': productName,
      'product_price': productPrice,
      'product_strength': productStrength,
      'product_form': productForm,
      'mapping_status_display': mappingStatusDisplay,
    };
  }
}
