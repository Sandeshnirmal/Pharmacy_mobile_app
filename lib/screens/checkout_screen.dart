import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/payment_service.dart'; // Use the updated PaymentService
import '../services/order_service.dart'; // Import OrderService
import '../models/payment_result.dart'; // Import PaymentResult
import '../providers/order_provider.dart'; // Assuming you have an OrderProvider
import '../utils/api_logger.dart';
import '../services/auth_service.dart'; // Import AuthService

class CheckoutScreen extends StatefulWidget {
  final double amount;
  final String
  orderId; // This orderId is the backend order ID for which payment is being made

  const CheckoutScreen({
    super.key,
    required this.amount,
    required this.orderId,
  });

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late PaymentService _paymentService;
  late StreamSubscription<PaymentResult> _paymentSubscription;
  bool _isLoading = false;
  Map<String, dynamic>? _currentUser; // To store current user data
  bool _isUserDataLoaded = false; // Track if user data is loaded

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
    _paymentSubscription = _paymentService.onPaymentResult.listen(
      _handlePaymentResult,
    );
    _loadCurrentUser(); // Load user data on init
  }

  Future<void> _loadCurrentUser() async {
    setState(() {
      _isUserDataLoaded = false; // Set to false while loading
    });
    final authService = AuthService();
    _currentUser = await authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _isUserDataLoaded = true; // Set to true once loaded
      });
    }
  }

  @override
  void dispose() {
    _paymentSubscription.cancel();
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> _startPayment() async {
    if (!_isUserDataLoaded) {
      // Ensure user data is loaded before proceeding
      await _loadCurrentUser();
      if (!_isUserDataLoaded) {
        // If still not loaded after awaiting, something is wrong
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User data not loaded. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      ApiLogger.log('Initiating payment for order: ${widget.orderId}');
      ApiLogger.log('Amount: ${widget.amount} INR');
      ApiLogger.log(
        'Current User Data: $_currentUser',
      ); // Log current user data

      // Use the simplified processOrderPayment method
      final processPaymentResponse = await _paymentService.processOrderPayment(
        orderId: widget.orderId,
        amount: widget.amount,
        customerName: _currentUser?['first_name'] ?? 'Guest',
        customerEmail: _currentUser?['email'] ?? 'guest@example.com',
        customerPhone: _currentUser?['phone'] ?? '1234567890',
        description: 'Order #${widget.orderId}',
      );

      if (!processPaymentResponse.isSuccess) {
        ApiLogger.logError(
          'Failed to initiate payment: ${processPaymentResponse.error ?? "Unknown error"}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to initiate payment: ${processPaymentResponse.error ?? "Unknown error"}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }
      // The actual Razorpay payment UI will open, and the result will be handled by _handlePaymentResult via the stream
    } catch (e) {
      ApiLogger.logError('Error initiating payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initiating payment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handlePaymentResult(PaymentResult result) async {
    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      ApiLogger.log('Payment successful: ${result.paymentId}');
      // Payment is successful and verified on backend. Now create the paid order.
      final orderService = OrderService(); // Or get from provider if available

      ApiLogger.log(
        'Attempting to create paid order after successful payment...',
      );

      // TODO: Replace with actual cart data and delivery address from your app's state management
      // For now, using placeholders. You might get this from a CartProvider or by passing it
      // to the CheckoutScreen from the previous screen.
      final Map<String, dynamic> mockCartData = {
        'items': [], // Populate with actual cart items
        'total': widget.amount,
      };
      const String mockDeliveryAddress =
          'User\'s Delivery Address'; // Populate with actual address

      final createPaidOrderResponse = await orderService.createPaidOrder(
        paymentId: result.paymentId!,
        razorpayOrderId: result.orderId!,
        razorpaySignature: result.signature!,
        totalAmount: widget.amount,
        cartData: mockCartData, // Use actual cart data
        deliveryAddress: mockDeliveryAddress, // Use actual delivery address
        paymentMethod: 'Razorpay',
      );

      if (createPaidOrderResponse['success']) {
        ApiLogger.log('Paid order created successfully after payment!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful and order placed!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushReplacementNamed(
            '/order-confirmation',
            arguments: createPaidOrderResponse['order_id'],
          );
        }
      } else {
        ApiLogger.logError(
          'Failed to create paid order after payment: ${createPaidOrderResponse['message']}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment successful, but failed to place order: ${createPaidOrderResponse['message']}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      ApiLogger.logError('Payment failed: ${result.errorMessage}');
      if (mounted) {
        String errorMessage = result.errorMessage ?? 'Payment failed';
        if (result.errorCode == 2) {
          errorMessage = 'Payment was cancelled.';
        } else if (result.errorMessage != null &&
            result.errorMessage!.contains('network')) {
          errorMessage =
              'Network error. Please check your internet connection.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Order ID: ${widget.orderId}'),
                    Text(
                      'Amount: ₹${widget.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Payment Button
            if (_isLoading)
              Column(
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing Payment...'),
                ],
              )
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _startPayment,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Pay Now',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Payment Methods Info
                  const Text(
                    'Supported Payment Methods:',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: const [
                      Chip(label: Text('UPI')),
                      Chip(label: Text('Google Pay')),
                      Chip(label: Text('PhonePe')),
                      Chip(label: Text('Paytm')),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
