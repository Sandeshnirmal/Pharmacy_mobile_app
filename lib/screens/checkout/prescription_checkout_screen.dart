// // Prescription Checkout Screen - Secure Payment Flow
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import 'dart:convert';
// import 'dart:async';
// import 'package:provider/provider.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import '../orders/order_confirmation_screen.dart';
// import '../../utils/api_logger.dart';
// import '../../services/api_service.dart';
// import '../../services/order_service.dart';
// import '../../services/payment_handler_service.dart';
// import '../../services/secure_order_service.dart';
// import '../../services/payment_service.dart';
// import '../../models/cart_item.dart';
// import '../../models/payment_result.dart';
// import '../../providers/auth_provider.dart';
// import '../prescription/prescription_verification_screen.dart';

// class PrescriptionCheckoutScreen extends StatefulWidget {
//   final List<CartItem> cartItems;
//   final double totalAmount;

//   const PrescriptionCheckoutScreen({
//     super.key,
//     required this.cartItems,
//     required this.totalAmount,
//   });

//   @override
//   State<PrescriptionCheckoutScreen> createState() =>
//       _PrescriptionCheckoutScreenState();
// }

// class _PrescriptionCheckoutScreenState
//     extends State<PrescriptionCheckoutScreen> {
//   final ImagePicker _picker = ImagePicker();
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _addressController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();
//   final PageController _pageController = PageController();

//   // Services
//   final _apiService = ApiService();
//   late final OrderService _orderService;
//   late final PaymentHandlerService _paymentHandler;
//   late final SecureOrderService _secureOrderService;
//   late final PaymentService _paymentService;

//   // State
//   String _selectedPaymentMethod = 'razorpay'; // Default to online payment
//   String? _backendOrderIdForPayment;
//   bool _isProcessingOrder = false;
//   File? _prescriptionImage;
//   int _currentStep = 0;

//   // Payment related fields
//   StreamSubscription<PaymentResult>? _paymentSubscription;

//   @override
//   void initState() {
//     super.initState();
//     _orderService = OrderService();
//     _paymentHandler = PaymentHandlerService();
//     _secureOrderService = SecureOrderService();
//     _paymentService = PaymentService();

//     // Listen for payment results
//     _paymentSubscription = _paymentService.onPaymentResult.listen(
//       _handlePaymentResult,
//     );

//     _loadUserData();
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _addressController.dispose();
//     _phoneController.dispose();
//     _pageController.dispose();
//     _paymentSubscription?.cancel();
//     _paymentService.dispose();
//     super.dispose();
//   }

//   Future<void> _loadUserData() async {
//     try {
//       final authProvider = Provider.of<AuthProvider>(context, listen: false);
//       final user = authProvider.user;
//       if (user != null) {
//         setState(() {
//           _nameController.text = '${user.firstName} ${user.lastName}';
//           _phoneController.text = user.phoneNumber ?? '';
//         });
//       }
//     } catch (e) {
//       // Handle error silently
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Prescription Checkout'),
//         backgroundColor: Colors.teal,
//         foregroundColor: Colors.white,
//       ),
//       body: Column(
//         children: [
//           _buildStepIndicator(),
//           Expanded(
//             child: PageView(
//               controller: _pageController,
//               onPageChanged: (index) {
//                 setState(() {
//                   _currentStep = index;
//                 });
//               },
//               physics: const NeverScrollableScrollPhysics(), // Disable swipe
//               children: [
//                 _buildDeliveryDetailsStep(),
//                 _buildPaymentMethodStep(),
//                 _buildPrescriptionUploadStep(),
//                 _buildPaymentConfirmationStep(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStepIndicator() {
//     return Container(
//       padding: const EdgeInsets.all(16.0),
//       child: Row(
//         children: [
//           _buildStepCircle(0, 'Details'),
//           _buildStepLine(0),
//           _buildStepCircle(1, 'Payment'),
//           _buildStepLine(1),
//           _buildStepCircle(2, 'Prescription'),
//           _buildStepLine(2),
//           _buildStepCircle(3, 'Confirm'),
//         ],
//       ),
//     );
//   }

