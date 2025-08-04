// Prescription Verification Screen - Payment First Flow
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';
import '../orders/order_confirmation_screen.dart';

class PrescriptionVerificationScreen extends StatefulWidget {
  final int orderId;
  final String orderNumber;
  final int? prescriptionId; // Nullable since it's set after upload
  final double totalAmount;

  const PrescriptionVerificationScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    this.prescriptionId, // Made optional
    required this.totalAmount,
  });

  @override
  State<PrescriptionVerificationScreen> createState() => _PrescriptionVerificationScreenState();
}

class _PrescriptionVerificationScreenState extends State<PrescriptionVerificationScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  
  String _orderStatus = 'pending_payment'; // Start with pending payment
  String? _verificationNotes;
  bool _isLoading = true;
  String? _error;
  String? _prescriptionImageUrl;
  int? _currentPrescriptionId;
  bool _isPrescriptionUploaded = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _currentPrescriptionId = widget.prescriptionId;
    _isPrescriptionUploaded = widget.prescriptionId != null;
    _loadOrderStatus();
    _startStatusPolling();
  }

  Future<void> _loadOrderStatus() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get order status
      final response = await _apiService.getOrderDetails(widget.orderId);
      
      if (response.isSuccess && response.data != null) {
        final order = response.data!;
        setState(() {
          _orderStatus = order.status ?? 'pending_payment';
          // Check if prescription is uploaded
          if (order.prescriptionId != null && !_isPrescriptionUploaded) {
            _currentPrescriptionId = order.prescriptionId;
            _isPrescriptionUploaded = true;
          }
        });

        // If verified, automatically confirm the order
        if (_orderStatus == 'verified') {
          await _confirmOrder();
        }
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load order status';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading order status: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startStatusPolling() {
    // Poll every 5 seconds for status updates
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _orderStatus != 'confirmed' && _orderStatus != 'cancelled') {
        _loadOrderStatus();
        _startStatusPolling();
      }
    });
  }

  Future<void> _uploadPrescription() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      // Convert image to base64
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Upload prescription for paid order
      final uploadData = {
        'order_id': widget.orderId,
        'image': base64Image,
        'process_with_ai': true,
      };

      final response = await _apiService.uploadPrescriptionForPaidOrder(uploadData);

      if (response.isSuccess && response.data != null) {
        setState(() {
          _currentPrescriptionId = response.data!['prescription_id'];
          _isPrescriptionUploaded = true;
          _orderStatus = 'pending_verification';
          _prescriptionImageUrl = response.data!['image_url'];
        });

        Fluttertoast.showToast(
          msg: 'Prescription uploaded successfully!',
          backgroundColor: Colors.green,
        );
      } else {
        Fluttertoast.showToast(
          msg: response.error ?? 'Failed to upload prescription',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error uploading prescription: $e',
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _confirmOrder() async {
    try {
      final response = await _apiService.confirmPrescriptionOrder(widget.orderId);
      
      if (response.isSuccess) {
        // Navigate to order confirmation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(
              orderId: widget.orderId,
              orderNumber: widget.orderNumber,
              totalAmount: widget.totalAmount,
            ),
          ),
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error confirming order: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderNumber}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadOrderStatus,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 20),
          _buildOrderSummary(),
          const SizedBox(height: 20),
          if (!_isPrescriptionUploaded) _buildUploadSection(),
          if (_isPrescriptionUploaded) _buildVerificationSection(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    IconData statusIcon;
    Color statusColor;
    String statusText;
    String statusDescription;

    switch (_orderStatus) {
      case 'pending_payment':
        statusIcon = Icons.payment;
        statusColor = Colors.orange;
        statusText = 'Payment Confirmed';
        statusDescription = 'Your payment has been confirmed. Please upload your prescription.';
        break;
      case 'pending_verification':
        statusIcon = Icons.hourglass_empty;
        statusColor = Colors.blue;
        statusText = 'Under Review';
        statusDescription = 'Our pharmacist is reviewing your prescription.';
        break;
      case 'verified':
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        statusText = 'Prescription Verified';
        statusDescription = 'Your prescription has been verified and order is being processed.';
        break;
      case 'confirmed':
        statusIcon = Icons.shopping_bag;
        statusColor = Colors.green;
        statusText = 'Order Confirmed';
        statusDescription = 'Your order has been confirmed and will be shipped soon.';
        break;
      default:
        statusIcon = Icons.info;
        statusColor = Colors.grey;
        statusText = 'Processing';
        statusDescription = 'Your order is being processed.';
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(statusIcon, size: 48, color: statusColor),
            const SizedBox(height: 12),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              statusDescription,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Order Number:'),
                Text(
                  widget.orderNumber,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount:'),
                Text(
                  '₹${widget.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upload Prescription',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please take a clear photo of your prescription. Make sure all text is readable.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadPrescription,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt),
              label: Text(_isUploading ? 'Uploading...' : 'Take Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Prescription Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_prescriptionImageUrl != null)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _prescriptionImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.image_not_supported, size: 48),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              _orderStatus == 'pending_verification'
                  ? 'Your prescription is being reviewed by our pharmacist. This usually takes 15-30 minutes.'
                  : _orderStatus == 'verified'
                      ? 'Your prescription has been verified! Your order will be confirmed automatically.'
                      : 'Prescription uploaded successfully.',
              style: const TextStyle(fontSize: 14),
            ),
            if (_verificationNotes != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pharmacist Notes:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_verificationNotes!),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
