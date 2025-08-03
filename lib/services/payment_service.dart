// Payment Service for Razorpay Integration
import 'dart:convert';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../utils/api_logger.dart';
import 'package:http/http.dart' as http;

class PaymentService {
  late Razorpay _razorpay;
  Function(PaymentSuccessResponse)? _onPaymentSuccess;
  Function(PaymentFailureResponse)? _onPaymentError;
  Function(ExternalWalletResponse)? _onExternalWallet;

  PaymentService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  // Initialize payment with order details
  Future<ApiResponse<Map<String, dynamic>>> createPaymentOrder({
    required double amount,
    required String currency,
    required String orderId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      ApiLogger.log('Creating payment order for amount: $amount');

      final response = await http.post(
        Uri.parse(ApiConfig.createPaymentUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'amount': (amount * 100).toInt(), // Convert to paise
          'currency': currency,
          'order_id': orderId,
          'metadata': metadata ?? {},
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          errorData['error'] ?? 'Failed to create payment order',
          response.statusCode,
        );
      }
    } catch (e) {
      ApiLogger.logError('Payment order creation failed: $e');
      return ApiResponse.error('Payment order creation failed: $e', 0);
    }
  }

  // Start Razorpay payment
  void startPayment({
    required String orderId,
    required double amount,
    required String name,
    required String description,
    required String email,
    required String contact,
    Function(PaymentSuccessResponse)? onSuccess,
    Function(PaymentFailureResponse)? onError,
    Function(ExternalWalletResponse)? onExternalWallet,
  }) {
    _onPaymentSuccess = onSuccess;
    _onPaymentError = onError;
    _onExternalWallet = onExternalWallet;

    var options = {
      'key': ApiConfig.razorpayKeyId,
      'amount': (amount * 100).toInt(), // Convert to paise
      'name': 'Pharmacy App',
      'description': description,
      'order_id': orderId,
      'prefill': {
        'contact': contact,
        'email': email,
        'name': name,
      },
      'theme': {
        'color': '#009688', // Teal color matching app theme
      },
      'modal': {
        'ondismiss': () {
          ApiLogger.log('Payment modal dismissed');
        }
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      ApiLogger.logError('Error starting payment: $e');
      if (_onPaymentError != null) {
        _onPaymentError!(PaymentFailureResponse(
          1, // Generic error code
          'Failed to start payment: $e',
          null,
        ));
      }
    }
  }

  // Verify payment on backend
  Future<ApiResponse<Map<String, dynamic>>> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    try {
      ApiLogger.log('Verifying payment: $paymentId');

      final response = await http.post(
        Uri.parse(ApiConfig.verifyPaymentUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'payment_id': paymentId,
          'order_id': orderId,
          'signature': signature,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          errorData['error'] ?? 'Payment verification failed',
          response.statusCode,
        );
      }
    } catch (e) {
      ApiLogger.logError('Payment verification failed: $e');
      return ApiResponse.error('Payment verification failed: $e', 0);
    }
  }

  // Handle payment success
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    ApiLogger.log('Payment successful: ${response.paymentId}');
    if (_onPaymentSuccess != null) {
      _onPaymentSuccess!(response);
    }
  }

  // Handle payment error
  void _handlePaymentError(PaymentFailureResponse response) {
    ApiLogger.logError('Payment failed: ${response.message}');
    if (_onPaymentError != null) {
      _onPaymentError!(response);
    }
  }

  // Handle external wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    ApiLogger.log('External wallet selected: ${response.walletName}');
    if (_onExternalWallet != null) {
      _onExternalWallet!(response);
    }
  }

  // Complete payment flow for an order
  Future<ApiResponse<bool>> processOrderPayment({
    required String orderId,
    required double amount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String description,
  }) async {
    try {
      // Step 1: Create payment order on backend
      final orderResponse = await createPaymentOrder(
        amount: amount,
        currency: 'INR',
        orderId: orderId,
        metadata: {
          'customer_name': customerName,
          'customer_email': customerEmail,
          'customer_phone': customerPhone,
        },
      );

      if (!orderResponse.isSuccess) {
        return ApiResponse.error(orderResponse.error!, orderResponse.statusCode);
      }

      final paymentOrderId = orderResponse.data!['id'];

      // Step 2: Start Razorpay payment
      bool paymentCompleted = false;
      String? paymentId;
      String? signature;

      startPayment(
        orderId: paymentOrderId,
        amount: amount,
        name: customerName,
        description: description,
        email: customerEmail,
        contact: customerPhone,
        onSuccess: (PaymentSuccessResponse response) async {
          paymentId = response.paymentId;
          signature = response.signature;
          paymentCompleted = true;

          // Step 3: Verify payment
          final verificationResponse = await verifyPayment(
            paymentId: response.paymentId!,
            orderId: response.orderId!,
            signature: response.signature!,
          );

          if (verificationResponse.isSuccess) {
            ApiLogger.log('Payment verification successful');
          } else {
            ApiLogger.logError('Payment verification failed');
          }
        },
        onError: (PaymentFailureResponse response) {
          paymentCompleted = true;
          ApiLogger.logError('Payment failed: ${response.message}');
        },
      );

      // Wait for payment completion (this is a simplified approach)
      // In a real app, you'd handle this with proper state management
      return ApiResponse.success(true);

    } catch (e) {
      ApiLogger.logError('Payment processing failed: $e');
      return ApiResponse.error('Payment processing failed: $e', 0);
    }
  }

  // Get payment status
  Future<ApiResponse<Map<String, dynamic>>> getPaymentStatus(String paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/payment/status/$paymentId/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          errorData['error'] ?? 'Failed to get payment status',
          response.statusCode,
        );
      }
    } catch (e) {
      ApiLogger.logError('Get payment status failed: $e');
      return ApiResponse.error('Get payment status failed: $e', 0);
    }
  }
}
