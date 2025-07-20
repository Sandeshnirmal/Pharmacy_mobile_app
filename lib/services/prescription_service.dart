// Prescription Service for AI Integration in Flutter
import 'dart:io';
import 'dart:async';
import '../models/api_response.dart';
import '../models/prescription_model.dart';
import 'api_service.dart';

class PrescriptionService {
  final ApiService _apiService = ApiService();
  
  // Singleton pattern
  static final PrescriptionService _instance = PrescriptionService._internal();
  factory PrescriptionService() => _instance;
  PrescriptionService._internal();

  // Processing queue to track prescription status
  final Map<int, PrescriptionProcessingInfo> _processingQueue = {};

  // Upload prescription image and start AI processing
  Future<ApiResponse<PrescriptionUploadResponse>> uploadPrescription(File imageFile) async {
    try {
      print('Uploading prescription: ${imageFile.path}');
      
      final result = await _apiService.uploadPrescription(imageFile);
      
      if (result.isSuccess) {
        final response = result.data!;
        
        // Store processing info
        _processingQueue[response.prescriptionId] = PrescriptionProcessingInfo(
          prescriptionId: response.prescriptionId,
          status: 'processing',
          uploadTime: DateTime.now(),
          confidence: response.aiConfidence,
        );

        return ApiResponse.success(response);
      } else {
        return ApiResponse.error(result.error!, result.statusCode);
      }
    } catch (error) {
      print('Prescription upload error: $error');
      return ApiResponse.error('Failed to upload prescription: $error', 0);
    }
  }

  // Check AI processing status
  Future<ApiResponse<PrescriptionStatusResponse>> checkProcessingStatus(int prescriptionId) async {
    try {
      final result = await _apiService.getPrescriptionStatus(prescriptionId);
      
      if (result.isSuccess) {
        final response = result.data!;
        
        // Update processing queue
        if (_processingQueue.containsKey(prescriptionId)) {
          _processingQueue[prescriptionId] = _processingQueue[prescriptionId]!.copyWith(
            status: response.status,
            aiProcessed: response.aiProcessed,
            confidence: response.confidenceScore,
          );
        }

        return ApiResponse.success(response);
      } else {
        return ApiResponse.error(result.error!, result.statusCode);
      }
    } catch (error) {
      print('Status check error: $error');
      return ApiResponse.error('Failed to check status: $error', 0);
    }
  }

  // Get AI medicine suggestions
  Future<ApiResponse<PrescriptionSuggestionsResponse>> getMedicineSuggestions(int prescriptionId) async {
    try {
      final result = await _apiService.getMedicineSuggestions(prescriptionId);
      
      if (result.isSuccess) {
        final suggestions = result.data!;
        
        // Update processing queue
        if (_processingQueue.containsKey(prescriptionId)) {
          _processingQueue[prescriptionId] = _processingQueue[prescriptionId]!.copyWith(
            status: 'completed',
            suggestions: suggestions,
          );
        }

        return ApiResponse.success(suggestions);
      } else {
        return ApiResponse.error(result.error!, result.statusCode);
      }
    } catch (error) {
      print('Get suggestions error: $error');
      return ApiResponse.error('Failed to get medicine suggestions: $error', 0);
    }
  }

  // Wait for AI processing to complete
  Future<ApiResponse<PrescriptionSuggestionsResponse>> waitForProcessing(
    int prescriptionId, {
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
    required int prescriptionId,
    required List<MedicineModel> selectedMedicines,
    required int addressId,
    required String paymentMethod,
    String? specialInstructions,
  }) async {
    try {
      final orderData = {
        'prescription_id': prescriptionId,
        'medicines': selectedMedicines.map((medicine) => {
          'detail_id': medicine.id,
          'quantity': medicine.selectedQuantity,
        }).toList(),
        'address_id': addressId,
        'payment_method': paymentMethod,
        'special_instructions': specialInstructions ?? '',
      };

      final result = await _apiService.createPrescriptionOrder(orderData);
      
      if (result.isSuccess) {
        return ApiResponse.success({'order_id': result.data?.orderId, 'message': 'Order created successfully'});
      } else {
        return ApiResponse.error(result.error!, result.statusCode);
      }
    } catch (error) {
      print('Create order error: $error');
      return ApiResponse.error('Failed to create order: $error', 0);
    }
  }

  // Calculate total price for selected medicines
  double calculateTotalPrice(List<MedicineModel> selectedMedicines) {
    double subtotal = selectedMedicines.fold(0.0, (total, medicine) {
      return total + (medicine.productInfo?.price ?? 0.0) * medicine.selectedQuantity;
    });

    double shipping = subtotal >= 500 ? 0.0 : 50.0;
    double discount = subtotal >= 1000 ? subtotal * 0.1 : 0.0;
    
    return subtotal + shipping - discount;
  }

  // Calculate pricing breakdown
  PricingModel calculatePricing(List<MedicineModel> selectedMedicines) {
    double subtotal = selectedMedicines.fold(0.0, (total, medicine) {
      return total + (medicine.productInfo?.price ?? 0.0) * medicine.selectedQuantity;
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

  // Get processing status from queue
  PrescriptionProcessingInfo? getProcessingStatus(int prescriptionId) {
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
    final extension = imageFile.path.toLowerCase().substring(imageFile.path.lastIndexOf('.'));
    
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
  final int prescriptionId;
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

  ValidationResult({
    required this.isValid,
    this.error,
  });
}
