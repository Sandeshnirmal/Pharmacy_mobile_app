// Payment Service for Razorpay Integration
import 'dart:convert';
import 'dart:async';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/payment_result.dart'; // Import the new PaymentResult model
import '../utils/api_logger.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart'; // Import ApiService

class PaymentService {
  late Razorpay _razorpay;
  final _paymentResultController = StreamController<PaymentResult>.broadcast();
  bool _isPaymentProcessing = false; // New flag to prevent duplicate processing

  Stream<PaymentResult> get onPaymentResult => _paymentResultController.stream;

  PaymentService() {
    ApiLogger.log('PaymentService instance created.');
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
    _paymentResultController.close();
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
      ApiLogger.log(
        'Payment order URL: ${ApiConfig.createPaymentUrl}',
      ); // Log the URL being used

      final response = await http.post(
        Uri.parse(ApiConfig.createPaymentUrl),
        headers: await ApiService()
            .getHeaders(), // Use ApiService to get authenticated headers
        body: json.encode({
          'amount': (amount * 100).toInt(), // Convert to paise
          'currency': currency,
          'order_id': orderId,
          'metadata': metadata ?? {},
        }),
      );

      ApiLogger.log(
        'Raw createPaymentOrder response body: ${response.body}',
      ); // Log raw response body

      if (response.statusCode == 200 || response.statusCode == 201) {
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
  }) {
    var options = {
      'key': ApiConfig.razorpayKeyId,
      'amount': (amount * 100).toInt(), // Convert to paise
      'name': 'Pharmacy App',
      'description': description,
      'order_id': orderId,
      'prefill': {'contact': contact, 'email': email, 'name': name},
      'theme': {
        'color': '#009688', // Teal color matching app theme
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      ApiLogger.logError('Error starting payment: $e');
      _paymentResultController.add(
        PaymentResult(
          success: false,
          errorMessage: 'Failed to start payment: $e',
          errorCode: 1, // Generic error code
        ),
      );
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
        headers: await ApiService()
            .getHeaders(), // Use ApiService to get authenticated headers
        body: json.encode({
          'razorpay_payment_id': paymentId,
          'razorpay_order_id': orderId,
          'razorpay_signature': signature,
        }),
      );

      // Use handleResponse from ApiService for consistent error handling,
      // especially for 401 Unauthorized.
      return ApiService().handleResponse(
        response,
        (data) => data,
      );
    } catch (e) {
      ApiLogger.logError('Payment verification failed: $e');
      return ApiResponse.error('Payment verification failed: $e', 0);
    }
  }

  // Handle payment success
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_isPaymentProcessing) {
      ApiLogger.log(
        'Payment success event received, but already processing. Ignoring.',
      );
      return;
    }

    _isPaymentProcessing = true;
    ApiLogger.log('Payment successful: ${response.paymentId}');

    try {
      // Immediately verify payment on backend
      final verificationResponse = await verifyPayment(
        paymentId: response.paymentId!,
        orderId: response.orderId!,
        signature: response.signature!,
      );

      if (verificationResponse.isSuccess) {
        ApiLogger.log('Payment verification successful');
        _paymentResultController.add(
          PaymentResult(
            success: true,
            paymentId: response.paymentId,
            orderId: response.orderId,
            signature: response.signature,
          ),
        );
      } else {
        ApiLogger.logError(
          'Payment verification failed: ${verificationResponse.error}',
        );
        _paymentResultController.add(
          PaymentResult(
            success: false,
            paymentId:
                response.paymentId, // Still provide paymentId for debugging
            orderId: response.orderId,
            signature: response.signature,
            errorMessage: verificationResponse.error,
            errorCode: verificationResponse.statusCode,
          ),
        );
      }
    } catch (e) {
      ApiLogger.logError('Error during payment success handling: $e');
      _paymentResultController.add(
        PaymentResult(
          success: false,
          errorMessage: 'Error during payment success handling: $e',
          errorCode: 1,
        ),
      );
    } finally {
      _isPaymentProcessing = false;
    }
  }

  // Handle payment error
  void _handlePaymentError(PaymentFailureResponse response) {
    ApiLogger.logError('Payment failed: ${response.message}');
    _paymentResultController.add(
      PaymentResult(
        success: false,
        errorMessage: response.message,
        errorCode: response.code,
      ),
    );
  }

  // Handle external wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    ApiLogger.log('External wallet selected: ${response.walletName}');
    // For external wallets, we might need to wait for a callback or poll status
    _paymentResultController.add(
      PaymentResult(
        success: false, // Assume false until confirmed
        errorMessage:
            'External wallet selected: ${response.walletName}. Manual confirmation may be required.',
        errorCode: 3, // Custom code for external wallet
      ),
    );
  }

  // Complete payment flow for an order (simplified, now relies on stream)
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
        return ApiResponse.error(
          orderResponse.error!,
          orderResponse.statusCode,
        );
      }

      ApiLogger.log(
        'Debug: orderResponse.data type: ${orderResponse.data.runtimeType}',
      );
      ApiLogger.log('Debug: orderResponse.data content: ${orderResponse.data}');
      // Ensure orderResponse.data is not null before proceeding
      if (orderResponse.data == null) {
        ApiLogger.logError(
          'createPaymentOrder returned success but data is null.',
        );
        return ApiResponse.error(
          'Failed to get payment order data from backend.',
          0,
        );
      }

      final dynamic rawPaymentOrderId =
          orderResponse.data!['razorpay_order_id'];
      String? paymentOrderId;

      if (rawPaymentOrderId is String && rawPaymentOrderId.isNotEmpty) {
        paymentOrderId = rawPaymentOrderId;
      } else {
        ApiLogger.logError(
          'Extracted razorpay_order_id is not a valid string or is empty. Value: $rawPaymentOrderId, Type: ${rawPaymentOrderId.runtimeType}',
        );
      }

      if (paymentOrderId == null || paymentOrderId.isEmpty) {
        ApiLogger.logError(
          'Razorpay order ID is null or empty after extraction. Cannot start payment. '
          'Final value: $paymentOrderId, Raw value from API: $rawPaymentOrderId',
        );
        return ApiResponse.error(
          'Failed to get Razorpay order ID to start payment. Raw value: $rawPaymentOrderId',
          0,
        );
      }
      ApiLogger.log('Razorpay order ID confirmed as valid: $paymentOrderId');

      // Step 2: Start Razorpay payment
      startPayment(
        orderId: paymentOrderId,
        amount: amount,
        name: customerName,
        description: description,
        email: customerEmail,
        contact: customerPhone,
      );

      // The result will be delivered via the onPaymentResult stream
      return ApiResponse.success(true);
    } catch (e) {
      ApiLogger.logError('Payment processing failed: $e');
      return ApiResponse.error('Payment processing failed: $e', 0);
    }
  }

  // Get payment status
  Future<ApiResponse<Map<String, dynamic>>> getPaymentStatus(
    String paymentId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/payment/status/$paymentId/',
        ), // Already using baseUrl, no change needed here.
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
