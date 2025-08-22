import 'dart:async';
import 'dart:convert';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../utils/api_logger.dart';
import 'package:http/http.dart' as http;

class PaymentHandlerService {
  final _razorpay = Razorpay();
  final _paymentCompleter = Completer<Map<String, dynamic>>();

  PaymentHandlerService() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  // Step 1: Create Payment Order
  Future<Map<String, dynamic>> createPaymentOrder({
    required double amount,
    required String currency,
  }) async {
    try {
      ApiLogger.log('Creating payment order for amount: $amount');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/payment/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'amount': (amount * 100).toInt(), // Convert to paise
          'currency': currency,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create payment order');
      }
    } catch (e) {
      ApiLogger.logError('Payment order creation failed: $e');
      throw Exception('Network error during payment order creation');
    }
  }

  // Step 2: Start Payment Process
  Future<Map<String, dynamic>> startPayment({
    required String orderId,
    required double amount,
    required String name,
    required String email,
    required String contact,
  }) async {
    try {
      final options = {
        'key': ApiConfig.razorpayKeyId,
        'amount': (amount * 100).toInt(),
        'name': name,
        'description': 'Prescription Order',
        'order_id': orderId,
        'prefill': {'contact': contact, 'email': email, 'name': name},
        'theme': {'color': '#009688'},
      };

      _razorpay.open(options);
      return await _paymentCompleter.future;
    } catch (e) {
      ApiLogger.logError('Error starting payment: $e');
      throw Exception('Failed to start payment process');
    }
  }

  // Step 3: Verify Payment
  Future<bool> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/payment/verify/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'razorpay_payment_id': paymentId,
          'razorpay_order_id': orderId,
          'razorpay_signature': signature,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      ApiLogger.logError('Payment verification failed: $e');
      return false;
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (!_paymentCompleter.isCompleted) {
      _paymentCompleter.complete({
        'success': true,
        'paymentId': response.paymentId,
        'orderId': response.orderId,
        'signature': response.signature,
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!_paymentCompleter.isCompleted) {
      _paymentCompleter.completeError({
        'success': false,
        'code': response.code,
        'message': response.message,
      });
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ApiLogger.log('External wallet selected: ${response.walletName}');
  }
}
