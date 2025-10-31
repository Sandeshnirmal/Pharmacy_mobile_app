import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'services/prescription_service.dart';
import 'services/auth_service.dart';
import 'models/cart_model.dart';
import 'models/cart_item.dart';
import 'screens/prescription_tracking_screen.dart'; // Import PrescriptionTrackingScreen

class OrderPrescriptionUploadScreen extends StatefulWidget {
  final Cart? cart;
  final List<CartItem>? prescriptionItems;

  const OrderPrescriptionUploadScreen({
    super.key,
    this.cart,
    this.prescriptionItems,
  });

  @override
  State<OrderPrescriptionUploadScreen> createState() =>
      _OrderPrescriptionUploadScreenState();
}

class _OrderPrescriptionUploadScreenState
    extends State<OrderPrescriptionUploadScreen> {
  final PrescriptionService _prescriptionService = PrescriptionService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isUploading = false;
  bool _isUploaded = false;
  bool _isCancelled = false;
  String? _uploadedPrescriptionId; // To store the prescription ID

  @override
  void dispose() {
    _cleanupTempFiles();
    super.dispose();
  }

  Future<void> _cleanupTempFiles() async {
    if (_selectedImage != null && !_isUploaded) {
      try {
        if (await _selectedImage!.exists()) {
          await _selectedImage!.delete();
        }
      } catch (e) {
        debugPrint('Error cleaning up temp files: $e');
      }
    }
  }

  Future<void> _selectImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);

        // Check file size (max 10MB)
        final fileSize = await imageFile.length();
        if (fileSize > 10 * 1024 * 1024) {
          if (!mounted) return;
          _showToast('Image size should be less than 10MB', Colors.orange);
          return;
        }

        if (!mounted) return;
        setState(() {
          _selectedImage = imageFile;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showToast('Error selecting image: $e', Colors.red);
    }
  }

  Future<void> _uploadPrescription() async {
    if (_selectedImage == null) {
      _showToast('Please select a prescription image first', Colors.orange);
      return;
    }

    if (!mounted) return;
    setState(() {
      _isUploading = true;
      _isCancelled = false;
    });

    try {
      // Validate image format
      final String extension = _selectedImage!.path
          .split('.')
          .last
          .toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'heic'].contains(extension)) {
        throw Exception(
          'Invalid image format. Please use JPG, PNG or HEIC images.',
        );
      }

      final isAuth = await _authService.isAuthenticated();
      if (!mounted) return;

      if (!isAuth) {
        _showToast('Please login to upload prescription', Colors.red);
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Simple upload without AI processing
      final result = await _prescriptionService.uploadPrescriptionSimple(
        _selectedImage!,
      );
      if (!mounted) return;

      if (result.isSuccess) {
        final prescriptionId = result.data!.prescriptionId;
        setState(() {
          _isUploaded = true;
          _isUploading = false;
          _uploadedPrescriptionId = prescriptionId;
        });
        _showToast(
          'Prescription submitted for admin verification! ID: $prescriptionId',
          Colors.green,
        );
        // Redirect to PrescriptionTrackingScreen after successful upload
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PrescriptionTrackingScreen(

              ),
            ),
          );
        }
      } else {
        String errorMsg = result.error ?? 'Failed to upload prescription';
        if (result.statusCode == 401) {
          errorMsg = 'Authentication failed. Please login again.';
        } else if (result.statusCode == 413) {
          errorMsg =
              'Prescription image is too large. Please select a smaller image.';
        }

        setState(() {
          _isUploading = false;
        });
        _showToast(errorMsg, Colors.red);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });
      _showToast('Error uploading prescription: $e', Colors.red);
    }
  }

  void _cancelUpload() {
    if (_isUploading) {
      setState(() {
        _isUploading = false;
        _isCancelled = true;
      });
      _showToast('Upload cancelled', Colors.orange);
    }
  }

  void _showToast(String msg, Color color) {
    Fluttertoast.showToast(
      msg: msg,
      backgroundColor: color,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Upload Prescription'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildPrescriptionItems(),
            const SizedBox(height: 24),
            _buildUploadSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined, color: Colors.teal.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prescription Verification Required',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Upload your prescription for admin verification. Our pharmacist will review and approve your order.',
                  style: TextStyle(fontSize: 14, color: Colors.teal.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );

  }

  Widget _buildPrescriptionItems() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.yellow.shade100,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Text(
              'Disclaimer: The information provided is based on AI-powered extraction and is for informational purposes only. It is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.',
              style: TextStyle(fontSize: 12, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.teal.shade600),
              const SizedBox(width: 8),
              const Text(
                'Upload for Admin Verification',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_selectedImage != null) _buildImagePreview(),

          if (!_isUploaded) _buildUploadButtons(),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_selectedImage!, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildUploadButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUploading
                    ? null
                    : () => _selectImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUploading
                    ? null
                    : () => _selectImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        if (_selectedImage != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _uploadPrescription,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isUploading) ...[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _cancelUpload,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ] else
                    const Text(
                      'Submit for Verification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
