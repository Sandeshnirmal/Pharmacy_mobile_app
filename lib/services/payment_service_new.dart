import 'dart:async';
import 'dart:convert';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../utils/api_logger.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class PaymentService {
  late Razorpay _razorpay;
  final _paymentCompleter = Completer<PaymentSuccessResponse>();

  PaymentService() {
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
  }

  Future<PaymentSuccessResponse> startPayment({
    required String orderId,
    required double amount,
    required String name,
    required String description,
    required String email,
    required String contact,
  }) {
    final options = {
      'key': ApiConfig.razorpayKeyId,
      'amount': (amount * 100).toInt(),
      'name': name,
      'description': description,
      'order_id': orderId,
      'timeout': 180, // 3 minutes timeout
      'prefill': {'contact': contact, 'email': email, 'name': name},
      'external': {
        'wallets': ['paytm', 'phonepe', 'googlepay', 'bhim', 'upi'],
      },
      'config': {
        'display': {
          'blocks': {
            'upi': {'preferred': true, 'position': 1},
            'wallets': {'preferred': false, 'position': 2},
          },
          'sequence': ['block.upi', 'block.wallets'],
          'preferences': {'show_default_blocks': true},
        },
      },
      'theme': {'color': '#009688', 'backdrop_color': '#ffffff'},
    };

    try {
      _razorpay.open(options);
      return _paymentCompleter.future;
    } catch (e) {
      ApiLogger.logError('Payment start failed: $e');
      throw Exception('Failed to start payment: $e');
    }
  }

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
          'amount': (amount * 100).toInt(),
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

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    ApiLogger.log('Payment successful: ${response.paymentId}');
    if (!_paymentCompleter.isCompleted) {
      _paymentCompleter.complete(response);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ApiLogger.logError('Payment failed: ${response.message}');
    if (!_paymentCompleter.isCompleted) {
      _paymentCompleter.completeError(
        Exception(response.message ?? 'Payment failed'),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ApiLogger.log('External wallet selected: ${response.walletName}');
  }
}
