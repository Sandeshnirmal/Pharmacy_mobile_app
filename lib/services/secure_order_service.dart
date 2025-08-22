import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/api_logger.dart';
import '../utils/secure_storage.dart';

class SecureOrderService {
  final storage = SecureStorage();

  // Create order only after payment verification
  Future<Map<String, dynamic>> createVerifiedOrder({
    required String paymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
    required double totalAmount,
    required Map<String, dynamic> cartData,
    required String deliveryAddress,
    required Map<String, dynamic>? prescriptionDetails,
  }) async {
    try {
      final token = await storage.read(key: 'auth_token');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/orders/create-verified/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'payment_id': paymentId,
          'razorpay_order_id': razorpayOrderId,
          'razorpay_signature': razorpaySignature,
          'total_amount': totalAmount,
          'cart_data': cartData,
          'delivery_address': deliveryAddress,
          'payment_method': 'razorpay',
          'prescription_details': prescriptionDetails,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        ApiLogger.log(
          'Order created successfully: ${responseData['order_id']}',
        );
        return {
          'success': true,
          'order_id': responseData['order_id'],
          'order': responseData,
        };
      } else {
        throw Exception(responseData['error'] ?? 'Failed to create order');
      }
    } catch (e) {
      ApiLogger.logError('Order creation error: $e');
      throw Exception('Failed to create order: $e');
    }
  }
}
