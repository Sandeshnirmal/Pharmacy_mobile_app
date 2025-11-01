import 'package:pharmacy/models/product_model.dart';
import 'package:pharmacy/config/api_config.dart'; // Import ApiConfig
import 'package:pharmacy/models/prescription_medicine_detail_model.dart'; // Import the new model
import 'package:pharmacy/utils/api_logger.dart'; // Import ApiLogger

class PrescriptionDetailModel {
  final String id; // Changed to String
  final String imageUrl;
  final String status;
  final DateTime uploadedAt;
  final List<ProductModel>?
  suggestedMedicines; // Products identified from prescription
  final List<PrescriptionMedicineDetailModel>?
  prescriptionMedicines; // Detailed prescription medicines

  // New fields for extracted medicine details
  final String? extractedMedicineName;
  final String? extractedDosage;
  final String? extractedFrequency;
  final String? extractedForm;

  // New fields from API response
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final int? totalMedicines;
  final int? verifiedMedicines;
  final String? processingStatus;
  final String? prescriptionNumber;
  final String? patientName;
  final int? patientAge;
  final String? patientGender;
  final String? doctorName;
  final String? doctorLicense;
  final String? hospitalClinic;
  final DateTime? prescriptionDate;
  final double? aiConfidenceScore;
  final String? rejectionReason;
  final String? clarificationNotes;
  final String? pharmacistNotes;
  final DateTime? verifiedAt;
  final DateTime? rejectedAt;
  final String? verificationNotes;
  final String? ocrText; // Added ocrText field

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
    this.prescriptionMedicines,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.totalMedicines,
    this.verifiedMedicines,
    this.processingStatus,
    this.prescriptionNumber,
    this.patientName,
    this.patientAge,
    this.patientGender,
    this.doctorName,
    this.doctorLicense,
    this.hospitalClinic,
    this.prescriptionDate,
    this.aiConfidenceScore,
    this.rejectionReason,
    this.clarificationNotes,
    this.pharmacistNotes,
    this.verificationNotes,
    this.verifiedAt,
    this.rejectedAt,
    this.ocrText, // Added to constructor
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
      userName: json['user_name']?.toString(),
      userEmail: json['user_email']?.toString(),
      userPhone: json['user_phone']?.toString(),
      totalMedicines: json['total_medicines'] as int?,
      verifiedMedicines: json['verified_medicines'] as int?,
      processingStatus: json['processing_status']?.toString(),
      prescriptionNumber: json['prescription_number']?.toString(),
      patientName: json['patient_name']?.toString(),
      patientAge: json['patient_age'] as int?,
      patientGender: json['patient_gender']?.toString(),
      doctorName: json['doctor_name']?.toString(),
      doctorLicense: json['doctor_license']?.toString(),
      hospitalClinic: json['hospital_clinic']?.toString(),
      prescriptionDate: DateTime.tryParse(
        json['prescription_date']?.toString() ?? '',
      ),
      aiConfidenceScore: json['ai_confidence_score'] is String
          ? double.tryParse(json['ai_confidence_score'])
          : (json['ai_confidence_score'] as num?)?.toDouble(),
      rejectionReason: json['rejection_reason']?.toString(),
      clarificationNotes: json['clarification_notes']?.toString(),
      pharmacistNotes: json['pharmacist_notes']?.toString(),
      verificationNotes: json['verification_notes']?.toString(),
      verifiedAt: DateTime.tryParse(json['verified_at']?.toString() ?? ''),
      rejectedAt: DateTime.tryParse(json['rejected_at']?.toString() ?? ''),
      ocrText: json['ocr_text']?.toString(), // Added fromJson mapping
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
      'prescription_medicines': prescriptionMedicines
          ?.map((e) => e.toJson())
          .toList(),
      'user_name': userName,
      'user_email': userEmail,
      'user_phone': userPhone,
      'total_medicines': totalMedicines,
      'verified_medicines': verifiedMedicines,
      'processing_status': processingStatus,
      'prescription_number': prescriptionNumber,
      'patient_name': patientName,
      'patient_age': patientAge,
      'patient_gender': patientGender,
      'doctor_name': doctorName,
      'doctor_license': doctorLicense,
      'hospital_clinic': hospitalClinic,
      'prescription_date': prescriptionDate?.toIso8601String(),
      'ai_confidence_score': aiConfidenceScore,
      'rejection_reason': rejectionReason,
      'clarification_notes': clarificationNotes,
      'pharmacist_notes': pharmacistNotes,
      'verification_notes': verificationNotes,
      'verified_at': verifiedAt?.toIso8601String(),
      'rejected_at': rejectedAt?.toIso8601String(),
      'ocr_text': ocrText, // Added to toJson
    };
  }
}