//   Widget _buildStepCircle(int step, String label) {
//     bool isActive = _currentStep >= step;
//     return Expanded(
//       child: Column(
//         children: [
//           Container(
//             width: 30,
//             height: 30,
//             decoration: BoxDecoration(
//               color: isActive ? Colors.teal : Colors.grey.shade300,
//               borderRadius: BorderRadius.circular(15),
//             ),
//             child: Center(
//               child: Text(
//                 '${step + 1}',
//                 style: TextStyle(
//                   color: isActive ? Colors.white : Colors.grey.shade600,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               color: isActive ? Colors.teal : Colors.grey.shade600,
//               fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStepLine(int step) {
//     bool isActive = _currentStep > step;
//     return Expanded(
//       child: Container(
//         height: 2,
//         color: isActive ? Colors.teal : Colors.grey.shade300,
//         margin: const EdgeInsets.only(bottom: 20),
//       ),
//     );
//   }

//   Widget _buildDeliveryDetailsStep() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           _buildOrderSummary(),
//           const SizedBox(height: 20),
//           Card(
//             elevation: 2,
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Delivery Address',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 16),
//                   TextField(
//                     controller: _nameController,
//                     decoration: const InputDecoration(
//                       labelText: 'Full Name',
//                       border: OutlineInputBorder(),
//                       prefixIcon: Icon(Icons.person),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   TextField(
//                     controller: _addressController,
//                     decoration: const InputDecoration(
//                       labelText: 'Complete Address',
//                       border: OutlineInputBorder(),
//                       prefixIcon: Icon(Icons.location_on),
//                     ),
//                     maxLines: 3,
//                   ),
//                   const SizedBox(height: 16),
//                   TextField(
//                     controller: _phoneController,
//                     decoration: const InputDecoration(
//                       labelText: 'Phone Number',
//                       border: OutlineInputBorder(),
//                       prefixIcon: Icon(Icons.phone),
//                     ),
//                     keyboardType: TextInputType.phone,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 30),
//           ElevatedButton(
//             onPressed: _validateDeliveryDetails,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.teal,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12.0),
//               ),
//             ),
//             child: const Text(
//               'Continue to Payment Method',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPaymentMethodStep() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Card(
//             elevation: 2,
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Payment Method',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 16),
//                   RadioListTile<String>(
//                     title: const Text('Cash on Delivery (COD)'),
//                     subtitle: const Text('Pay when your order is delivered'),
//                     value: 'cod',
//                     groupValue: _selectedPaymentMethod,
//                     onChanged: (value) {
//                       setState(() {
//                         _selectedPaymentMethod = value!;
//                       });
//                     },
//                   ),
//                   RadioListTile<String>(
//                     title: const Text('Online Payment'),
//                     subtitle: const Text('Pay securely with Razorpay'),
//                     value: 'online',
//                     groupValue: _selectedPaymentMethod,
//                     onChanged: (value) {
//                       setState(() {
//                         _selectedPaymentMethod = value!;
//                       });
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 30),
//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: () => _goToStep(0),
//                   child: const Text('Back'),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: () => _goToStep(2),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.teal,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                   ),
//                   child: const Text('Continue to Prescription'),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPrescriptionUploadStep() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Card(
//             elevation: 2,
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   const Text(
//                     'Upload Prescription',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 16),
//                   if (_prescriptionImage == null) ...[
//                     Container(
//                       height: 200,
//                       decoration: BoxDecoration(
//                         border: Border.all(
//                           color: Colors.grey.shade300,
//                           width: 2,
//                         ),
//                         borderRadius: BorderRadius.circular(12),
//                         color: Colors.grey.shade50,
//                       ),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.camera_alt,
//                             size: 48,
//                             color: Colors.grey.shade400,
//                           ),
//                           const SizedBox(height: 12),
//                           Text(
//                             'Take a photo of your prescription',
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Colors.grey.shade600,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             'Make sure all text is clearly visible',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.grey.shade500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: ElevatedButton.icon(
//                             onPressed: () =>
//                                 _takePrescriptionPhoto(ImageSource.camera),
//                             icon: const Icon(Icons.camera_alt),
//                             label: const Text('Take Photo'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.teal,
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(vertical: 12),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: ElevatedButton.icon(
//                             onPressed: () =>
//                                 _takePrescriptionPhoto(ImageSource.gallery),
//                             icon: const Icon(Icons.photo_library),
//                             label: const Text('From Gallery'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.grey.shade600,
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(vertical: 12),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ] else ...[
//                     Container(
//                       height: 200,
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.teal, width: 2),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(10),
//                         child: Image.file(
//                           _prescriptionImage!,
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Row(
//                       children: [
//                         Icon(Icons.check_circle, color: Colors.green, size: 20),
//                         const SizedBox(width: 8),
//                         const Text(
//                           'Prescription image captured successfully',
//                           style: TextStyle(
//                             color: Colors.green,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     TextButton.icon(
//                       onPressed: () =>
//                           _takePrescriptionPhoto(ImageSource.camera),
//                       icon: const Icon(Icons.refresh),
//                       label: const Text('Retake Photo'),
//                       style: TextButton.styleFrom(foregroundColor: Colors.teal),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 30),
//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: () => _goToStep(1),
//                   child: const Text('Back'),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: _prescriptionImage != null
//                       ? () => _goToStep(3)
//                       : null,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.teal,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                   ),
//                   child: const Text('Continue to Payment'),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPaymentConfirmationStep() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           _buildOrderSummary(),
//           const SizedBox(height: 20),
//           Card(
//             elevation: 2,
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Order Confirmation',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 16),
//                   _buildConfirmationItem('Name', _nameController.text),
//                   _buildConfirmationItem('Address', _addressController.text),
//                   _buildConfirmationItem('Phone', _phoneController.text),
//                   _buildConfirmationItem(
//                     'Payment Method',
//                     _selectedPaymentMethod.toUpperCase(),
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     children: [
//                       Icon(Icons.check_circle, color: Colors.green, size: 20),
//                       const SizedBox(width: 8),
//                       const Text(
//                         'Prescription uploaded successfully',
//                         style: TextStyle(
//                           color: Colors.green,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 30),
//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: () => _goToStep(2),
//                   child: const Text('Back'),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: _isProcessingOrder ? null : _processOrder,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.teal,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                   ),
//                   child: _isProcessingOrder
//                       ? const SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             valueColor: AlwaysStoppedAnimation<Color>(
//                               Colors.white,
//                             ),
//                           ),
//                         )
//                       : Text(
//                           'Complete Payment • ₹${widget.totalAmount.toStringAsFixed(2)}',
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildConfirmationItem(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 100,
//             child: Text(
//               '$label:',
//               style: const TextStyle(
//                 fontWeight: FontWeight.w600,
//                 color: Colors.grey,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(fontWeight: FontWeight.w500),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOrderSummary() {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Order Summary',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             ...widget.cartItems.map(
//               (item) => Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 4.0),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Expanded(
//                       child: Text(
//                         '${item.name} × ${item.quantity}',
//                         style: const TextStyle(fontSize: 14),
//                       ),
//                     ),
//                     Text(
//                       '₹${(item.price * item.quantity).toStringAsFixed(2)}',
//                       style: const TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const Divider(),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Total Amount:',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 Text(
//                   '₹${widget.totalAmount.toStringAsFixed(2)}',
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.teal,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _goToStep(int step) {
//     setState(() {
//       _currentStep = step;
//     });
//     _pageController.animateToPage(
//       step,
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeInOut,
//     );
//   }

//   void _validateDeliveryDetails() {
//     if (_nameController.text.trim().isEmpty) {
//       _showErrorToast('Please enter your name');
//       return;
//     }
//     if (_addressController.text.trim().isEmpty) {
//       _showErrorToast('Please enter your address');
//       return;
//     }
//     if (_phoneController.text.trim().isEmpty) {
//       _showErrorToast('Please enter your phone number');
//       return;
//     }
//     _goToStep(1);
//   }

//   Future<void> _takePrescriptionPhoto(ImageSource source) async {
//     try {
//       final XFile? image = await _picker.pickImage(
//         source: source,
//         imageQuality: 80,
//         maxWidth: 1024,
//         maxHeight: 1024,
//       );

//       if (image != null) {
//         setState(() {
//           _prescriptionImage = File(image.path);
//         });
//       }
//     } catch (e) {
//       _showErrorToast('Error capturing image: $e');
//     }
//   }

//   void _showErrorToast(String message) {
//     Fluttertoast.showToast(
//       msg: message,
//       backgroundColor: Colors.red,
//       textColor: Colors.white,
//     );
//   }

//   Future<void> _processOrder() async {
//     if (_prescriptionImage == null) {
//       _showErrorToast('Please upload a prescription image.');
//       return;
//     }

//     setState(() {
//       _isProcessingOrder = true;
//     });

//     try {
//       final bytes = await _prescriptionImage!.readAsBytes();
//       final base64Image = base64Encode(bytes);

//       final deliveryAddress = {
//         'name': _nameController.text.trim(),
//         'address': _addressController.text.trim(),
//         'phone': _phoneController.text.trim(),
//       };

//       final cartData = {
//         'items': widget.cartItems
//             .map(
//               (item) => {
//                 'product_id': item.productId,
//                 'quantity': item.quantity,
//                 'price': item.price,
//               },
//             )
//             .toList(),
//         'total': widget.totalAmount,
//       };

//       if (_selectedPaymentMethod == 'cod') {
//         // COD Flow: Create pending order first
//         final orderData = {
//           'items': cartData['items'],
//           'delivery_address': deliveryAddress,
//           'payment_method': 'COD',
//           'total_amount': widget.totalAmount,
//           'order_type': 'prescription',
//           'prescription_image': base64Image,
//         };

//         final result = await _apiService.createPendingOrder(orderData);

//         if (result.isSuccess && result.data != null) {
//           final orderId = result.data!['order_id'];
//           final orderNumber = result.data!['order_number'];
//           final prescriptionId = result.data!['prescription_id'];

//           Fluttertoast.showToast(
//             msg: 'Order created successfully! Order #$orderNumber',
//             toastLength: Toast.LENGTH_LONG,
//             gravity: ToastGravity.BOTTOM,
//             backgroundColor: Colors.green,
//           );

//           if (mounted) {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => PrescriptionVerificationScreen(
//                   orderId: orderId,
//                   orderNumber: orderNumber,
//                   prescriptionId: prescriptionId,
//                   totalAmount: widget.totalAmount,
//                 ),
//               ),
//             );
//           }
//         } else {
//           _showErrorToast(result.error ?? 'Failed to create COD order');
//         }
//       } else if (_selectedPaymentMethod == 'online') {
//         // Online Payment Flow: First create a pending order to get a backend order ID
//         // This order will be confirmed/updated after successful payment
//         final pendingOrderData = {
//           'items': cartData['items'],
//           'delivery_address': deliveryAddress,
//           'payment_method': 'ONLINE_PENDING', // Indicate it's pending payment
//           'total_amount': widget.totalAmount,
//           'order_type': 'prescription',
//           'prescription_image': base64Image,
//         };

//         final pendingOrderResult = await _apiService.createPendingOrder(
//           pendingOrderData,
//         );

//         if (pendingOrderResult.isSuccess && pendingOrderResult.data != null) {
//           _backendOrderIdForPayment = pendingOrderResult.data!['order_id']
//               .toString();
//           ApiLogger.log(
//             'Pending order created for online payment: $_backendOrderIdForPayment',
//           );

//           // Now initiate Razorpay payment using this backend order ID
//           final createPaymentOrderResponse = await _paymentService
//               .createPaymentOrder(
//                 amount: widget.totalAmount,
//                 currency: 'INR',
//                 orderId: _backendOrderIdForPayment!,
//                 metadata: {
//                   'customer_name': _nameController.text.trim(),
//                   'customer_email':
//                       'vjsanthakumar@gmail.com', // Replace with actual user email
//                   'customer_phone': _phoneController.text.trim(),
//                   'prescription_id':
//                       pendingOrderResult.data!['prescription_id'],
//                 },
//               );

//           if (!createPaymentOrderResponse.isSuccess ||
//               createPaymentOrderResponse.data == null) {
//             ApiLogger.logError(
//               'Failed to create Razorpay order: ${createPaymentOrderResponse.error ?? "Unknown error"}',
//             );
//             _showErrorToast(
//               'Failed to initiate online payment: ${createPaymentOrderResponse.error ?? "Unknown error"}',
//             );
//             setState(() {
//               _isProcessingOrder = false;
//             });
//             return;
//           }

//           final razorpayOrderId =
//               createPaymentOrderResponse.data!['razorpay_order_id'];

//           // Get user email from auth provider
//           final authProvider = Provider.of<AuthProvider>(
//             context,
//             listen: false,
//           );
//           final userEmail = "vjsanthakumat@gmail.com";

//           if (userEmail.isEmpty) {
//             _showErrorToast('User email is required for payment');
//             setState(() => _isProcessingOrder = false);
//             return;
//           }

//           try {
//             _paymentService.startPayment(
//               orderId: razorpayOrderId,
//               amount: widget.totalAmount,
//               name: _nameController.text.trim(),
//               description: 'Prescription Order #$_backendOrderIdForPayment',
//               email: userEmail,
//               contact: _phoneController.text.trim(),
//             );
//             // Payment result will be handled by _handlePaymentResult via the stream
//           } catch (e) {
//             ApiLogger.logError('Failed to start payment: $e');
//             _showErrorToast('Failed to start payment. Please try again.');
//             setState(() => _isProcessingOrder = false);
//           }
//         } else {
//           _showErrorToast(
//             pendingOrderResult.error ??
//                 'Failed to create pending order for online payment',
//           );
//         }
//       }
//     } catch (e) {
//       _showErrorToast('Error processing order: $e');
//     } finally {
//       // _isProcessingOrder is set to false in _handlePaymentResult for online payments
//       // For COD, it's set here.
//       if (_selectedPaymentMethod == 'cod') {
//         setState(() {
//           _isProcessingOrder = false;
//         });
//       }
//     }
//   }

//   Map<String, dynamic> _getCartData() {
//     return {
//       'items': widget.cartItems
//           .map(
//             (item) => {
//               'product_id': item.productId,
//               'quantity': item.quantity,
//               'price': item.price,
//             },
//           )
//           .toList(),
//       'total_amount': widget.totalAmount,
//     };
//   }

//   Future<Map<String, dynamic>> _getPrescriptionDetails() async {
//     if (_prescriptionImage == null) {
//       throw Exception('Prescription image is required');
//     }

//     final bytes = await _prescriptionImage!.readAsBytes();
//     final base64Image = base64Encode(bytes);

//     return {'prescription_image': base64Image, 'notes': 'Prescription order'};
//   }

//   void _handlePaymentResult(PaymentResult result) async {
//     try {
//       if (result.success && result.paymentId != null) {
//         ApiLogger.log('Payment successful: ${result.paymentId}');

//         // 1. Verify payment with backend first
//         final verificationResult = await _paymentService.verifyPayment(
//           paymentId: result.paymentId!,
//           orderId: result.orderId!,
//           signature: result.signature!,
//         );

//         if (!verificationResult.isSuccess) {
//           throw Exception(verificationResult.error);
//         }

//         // 2. Create the order only after payment is verified
//         final deliveryAddressMap = {
//           'name': _nameController.text.trim(),
//           'address_line_1': _addressController.text
//               .trim(), // Assuming addressController holds address_line_1
//           'phone': _phoneController.text.trim(),
//           // Add other required fields for delivery_address if available in UI
//           'city': 'Unknown', // Placeholder, ideally from user input
//           'state': 'Unknown', // Placeholder, ideally from user input
//           'pincode': '000000', // Placeholder, ideally from user input
//         };

//         final prescriptionDetailsMap = await _getPrescriptionDetails();
//         // Add a status to prescriptionDetailsMap for the backend
//         prescriptionDetailsMap['status'] = 'pending_review';

//         // final paidOrderResult = await _orderService.createPaidOrder(
//         //   paymentId: result.paymentId!,
//         //   razorpayOrderId: result.orderId!,
//         //   razorpaySignature: result.signature!,
//         //   totalAmount: widget.totalAmount,
//         //   cartData: _getCartData(),
//         //   deliveryAddress: deliveryAddressMap, // Now a Map
//         //   paymentMethod: 'RAZORPAY', // Consistent with backend expectation
//         //   prescriptionDetails: prescriptionDetailsMap,
//         // );

//         // if (paidOrderResult['success'] == true &&
//         //     paidOrderResult['order'] != null) {
//         //   // 3. Navigate to order confirmation on success
//         //   if (mounted) {
//         //     Navigator.pushReplacement(
//         //       context,
//         //       MaterialPageRoute(
//         //         builder: (context) => OrderConfirmationScreen(
//         //           orderId: paidOrderResult['order_id'] as int,
//         //           orderNumber: paidOrderResult['order']['order_number']
//         //               .toString(),
//         //           totalAmount: widget.totalAmount,
//         //         ),
//         //       ),
//         //     );
//         //   }
//         // } else {
//         //   throw Exception(
//         //     paidOrderResult['message'] ?? 'Failed to create order',
//         //   );
//         // }
//       } else {
//         String errorMessage = 'Payment process failed';
//         if (result.errorCode == 2) {
//           errorMessage = 'Payment was cancelled';
//         } else if (result.errorMessage?.contains('network') ?? false) {
//           errorMessage = 'Network error during payment. Please try again.';
//         } else if (result.errorMessage != null) {
//           errorMessage = result.errorMessage!;
//         }
//         throw Exception(errorMessage);
//       }
//     } catch (e) {
//       ApiLogger.logError('Error in payment process: $e');
//       if (mounted) {
//         _showErrorToast(e.toString());
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isProcessingOrder = false);
//       }
//     }
//   }
// }
