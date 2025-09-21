import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_service.dart'; // Import ApiService

class OrderService {
  static String get baseUrl => ApiConfig.apiBaseUrl;
  final ApiService _apiService = ApiService(); // Use ApiService for headers

  // Create a paid order after successful payment
  Future<Map<String, dynamic>> createPaidOrder({
    required String paymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
    required double totalAmount,
    required Map<String, dynamic> cartData,
    required Map<String, dynamic> deliveryAddress, // Changed to Map
    String paymentMethod = 'RAZORPAY', // Default to RAZORPAY for consistency
    Map<String, dynamic>?
    prescriptionDetails, // Optional for prescription orders
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/order/pending/'),
        headers: await _apiService.getHeaders(), // Use ApiService for headers
        body: json.encode({
          'items': cartData['items'], // Backend expects 'items' directly
          'delivery_address': deliveryAddress, // Now a Map
          'payment_data': {
            'method': paymentMethod,
            'payment_id': paymentId,
            'razorpay_order_id': razorpayOrderId,
            'razorpay_signature': razorpaySignature,
            'amount': totalAmount, // Amount should be part of payment_data
          },
          if (prescriptionDetails != null)
            'prescription_image_base64':
                prescriptionDetails['prescription_image'], // Pass base64 image
          if (prescriptionDetails != null)
            'prescription_status':
                prescriptionDetails['status'], // Pass prescription status
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'order_id':
              responseData['order_id'], // Use 'order_id' from backend response
          'order': responseData, // Pass the whole response for other details
          'message': 'Paid order placed successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Failed to create paid order',
        };
      }
    } catch (e) {
      print('Paid order creation error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get order details
  Future<Map<String, dynamic>?> getOrderDetails(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/order/orders/$orderId/'),
        headers: await _apiService.getHeaders(), // Use ApiService for headers
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching order details: $e');
      return null;
    }
  }

  // Get user orders
  Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/order/orders/'),
        headers: await _apiService.getHeaders(), // Use ApiService for headers
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['results'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error fetching user orders: $e');
      return [];
    }
  }

  // Cancel order
  Future<bool> cancelOrder(int orderId, String reason) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/order/orders/$orderId/cancel/'),
        headers: await _apiService.getHeaders(), // Use ApiService for headers
        body: json.encode({'cancellation_reason': reason}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error cancelling order: $e');
      return false;
    }
  }

  // Track order
  Future<Map<String, dynamic>?> trackOrder(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/order/orders/$orderId/track/'),
        headers: await _apiService.getHeaders(), // Use ApiService for headers
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error tracking order: $e');
      return null;
    }
  }

  // Process payment (mock implementation)
  Future<Map<String, dynamic>> processPayment({
    required int orderId,
    required String paymentMethod,
    required double amount,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 3));

      // Mock payment success
      return {
        'success': true,
        'transaction_id': 'TXN${DateTime.now().millisecondsSinceEpoch}',
        'payment_status': 'Success',
        'amount': amount,
        'payment_method': paymentMethod,
      };
    } catch (e) {
      return {'success': false, 'error': 'Payment processing failed: $e'};
    }
  }

  // Get order status updates
  Future<List<Map<String, dynamic>>> getOrderStatusUpdates(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/order/orders/$orderId/status-updates/'),
        headers: await _apiService.getHeaders(), // Use ApiService for headers
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['updates'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error fetching status updates: $e');
      return [];
    }
  }

  // Estimate delivery time
  DateTime estimateDeliveryTime({
    required String deliveryType,
    required String location,
  }) {
    final now = DateTime.now();

    switch (deliveryType.toLowerCase()) {
      case 'express':
        return now.add(const Duration(hours: 2));
      case 'same_day':
        return now.add(const Duration(hours: 6));
      case 'standard':
      default:
        return now.add(const Duration(days: 1));
    }
  }

  // Calculate delivery fee
  double calculateDeliveryFee({
    required double orderAmount,
    required String deliveryType,
    required String location,
  }) {
    if (orderAmount >= 500) {
      return 0.0; // Free delivery for orders above ₹500
    }

    switch (deliveryType.toLowerCase()) {
      case 'express':
        return 100.0;
      case 'same_day':
        return 50.0;
      case 'standard':
      default:
        return 25.0;
    }
  }
}
