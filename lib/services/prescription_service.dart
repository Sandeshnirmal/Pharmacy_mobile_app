// Prescription Service for AI Integration in Flutter
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/prescription_model.dart';
import '../models/prescription_detail_model.dart'; // Import the new model
import 'api_service.dart';

class PrescriptionService {
  final ApiService _apiService = ApiService();

  // Singleton pattern
  static final PrescriptionService _instance = PrescriptionService._internal();
  factory PrescriptionService() => _instance;
  PrescriptionService._internal();

  // Processing queue to track prescription status
  final Map<String, PrescriptionProcessingInfo> _processingQueue = {};

  // Upload prescription for paid order verification (payment-first flow)
  Future<ApiResponse<Map<String, dynamic>>> uploadPrescriptionForPaidOrder({
    required String orderId, // Changed to String
    required File imageFile,
  }) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64.encode(bytes);

      final response = await http.post(
        Uri.parse(
          '${ApiConfig.apiBaseUrl}/prescriptions/upload-for-paid-order/',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'order_id': orderId, 'image': base64Image}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(responseData);
      } else {
        return ApiResponse.error(
          responseData['error'] ?? 'Failed to upload prescription',
          response.statusCode,
        );
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Prescription upload for paid order error: $error');
      }
      return ApiResponse.error('Failed to upload prescription: $error', 0);
    }
  }

  // Get a single prescription detail by ID
  Future<ApiResponse<PrescriptionDetailModel>> getPrescriptionDetail(
    String prescriptionId,
  ) async {
    try {
      final result = await _apiService.getPrescriptionDetail(prescriptionId);
      if (result.isSuccess) {
        return ApiResponse.success(result.data!);
      } else {
        return ApiResponse.error(result.error!, result.statusCode);
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch prescription detail: $e', 0);
    }
  }

  // Get prescription verification status
  Future<ApiResponse<Map<String, dynamic>>> getPrescriptionVerificationStatus(
    String prescriptionId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.apiBaseUrl}/prescriptions/verification-status/$prescriptionId/',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse.success(responseData);
      } else {
        return ApiResponse.error(
          responseData['error'] ?? 'Failed to get verification status',
          response.statusCode,
        );
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Get verification status error: $error');
      }
      return ApiResponse.error('Failed to get verification status: $error', 0);
    }
  }

  // Simple prescription upload without AI processing (for order verification)
  Future<ApiResponse<PrescriptionUploadResponse>> uploadPrescriptionSimple(
    File imageFile,
  ) async {
    try {
      // Simple upload for order verification - no AI processing needed
      final result = await _apiService.uploadPrescription(imageFile);

      if (result.isSuccess) {
        return ApiResponse.success(result.data!);
      } else {
        return ApiResponse.error(result.error!, result.statusCode);
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Simple prescription upload error: $error');
      }
      return ApiResponse.error('Failed to upload prescription: $error', 0);
    }
  }

  // Upload prescription image and start AI processing (for medicine discovery)
  Future<ApiResponse<PrescriptionUploadResponse>> uploadPrescription(
    File imageFile,
  ) async {
    try {
      // print('Uploading prescription: ${imageFile.path}'); // Debug print removed

      final result = await _apiService.uploadPrescription(imageFile);

      if (result.isSuccess) {
        final response = result.data!;

        // Store processing info
        _processingQueue[response.prescriptionId] = PrescriptionProcessingInfo(
          prescriptionId: response.prescriptionId,
          status: 'processing',
          uploadTime: DateTime.now(),
          confidence: 0.0, // No longer using AI confidence
        );

        return ApiResponse.success(response);
      } else {
        return ApiResponse.error(result.error!, result.statusCode);
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Prescription upload error: $error');
      }
      return ApiResponse.error('Failed to upload prescription: $error', 0);
    }
  }

  // Check AI processing status
  Future<ApiResponse<PrescriptionStatusResponse>> checkProcessingStatus(
    String prescriptionId, // Changed to String
  ) async {
    try {
      final result = await _apiService.getPrescriptionStatus(prescriptionId);

      if (result.isSuccess) {
        final response = result.data!;

        // Update processing queue
        if (_processingQueue.containsKey(prescriptionId)) {
          _processingQueue[prescriptionId] = _processingQueue[prescriptionId]!
              .copyWith(
                status: response.status,
                aiProcessed: response.processed,
                confidence: 0.0, // No longer using confidence scores
              );
        }

        return ApiResponse.success(response);
      } else {
        return ApiResponse.error(result.error!, result.statusCode);
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Status check error: $error');
      }
      return ApiResponse.error('Failed to check status: $error', 0);
    }
  }

  // Get AI medicine suggestions
  Future<ApiResponse<PrescriptionSuggestionsResponse>> getMedicineSuggestions(
    String prescriptionId, // Changed to String
  ) async {
    try {
      final result = await _apiService.getMedicineSuggestions(prescriptionId);

      if (result.isSuccess) {
        final suggestions = result.data!;

        // Update processing queue
        if (_processingQueue.containsKey(prescriptionId)) {
          _processingQueue[prescriptionId] = _processingQueue[prescriptionId]!
              .copyWith(status: 'completed', suggestions: suggestions);
        }

        return ApiResponse.success(suggestions);
      } else {
        return ApiResponse.error(result.error!, result.statusCode);
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Get suggestions error: $error');
      }
      return ApiResponse.error('Failed to get medicine suggestions: $error', 0);
    }
  }

  // Wait for AI processing to complete
  Future<ApiResponse<PrescriptionSuggestionsResponse>> waitForProcessing(
    String prescriptionId, {
    Duration maxWaitTime = const Duration(seconds: 30),
    Duration checkInterval = const Duration(seconds: 2),
  }) async {
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < maxWaitTime) {
      try {
        final statusResult = await checkProcessingStatus(prescriptionId);

        if (statusResult.isSuccess && statusResult.data!.isReady) {
          // Processing complete, get suggestions
          return await getMedicineSuggestions(prescriptionId);
        }

        // Wait before checking again
        await Future.delayed(checkInterval);
      } catch (error) {
        return ApiResponse.error('Processing timeout: $error', 0);
      }
    }

    return ApiResponse.error('AI processing timeout', 408);
  }

  // Create order from prescription suggestions
  Future<ApiResponse<Map<String, dynamic>>> createOrderFromPrescription({
    required String prescriptionId, // Changed to String
    required List<MedicineModel> selectedMedicines,
    required int addressId,
    required String paymentMethod,
    String? specialInstructions,
  }) async {
    try {
      final orderData = {
        'prescription_id': prescriptionId,
        'medicines': selectedMedicines
            .map(
              (medicine) => {
                'detail_id': medicine.id,
                'quantity': medicine.selectedQuantity,
              },
            )
            .toList(),
        'address_id': addressId,
        'payment_method': paymentMethod,
        'special_instructions': specialInstructions ?? '',
      };

      final result = await _apiService.createPrescriptionOrder(orderData);

      if (result.isSuccess) {
        return ApiResponse.success({
          'order_id': result.data?.orderId,
          'message': 'Order created successfully',
        });
      } else {
        return ApiResponse.error(result.error!, result.statusCode);
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Create order error: $error');
      }
      return ApiResponse.error('Failed to create order: $error', 0);
    }
  }

  // Calculate total price for selected medicines
  double calculateTotalPrice(List<MedicineModel> selectedMedicines) {
    double subtotal = selectedMedicines.fold(0.0, (total, medicine) {
      return total +
          (medicine.productInfo?.price ?? 0.0) * medicine.selectedQuantity;
    });

    double shipping = subtotal >= 500 ? 0.0 : 50.0;
    double discount = subtotal >= 1000 ? subtotal * 0.1 : 0.0;

    return subtotal + shipping - discount;
  }

  // Calculate pricing breakdown
  PricingModel calculatePricing(List<MedicineModel> selectedMedicines) {
    double subtotal = selectedMedicines.fold(0.0, (total, medicine) {
      return total +
          (medicine.productInfo?.price ?? 0.0) * medicine.selectedQuantity;
    });

    double shipping = subtotal >= 500 ? 0.0 : 50.0;
    double discount = subtotal >= 1000 ? subtotal * 0.1 : 0.0;
    double total = subtotal + shipping - discount;

    return PricingModel(
      subtotal: subtotal,
      shipping: shipping,
      discount: discount,
      total: total,
    );
  }

  // Get all user prescriptions
  Future<ApiResponse<List<PrescriptionDetailModel>>>
  getUserPrescriptions() async {
    try {
      final result = await _apiService.getUserPrescriptions();
      if (result.isSuccess) {
        return ApiResponse.success(result.data!);
      } else {
        return ApiResponse.error(result.error!, result.statusCode);
      }
    } catch (e) {
      return ApiResponse.error('Failed to fetch user prescriptions: $e', 0);
    }
  }

  // Get processing status from queue
  PrescriptionProcessingInfo? getProcessingStatus(String prescriptionId) {
    return _processingQueue[prescriptionId];
  }

  // Clear processing queue
  void clearProcessingQueue() {
    _processingQueue.clear();
  }

  // Validate prescription image before upload
  ValidationResult validatePrescriptionImage(File imageFile) {
    if (!imageFile.existsSync()) {
      return ValidationResult(
        isValid: false,
        error: 'Image file does not exist',
      );
    }

    // Check file size (max 10MB)
    final fileSizeInBytes = imageFile.lengthSync();
    final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
    if (fileSizeInMB > 10) {
      return ValidationResult(
        isValid: false,
        error: 'Image file is too large. Maximum size is 10MB.',
      );
    }

    // Check file extension
    final validExtensions = ['.jpg', '.jpeg', '.png'];
    final extension = imageFile.path.toLowerCase().substring(
      imageFile.path.lastIndexOf('.'),
    );

    if (!validExtensions.contains(extension)) {
      return ValidationResult(
        isValid: false,
        error: 'Invalid image format. Please use JPG or PNG.',
      );
    }

    return ValidationResult(isValid: true);
  }

  // Get confidence level description
  String getConfidenceDescription(double confidence) {
    if (confidence >= 0.9) return 'Excellent';
    if (confidence >= 0.8) return 'Very Good';
    if (confidence >= 0.7) return 'Good';
    if (confidence >= 0.6) return 'Fair';
    return 'Poor';
  }

  // Get confidence color for UI
  String getConfidenceColorHex(double confidence) {
    if (confidence >= 0.8) return '#4CAF50'; // Green
    if (confidence >= 0.6) return '#FF9800'; // Orange
    return '#F44336'; // Red
  }

  // Dispose resources
  void dispose() {
    _processingQueue.clear();
  }
}

// Helper classes
class PrescriptionProcessingInfo {
  final String prescriptionId; // Changed to String
  final String status;
  final DateTime uploadTime;
  final double? confidence;
  final bool? aiProcessed;
  final PrescriptionSuggestionsResponse? suggestions;

  PrescriptionProcessingInfo({
    required this.prescriptionId,
    required this.status,
    required this.uploadTime,
    this.confidence,
    this.aiProcessed,
    this.suggestions,
  });

  PrescriptionProcessingInfo copyWith({
    String? status,
    double? confidence,
    bool? aiProcessed,
    PrescriptionSuggestionsResponse? suggestions,
  }) {
    return PrescriptionProcessingInfo(
      prescriptionId: prescriptionId,
      status: status ?? this.status,
      uploadTime: uploadTime,
      confidence: confidence ?? this.confidence,
      aiProcessed: aiProcessed ?? this.aiProcessed,
      suggestions: suggestions ?? this.suggestions,
    );
  }
}

class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult({required this.isValid, this.error});
}
