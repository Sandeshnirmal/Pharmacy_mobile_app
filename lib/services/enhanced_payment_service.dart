import 'dart:async';
import 'dart:convert';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/payment_result.dart';
import '../utils/api_logger.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart'; // Import ApiService

class EnhancedPaymentService {
  late final Razorpay _razorpay;
  final StreamController<PaymentResult> _paymentController =
      StreamController<PaymentResult>.broadcast();
  late final Completer<PaymentSuccessResponse> _paymentCompleter;

  Stream<PaymentResult> get paymentResult => _paymentController.stream;

  EnhancedPaymentService() {
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
    _paymentController.close();
  }

  Future<ApiResponse<Map<String, dynamic>>> createPaymentOrder({
    required double amount,
    required String currency,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      ApiLogger.log('Creating payment order for amount: $amount');

      final response = await http.post(
        Uri.parse(ApiConfig.createPaymentUrl),
        headers: await ApiService()
            .getHeaders(), // Use ApiService to get authenticated headers
        body: json.encode({
          'amount': (amount * 100).toInt(), // Convert to paise
          'currency': currency,
          'metadata': metadata ?? {},
        }),
      );

      return ApiService().handleResponse(
        response,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      ApiLogger.logError('Payment order creation failed: $e');
      return ApiResponse.error('Network error: $e', 500);
    }
  }

  Future<PaymentSuccessResponse> startPayment({
    required String orderId,
    required double amount,
    required String name,
    required String description,
    required String email,
    required String contact,
  }) {
    _paymentCompleter = Completer<PaymentSuccessResponse>();

    final options = {
      'key': ApiConfig.razorpayKeyId,
      'amount': (amount * 100).toInt(), // Convert to paise
      'name': name,
      'description': description,
      'order_id': orderId,
      'timeout': 180, // 3 minutes timeout
      'prefill': {'contact': contact, 'email': email, 'name': name},
      'external': {
        'wallets': ['paytm', 'phonepe', 'googlepay', 'bhim', 'upi'],
      },
      'theme': {'color': '#009688'},
      'modal': {
        'escape': true,
        'ondismiss': () {
          if (!_paymentCompleter.isCompleted) {
            _paymentController.add(
              PaymentResult(
                success: false,
                errorMessage: 'Payment cancelled by user',
                errorCode: 2, // Custom code for user cancellation
              ),
            );
            _paymentCompleter.completeError('Payment cancelled by user');
          }
        },
      },
    };

    try {
      _razorpay.open(options);
      return _paymentCompleter.future;
    } catch (e) {
      ApiLogger.logError('Error starting payment: $e');
      _paymentCompleter.completeError(e);
      return _paymentCompleter.future;
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    ApiLogger.log('Payment successful: ${response.paymentId}');
    if (!_paymentCompleter.isCompleted) {
      _paymentCompleter.complete(response);
      _paymentController.add(
        PaymentResult(
          success: true,
          paymentId: response.paymentId,
          orderId: response.orderId,
          signature: response.signature,
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ApiLogger.logError('Payment error: ${response.message}');
    if (!_paymentCompleter.isCompleted) {
      _paymentCompleter.completeError(response);
      _paymentController.add(
        PaymentResult(
          success: false,
          errorMessage: response.message ?? 'Payment failed',
          errorCode: response.code ?? 0,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ApiLogger.log('External wallet selected: ${response.walletName}');
    _paymentController.add(
      PaymentResult(
        success: false,
        errorMessage: 'External wallet selected: ${response.walletName}',
        errorCode: 3, // Custom code for external wallet
      ),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    try {
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

      return ApiService().handleResponse(
        response,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse.error('Network error: $e', 500);
    }
  }
}
