import 'package:flutter/material.dart';
import 'dart:io'; // Import for File
import 'package:fluttertoast/fluttertoast.dart';
import 'models/cart_model.dart';
import 'models/cart_item.dart'; // Import CartItem
import 'services/cart_service.dart';
import 'services/order_service.dart';
import 'services/auth_service.dart';
import 'dart:convert'; // For base64 encoding
import 'LoginScreen.dart';
import 'OrderConfirmationScreen.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'models/user_model.dart'; // Import AddressModel
import 'services/api_service.dart'; // Import ApiService

class CheckoutScreen extends StatefulWidget {
  final Cart cart;

  const CheckoutScreen({super.key, required this.cart});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartService _cartService = CartService();
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService(); // Initialize ApiService
  final TextEditingController _notesController = TextEditingController();

  List<AddressModel> _addresses = []; // Change to AddressModel list
  int _selectedAddressIndex = 0;
  int _selectedPaymentMethod = 0;
  bool _isPlacingOrder = false;
  bool _isLoadingAddresses = true; // New loading state for addresses
  bool _prescriptionRequired = false; // New state for prescription requirement
  File? _uploadedPrescriptionImage; // To store the uploaded image file
  String?
  _uploadedPrescriptionBase64; // To store the base64 string of the image
  String?
  _uploadedPrescriptionImageUrl; // To store the URL if uploaded to backend
  String? _prescriptionStatus; // To store the status after upload/processing

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 1,
      'type': 'Cash on Delivery',
      'icon': Icons.money,
      'description': 'Pay when your order is delivered',
    },
    {
      'id': 2,
      'type': 'UPI',
      'icon': Icons.payment,
      'description': 'Pay using UPI apps',
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _fetchAddresses(); // Fetch addresses on init
    _checkPrescriptionRequirement(); // Check prescription requirement
  }

  Future<void> _checkAuthentication() async {
    final isAuth = await _authService.isAuthenticated();
    if (!isAuth && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _checkPrescriptionRequirement() {
    setState(() {
      _prescriptionRequired = widget.cart.hasRxItems;
    });
  }

  Future<void> _fetchAddresses() async {
    setState(() {
      _isLoadingAddresses = true;
    });

    try {
      final response = await _apiService.getAddresses();
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> addressJson = response['data'];
        setState(() {
          _addresses = addressJson
              .map(
                (json) => AddressModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
          if (_addresses.isNotEmpty) {
            _selectedAddressIndex = _addresses.indexWhere(
              (addr) => addr.isDefault,
            );
            if (_selectedAddressIndex == -1) {
              _selectedAddressIndex =
                  0; // Default to the first address if no default is found
            }
          } else {
            _selectedAddressIndex = -1; // No addresses available
          }
        });
      } else {
        _showErrorToast(response['error'] ?? 'Failed to load addresses');
        setState(() {
          _addresses = [];
          _selectedAddressIndex = -1;
        });
      }
    } catch (e) {
      _showErrorToast('Error fetching addresses: $e');
      setState(() {
        _addresses = [];
        _selectedAddressIndex = -1;
      });
    } finally {
      setState(() {
        _isLoadingAddresses = false;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _uploadPrescription() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _uploadedPrescriptionImage = File(pickedFile.path);
        _prescriptionStatus = 'Ready for submission'; // Set a local status
      });
      _showErrorToast('Prescription image selected!');
    }
  }

  Future<void> _placeOrder() async {
    setState(() {
      _isPlacingOrder = true;
    });

    try {
      if (_prescriptionRequired && _uploadedPrescriptionImage == null) {
        _showErrorToast('Please upload your prescription to proceed.');
        return;
      }

      final selectedAddress = _addresses[_selectedAddressIndex];
      final selectedPayment = _paymentMethods[_selectedPaymentMethod];

      Map<String, dynamic>? prescriptionDetails;
      if (_prescriptionRequired && _uploadedPrescriptionImage != null) {
        final List<int> imageBytes = await _uploadedPrescriptionImage!
            .readAsBytes();
        final String base64Image = base64Encode(imageBytes);
        prescriptionDetails = {
          'prescription_image': base64Image,
          'status': _prescriptionStatus ?? 'Pending verification',
        };
      }

      final orderData = {
        'cart': widget.cart.toJson(),
        'delivery_address': selectedAddress
            .toJson(), // Convert AddressModel to JSON
        'payment_method': selectedPayment['type'],
        'notes': _notesController.text.trim(),
        'prescription_details': prescriptionDetails, // Add prescription details
      };

      // For now, use mock payment data as actual payment integration is outside this task's scope.
      // In a real scenario, payment would be processed here, and its details used below.
      final String paymentId =
          'mock_payment_id_${DateTime.now().millisecondsSinceEpoch}';
      final String razorpayOrderId =
          'mock_razorpay_order_id_${DateTime.now().millisecondsSinceEpoch}';
      final String razorpaySignature = 'mock_razorpay_signature';
      final double totalAmount =
          widget.cart.total; // Assuming cart.total is the final amount

      final result = await _orderService.createPaidOrder(
        paymentId: paymentId,
        razorpayOrderId: razorpayOrderId,
        razorpaySignature: razorpaySignature,
        totalAmount: totalAmount,
        cartData: widget.cart.toJson(),
        deliveryAddress: selectedAddress
            .toJson(), // Convert AddressModel to JSON
        paymentMethod: selectedPayment['type'] == 'Cash on Delivery'
            ? 'COD'
            : 'RAZORPAY', // Map to backend payment methods
        prescriptionDetails: prescriptionDetails, // Pass prescription details
      );

      if (result['success'] == true) {
        // Clear cart after successful order
        await _cartService.clearCart();

        // Navigate to order confirmation
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OrderConfirmationScreen(
                orderId: result['order_id'],
                orderData: result['order'],
              ),
            ),
          );
        }
      } else {
        _showErrorToast(result['message'] ?? 'Failed to place order');
      }
    } catch (e) {
      _showErrorToast('Error placing order: $e');
    } finally {
      setState(() {
        _isPlacingOrder = false;
      });
    }
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            _buildOrderSummary(),
            const SizedBox(height: 24),

            // Delivery Address
            _buildDeliveryAddressSection(),
            const SizedBox(height: 24),

            // Prescription Upload Section (conditionally rendered)
            if (_prescriptionRequired) _buildPrescriptionUploadSection(),
            if (_prescriptionRequired) const SizedBox(height: 24),

            // Payment Method
            _buildPaymentMethodSection(),
            const SizedBox(height: 24),

            // Order Notes
            _buildOrderNotesSection(),
            const SizedBox(height: 24),

            // Price Summary
            _buildPriceSummary(),
            const SizedBox(height: 100), // Space for floating button
          ],
        ),
      ),
      bottomNavigationBar: _buildPlaceOrderButton(),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.cart.items.length} items in your cart',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          ...widget.cart.items
              .take(3)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'x${item.quantity}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
          if (widget.cart.items.length > 3)
            Text(
              '... and ${widget.cart.items.length - 3} more items',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionUploadSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prescription Upload',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          if (_uploadedPrescriptionImage == null)
            Column(
              children: [
                const Text(
                  'Some items in your cart require a prescription. Please upload it.',
                  style: TextStyle(fontSize: 14, color: Colors.red),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _uploadPrescription,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Prescription'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prescription Uploaded:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Image.file(
                  _uploadedPrescriptionImage!,
                  height: 150,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 8),
                Text(
                  'Status: ${_prescriptionStatus ?? 'Pending verification'}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _uploadPrescription,
                    icon: const Icon(Icons.edit),
                    label: const Text('Change Prescription'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: const BorderSide(color: Colors.teal),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Add new address functionality
                  _showAddAddressDialog();
                },
                child: const Text('Add New'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _isLoadingAddresses
              ? const Center(child: CircularProgressIndicator())
              : _addresses.isEmpty
              ? const Center(child: Text('No addresses found. Please add one.'))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _addresses.length,
                  itemBuilder: (context, index) {
                    final address = _addresses[index];
                    final isSelected = _selectedAddressIndex == index;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isSelected ? Colors.teal.shade50 : Colors.white,
                      child: ListTile(
                        leading: Radio<int>(
                          value: index,
                          groupValue: _selectedAddressIndex,
                          onChanged: (value) {
                            setState(() {
                              _selectedAddressIndex = value!;
                            });
                          },
                          activeColor: Colors.teal,
                        ),
                        title: Row(
                          children: [
                            Text(
                              address
                                  .addressLine1, // Using AddressModel property
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (address.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Default',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              address.addressLine1,
                            ), // Using AddressModel property
                            if (address.addressLine2 != null &&
                                address.addressLine2!.isNotEmpty)
                              Text(
                                address.addressLine2!,
                              ), // Using AddressModel property
                            Text(
                              '${address.city}, ${address.state} - ${address.pincode}', // Using AddressModel properties
                            ),
                            // Assuming phone number is not part of AddressModel, or needs to be fetched from UserModel
                            // For now, I'll remove the phone number line as it's not directly in AddressModel
                            // Text('Phone: ${address['phone']}'),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            _selectedAddressIndex = index;
                          });
                        },
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _paymentMethods.length,
            itemBuilder: (context, index) {
              final payment = _paymentMethods[index];
              final isSelected = _selectedPaymentMethod == index;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isSelected ? Colors.teal.shade50 : Colors.white,
                child: ListTile(
                  leading: Radio<int>(
                    value: index,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value!;
                      });
                    },
                    activeColor: Colors.teal,
                  ),
                  title: Row(
                    children: [
                      Icon(payment['icon'], color: Colors.teal, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        payment['type'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  subtitle: Text(payment['description']),
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = index;
                    });
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Notes (Optional)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Any special instructions for delivery...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.teal),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildPriceRow('Subtotal', widget.cart.subtotal),
          if (widget.cart.couponDiscount > 0)
            _buildPriceRow(
              'Discount',
              -widget.cart.couponDiscount,
              isDiscount: true,
            ),
          _buildPriceRow('Delivery Fee', widget.cart.finalShipping),
          _buildPriceRow('Tax', widget.cart.taxAmount),
          const Divider(),
          _buildPriceRow('Total', widget.cart.total, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black87 : Colors.grey[700],
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount
                  ? Colors.green
                  : isTotal
                  ? Colors.black87
                  : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isPlacingOrder ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isPlacingOrder
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Placing Order...', style: TextStyle(fontSize: 16)),
                    ],
                  )
                : Text(
                    'Place Order • ₹${widget.cart.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _showAddAddressDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Address'),
        content: const Text(
          'Address management feature will be implemented with user authentication.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
