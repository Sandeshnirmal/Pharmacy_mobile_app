// Prescription Provider for Flutter Pharmacy App
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/prescription_model.dart';
import '../models/api_response.dart';
import '../services/prescription_service.dart';

class PrescriptionProvider with ChangeNotifier {
  final PrescriptionService _prescriptionService = PrescriptionService();
  
  // State variables
  bool _isUploading = false;
  bool _isProcessing = false;
  bool _isCreatingOrder = false;
  String? _error;
  
  // Prescription data
  PrescriptionUploadResponse? _uploadResponse;
  PrescriptionSuggestionsResponse? _suggestions;
  List<MedicineModel> _selectedMedicines = [];
  PricingModel? _pricing;

  // Getters
  bool get isUploading => _isUploading;
  bool get isProcessing => _isProcessing;
  bool get isCreatingOrder => _isCreatingOrder;
  String? get error => _error;
  PrescriptionUploadResponse? get uploadResponse => _uploadResponse;
  PrescriptionSuggestionsResponse? get suggestions => _suggestions;
  List<MedicineModel> get selectedMedicines => _selectedMedicines;
  PricingModel? get pricing => _pricing;

  bool get hasUploadedPrescription => _uploadResponse != null;
  bool get hasSuggestions => _suggestions != null;
  bool get hasSelectedMedicines => _selectedMedicines.isNotEmpty;

  // Upload prescription image
  Future<bool> uploadPrescription(File imageFile) async {
    _setUploading(true);
    _clearError();

    try {
      // Validate image first
      final validation = _prescriptionService.validatePrescriptionImage(imageFile);
      if (!validation.isValid) {
        _setError(validation.error!);
        _setUploading(false);
        return false;
      }

      final result = await _prescriptionService.uploadPrescription(imageFile);
      
      if (result.isSuccess) {
        _uploadResponse = result.data;
        _setUploading(false);
        
        // Start processing automatically
        return await _waitForProcessing();
      } else {
        _setError(result.error!);
        _setUploading(false);
        return false;
      }
    } catch (e) {
      _setError('Upload failed: $e');
      _setUploading(false);
      return false;
    }
  }

  // Wait for AI processing to complete
  Future<bool> _waitForProcessing() async {
    if (_uploadResponse == null) return false;

    _setProcessing(true);
    _clearError();

    try {
      final result = await _prescriptionService.waitForProcessing(
        _uploadResponse!.prescriptionId,
        maxWaitTime: Duration(seconds: 30),
      );

      if (result.isSuccess) {
        _suggestions = result.data;
        _updateSelectedMedicines();
        _calculatePricing();
        _setProcessing(false);
        return true;
      } else {
        _setError(result.error!);
        _setProcessing(false);
        return false;
      }
    } catch (e) {
      _setError('Processing failed: $e');
      _setProcessing(false);
      return false;
    }
  }

  // Manually refresh suggestions
  Future<bool> refreshSuggestions() async {
    if (_uploadResponse == null) return false;

    _setProcessing(true);
    _clearError();

    try {
      final result = await _prescriptionService.getMedicineSuggestions(
        _uploadResponse!.prescriptionId,
      );

      if (result.isSuccess) {
        _suggestions = result.data;
        _updateSelectedMedicines();
        _calculatePricing();
        _setProcessing(false);
        return true;
      } else {
        _setError(result.error!);
        _setProcessing(false);
        return false;
      }
    } catch (e) {
      _setError('Refresh failed: $e');
      _setProcessing(false);
      return false;
    }
  }

  // Update selected medicines (auto-select available ones)
  void _updateSelectedMedicines() {
    if (_suggestions == null) return;

    _selectedMedicines = _suggestions!.medicines
        .where((medicine) => medicine.isAvailable && medicine.productInfo != null)
        .map((medicine) => medicine.copyWith(selectedQuantity: 1))
        .toList();
    
    notifyListeners();
  }

  // Toggle medicine selection
  void toggleMedicineSelection(MedicineModel medicine) {
    if (!medicine.isAvailable || medicine.productInfo == null) {
      _setError('This medicine is not available for order');
      return;
    }

    final index = _selectedMedicines.indexWhere((m) => m.id == medicine.id);
    
    if (index >= 0) {
      // Remove from selection
      _selectedMedicines.removeAt(index);
    } else {
      // Add to selection
      _selectedMedicines.add(medicine.copyWith(selectedQuantity: 1));
    }
    
    _calculatePricing();
    notifyListeners();
  }

  // Update medicine quantity
  void updateMedicineQuantity(int medicineId, int quantity) {
    if (quantity < 1) return;

    final index = _selectedMedicines.indexWhere((m) => m.id == medicineId);
    if (index >= 0) {
      _selectedMedicines[index] = _selectedMedicines[index].copyWith(
        selectedQuantity: quantity,
      );
      _calculatePricing();
      notifyListeners();
    }
  }

  // Calculate pricing for selected medicines
  void _calculatePricing() {
    if (_selectedMedicines.isEmpty) {
      _pricing = null;
      return;
    }

    _pricing = _prescriptionService.calculatePricing(_selectedMedicines);
    notifyListeners();
  }

  // Create order from selected medicines
  Future<bool> createOrder({
    required int addressId,
    required String paymentMethod,
    String? specialInstructions,
  }) async {
    if (_uploadResponse == null || _selectedMedicines.isEmpty) {
      _setError('No prescription or medicines selected');
      return false;
    }

    _setCreatingOrder(true);
    _clearError();

    try {
      final result = await _prescriptionService.createOrderFromPrescription(
        prescriptionId: _uploadResponse!.prescriptionId,
        selectedMedicines: _selectedMedicines,
        addressId: addressId,
        paymentMethod: paymentMethod,
        specialInstructions: specialInstructions,
      );

      if (result.isSuccess) {
        _setCreatingOrder(false);
        // Clear current prescription data after successful order
        _clearPrescriptionData();
        return true;
      } else {
        _setError(result.error!);
        _setCreatingOrder(false);
        return false;
      }
    } catch (e) {
      _setError('Order creation failed: $e');
      _setCreatingOrder(false);
      return false;
    }
  }

  // Check if medicine is selected
  bool isMedicineSelected(int medicineId) {
    return _selectedMedicines.any((m) => m.id == medicineId);
  }

  // Get selected quantity for a medicine
  int getSelectedQuantity(int medicineId) {
    final medicine = _selectedMedicines.firstWhere(
      (m) => m.id == medicineId,
      orElse: () => MedicineModel(
        id: 0,
        medicineName: '',
        confidenceScore: 0.0,
        isAvailable: false,
      ),
    );
    return medicine.id != 0 ? medicine.selectedQuantity : 0;
  }

  // Get confidence description
  String getConfidenceDescription(double confidence) {
    return _prescriptionService.getConfidenceDescription(confidence);
  }

  // Get confidence color
  String getConfidenceColorHex(double confidence) {
    return _prescriptionService.getConfidenceColorHex(confidence);
  }

  // Clear prescription data
  void _clearPrescriptionData() {
    _uploadResponse = null;
    _suggestions = null;
    _selectedMedicines.clear();
    _pricing = null;
    notifyListeners();
  }

  // Clear all data (for new prescription)
  void clearAll() {
    _clearPrescriptionData();
    _clearError();
  }

  // Clear error
  void clearError() {
    _clearError();
  }

  // Private helper methods
  void _setUploading(bool uploading) {
    _isUploading = uploading;
    notifyListeners();
  }

  void _setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  void _setCreatingOrder(bool creating) {
    _isCreatingOrder = creating;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _prescriptionService.dispose();
    super.dispose();
  }
}
