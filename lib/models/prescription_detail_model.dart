import 'package:pharmacy/models/product_model.dart';
import 'package:pharmacy/config/api_config.dart'; // Import ApiConfig
import 'package:pharmacy/models/prescription_medicine_detail_model.dart'; // Import the new model
import 'package:pharmacy/utils/api_logger.dart'; // Import ApiLogger

class PrescriptionDetailModel {
  final String id; // Changed to String
  final String imageUrl;
  final String status;
  final DateTime uploadedAt;
  final List<ProductModel>? suggestedMedicines; // Products identified from prescription
  final List<PrescriptionMedicineDetailModel>? prescriptionMedicines; // Detailed prescription medicines

  // New fields for extracted medicine details
  final String? extractedMedicineName;
  final String? extractedDosage;
  final String? extractedFrequency;
  final String? extractedForm;
  final String? mappingStatus;

  PrescriptionDetailModel({
    required this.id,
    required this.imageUrl,
    required this.status,
    required this.uploadedAt,
    this.suggestedMedicines,
    this.extractedMedicineName,
    this.extractedDosage,
    this.extractedFrequency,
    this.extractedForm,
    this.mappingStatus,
    this.prescriptionMedicines,
  });

  factory PrescriptionDetailModel.fromJson(Map<String, dynamic> json) {
    List<ProductModel>? medicines;
    if (json['suggested_medicines'] != null) {
      medicines = (json['suggested_medicines'] as List)
          .map((i) => ProductModel.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    String rawImageUrl = json['image_url']?.toString() ?? '';
    // Prepend base URL if the image URL is a relative path
    if (rawImageUrl.isNotEmpty && !rawImageUrl.startsWith('http')) {
      rawImageUrl = '${ApiConfig.baseUrl}$rawImageUrl';
    }

    return PrescriptionDetailModel(
      id: json['id']?.toString() ?? '', // Handle as String
      imageUrl: rawImageUrl, // Use the potentially modified URL
      status:
          json['status']?.toString() ??
          'Unknown', // Handle as String, provide default 'Unknown'
      uploadedAt:
          DateTime.tryParse(json['uploaded_at']?.toString() ?? '') ??
          DateTime.now(), // Robust parsing, handle null or non-string
      suggestedMedicines: medicines,
      prescriptionMedicines: (json['prescription_medicines'] as List?)
          ?.map((i) {
            if (i is Map<String, dynamic>) {
              return PrescriptionMedicineDetailModel.fromJson(i);
            } else {
              ApiLogger.logError(
                'Unexpected item type in prescriptionMedicines list: $i (type: ${i.runtimeType})',
              );
              // Return a default or throw an error, depending on desired behavior
              // For now, returning null to allow the list to be built with valid items
              return null;
            }
          })
          .whereType<PrescriptionMedicineDetailModel>() // Filter out nulls
          .toList(),
      extractedMedicineName: json['extracted_medicine_name']?.toString(),
      extractedDosage: json['extracted_dosage']?.toString(),
      extractedFrequency: json['extracted_frequency']?.toString(),
      extractedForm: json['extracted_form']?.toString(),
      mappingStatus: json['mapping_status_display']
          ?.toString(), // Use mapping_status_display
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'status': status,
      'uploaded_at': uploadedAt.toIso8601String(),
      'suggested_medicines': suggestedMedicines
          ?.map((e) => e.toJson())
          .toList(),
      'extracted_medicine_name': extractedMedicineName,
      'extracted_dosage': extractedDosage,
      'extracted_frequency': extractedFrequency,
      'extracted_form': extractedForm,
      'mapping_status_display': mappingStatus,
      'prescription_medicines': prescriptionMedicines?.map((e) => e.toJson()).toList(),
    };
  }
}
