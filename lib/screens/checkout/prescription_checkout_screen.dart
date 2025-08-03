// Prescription Checkout Screen - Payment First, Then Prescription Upload
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../services/payment_service.dart';
import '../../models/api_response.dart';
import '../../utils/api_logger.dart';
import '../prescription/prescription_verification_screen.dart';

class PrescriptionCheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;

  const PrescriptionCheckoutScreen({
    super.key,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  State<PrescriptionCheckoutScreen> createState() => _PrescriptionCheckoutScreenState();
}

class _PrescriptionCheckoutScreenState extends State<PrescriptionCheckoutScreen> {
  final ApiService _apiService = ApiService();
  final PaymentService _paymentService = PaymentService();
  final ImagePicker _picker = ImagePicker();
  
  File? _prescriptionImage;
  String _selectedPaymentMethod = 'cod';
  bool _isProcessing = false;
  String? _error;
  
  // Address fields
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> _selectPrescriptionImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _prescriptionImage = File(image.path);
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to capture prescription: $e';
      });
      ApiLogger.logError('Prescription capture error: $e');
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _prescriptionImage = File(image.path);
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to select prescription: $e';
      });
      ApiLogger.logError('Prescription selection error: $e');
    }
  }

  Future<void> _processCheckout() async {
    // Validate inputs
    if (_prescriptionImage == null) {
      setState(() {
        _error = 'Please upload prescription image';
      });
      return;
    }

    if (_nameController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please fill all delivery details';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // Step 1: Create pending order (without prescription verification)
      final orderData = {
        'items': widget.cartItems,
        'delivery_address': {
          'name': _nameController.text.trim(),
          'address': _addressController.text.trim(),
          'phone': _phoneController.text.trim(),
        },
        'payment_method': _selectedPaymentMethod,
        'order_type': 'prescription',
        'status': 'pending_payment',
        'total_amount': widget.totalAmount,
      };

      final orderResponse = await _apiService.createPendingOrder(orderData);
      
      if (!orderResponse.isSuccess || orderResponse.data == null) {
        setState(() {
          _error = orderResponse.error ?? 'Failed to create order';
        });
        return;
      }

      final orderId = orderResponse.data!['order_id'];
      final orderNumber = orderResponse.data!['order_number'];

      // Step 2: Process payment
      if (_selectedPaymentMethod == 'razorpay') {
        await _processRazorpayPayment(orderId, orderNumber);
      } else {
        // COD - directly proceed to prescription upload
        await _proceedToPrescrip​tionUpload(orderId, orderNumber);
      }

    } catch (e) {
      setState(() {
        _error = 'Checkout failed: $e';
      });
      ApiLogger.logError('Checkout error: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processRazorpayPayment(int orderId, String orderNumber) async {
    try {
      // Process Razorpay payment
      final paymentResult = await _paymentService.processOrderPayment(
        orderId: orderNumber,
        amount: widget.totalAmount,
        customerName: _nameController.text.trim(),
        customerEmail: 'customer@example.com', // Get from user profile
        customerPhone: _phoneController.text.trim(),
        description: 'Prescription Order #$orderNumber',
      );

      if (paymentResult.isSuccess) {
        // Payment successful, proceed to prescription upload
        await _proceedToPrescrip​tionUpload(orderId, orderNumber);
      } else {
        setState(() {
          _error = paymentResult.error ?? 'Payment failed';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Payment processing failed: $e';
      });
      ApiLogger.logError('Payment error: $e');
    }
  }

  Future<void> _proceedToPrescrip​tionUpload(int orderId, String orderNumber) async {
    try {
      // Convert prescription image to base64
      final bytes = await _prescriptionImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Upload prescription linked to the paid order
      final prescriptionData = {
        'order_id': orderId,
        'image': base64Image,
        'upload_type': 'post_payment_verification',
        'payment_confirmed': true,
      };

      final uploadResponse = await _apiService.uploadPrescriptionForPaidOrder(prescriptionData);
      
      if (uploadResponse.isSuccess && uploadResponse.data != null) {
        final prescriptionId = uploadResponse.data!['prescription_id'];
        
        // Navigate to prescription verification screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PrescriptionVerificationScreen(
                orderId: orderId,
                orderNumber: orderNumber,
                prescriptionId: prescriptionId,
                totalAmount: widget.totalAmount,
              ),
            ),
          );
        }
      } else {
        setState(() {
          _error = uploadResponse.error ?? 'Failed to upload prescription';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Prescription upload failed: $e';
      });
      ApiLogger.logError('Prescription upload error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Checkout'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderSummary(),
            const SizedBox(height: 24),
            _buildPrescriptionUpload(),
            const SizedBox(height: 24),
            _buildDeliveryDetails(),
            const SizedBox(height: 24),
            _buildPaymentMethod(),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _buildErrorCard(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.cartItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item['name']} x ${item['quantity']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    '₹${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )),
            const Divider(),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '₹${widget.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionUpload() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.upload_file, color: Colors.teal, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Upload Prescription',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const Text(
                  ' *',
                  style: TextStyle(color: Colors.red, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Upload your prescription. Verification will happen after payment confirmation.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            if (_prescriptionImage == null) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectPrescriptionImage,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.teal),
                        foregroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('From Gallery'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.teal),
                        foregroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _prescriptionImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectPrescriptionImage,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retake'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.teal),
                        foregroundColor: Colors.teal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Prescription Ready',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryDetails() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.teal, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Delivery Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Delivery Address *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.teal, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            RadioListTile<String>(
              title: const Text('Cash on Delivery (COD)'),
              subtitle: const Text('Pay when your order is delivered'),
              value: 'cod',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
              activeColor: Colors.teal,
            ),
            RadioListTile<String>(
              title: const Text('Online Payment (Razorpay)'),
              subtitle: const Text('Pay now using UPI, Card, or Net Banking'),
              value: 'razorpay',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
              activeColor: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processCheckout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isProcessing
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Processing...'),
                ],
              )
            : Text(
                _selectedPaymentMethod == 'cod' 
                    ? 'Place Order (COD)' 
                    : 'Pay ₹${widget.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16),
              ),
      ),
    );
  }
}
