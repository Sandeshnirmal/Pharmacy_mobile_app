import 'product_model.dart';

class PrescriptionDetailModel {
  final String id; // Changed to String
  final String imageUrl;
  final String status;
  final DateTime uploadedAt;
  final List<ProductModel>?
  suggestedMedicines; // Products identified from prescription

  PrescriptionDetailModel({
    required this.id,
    required this.imageUrl,
    required this.status,
    required this.uploadedAt,
    this.suggestedMedicines,
  });

  factory PrescriptionDetailModel.fromJson(Map<String, dynamic> json) {
    List<ProductModel>? medicines;
    if (json['suggested_medicines'] != null) {
      medicines = (json['suggested_medicines'] as List)
          .map((i) => ProductModel.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return PrescriptionDetailModel(
      id: json['id']?.toString() ?? '', // Handle as String
      imageUrl:
          json['image_url']?.toString() ??
          '', // Handle as String, provide default empty string
      status:
          json['status']?.toString() ??
          'Unknown', // Handle as String, provide default 'Unknown'
      uploadedAt:
          DateTime.tryParse(json['uploaded_at']?.toString() ?? '') ??
          DateTime.now(), // Robust parsing, handle null or non-string
      suggestedMedicines: medicines,
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
    };
  }
}
