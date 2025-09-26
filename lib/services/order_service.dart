import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_service.dart'; // Import ApiService

class OrderService {
  static String get baseUrl => ApiConfig.apiBaseUrl;
  final ApiService _apiService = ApiService(); // Use ApiService for headers

  // Create a pending order on the backend
  Future<Map<String, dynamic>> createPendingOrder({
    required Map<String, dynamic> cartData,
    required Map<String, dynamic> deliveryAddress,
    String paymentMethod = 'COD', // Default to COD for pending
    Map<String, dynamic>? prescriptionDetails,
    required double totalAmount,
    String notes = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${ApiConfig.orderEndpoint}/pending/',
        ), // Use the specific pending order endpoint
        headers: await _apiService.getHeaders(),
        body: json.encode({
          'items': cartData['items'],
          'delivery_address': deliveryAddress,
          'payment_method': paymentMethod,
          'total_amount': totalAmount,
          'notes': notes,
          if (prescriptionDetails != null)
            'prescription_image': prescriptionDetails['prescription_image'],
          if (prescriptionDetails != null)
            'prescription_status': prescriptionDetails['status'],
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'order_id': responseData['order_id'],
          'order_number': responseData['order_number'],
          'order': responseData,
          'message':
              responseData['message'] ?? 'Pending order processed successfully',
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['error'] ??
              responseData['message'] ??
              'Failed to create pending order',
        };
      }
    } catch (e) {
      print('Pending order creation/management error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Finalize an order after successful payment (or for COD)
  Future<Map<String, dynamic>> finalizeOrderWithPaymentDetails({
    required int orderId, // Now requires an existing orderId
    required String paymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
    required double totalAmount,
    required Map<String, dynamic>
    cartData, // Still needed for context, though items are already in pending order
    required Map<String, dynamic> deliveryAddress,
    String paymentMethod = 'RAZORPAY',
    Map<String, dynamic>? prescriptionDetails,
  }) async {
    try {
      // This endpoint should be for confirming/updating an existing order with payment details
      // The backend endpoint `create_paid_order_for_prescription` is suitable for this.
      final response = await http.post(
        Uri.parse(
          ApiConfig.createPaidOrderUrl,
        ), // Use the enhanced paid order endpoint
        headers: await _apiService.getHeaders(),
        body: json.encode({
          'order_id': orderId, // Pass the existing order ID
          'items':
              cartData['items'], // Re-send items for backend validation/consistency
          'delivery_address': deliveryAddress,
          'payment_data': {
            'method': paymentMethod,
            'payment_id': paymentId,
            'razorpay_order_id': razorpayOrderId,
            'razorpay_signature': razorpaySignature,
            'amount': totalAmount,
          },
          if (prescriptionDetails != null)
            'prescription_image_base64':
                prescriptionDetails['prescription_image'],
          if (prescriptionDetails != null)
            'prescription_status': prescriptionDetails['status'],
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'order_id': responseData['order_id'],
          'order': responseData,
          'message': 'Order finalized successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Failed to finalize order',
        };
      }
    } catch (e) {
      print('Order finalization error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get the most recent pending order for the user
  Future<Map<String, dynamic>?> getUserPendingOrder() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.orderEndpoint}/pending-order/'),
        headers: await _apiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return responseData;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching user pending order: $e');
      return null;
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
