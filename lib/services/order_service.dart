import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OrderService {
  static const String baseUrl = 'http://192.168.129.6:8001/api';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Create order
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      final response = await http.post(
        Uri.parse('$baseUrl/orders/create/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(orderData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'order_id': responseData['id'],
          'order': responseData,
          'message': 'Order placed successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Failed to create order',
        };
      }
    } catch (e) {
      print('Order creation error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get order details
  Future<Map<String, dynamic>?> getOrderDetails(int orderId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
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
      final token = await _storage.read(key: 'auth_token');
      
      final response = await http.get(
        Uri.parse('$baseUrl/orders/my-orders/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
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
      final token = await _storage.read(key: 'auth_token');
      
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/cancel/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'cancellation_reason': reason,
        }),
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
      final token = await _storage.read(key: 'auth_token');
      
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId/track/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
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

  // Mock order creation for demo purposes
  Future<Map<String, dynamic>> mockCreateOrder(Map<String, dynamic> orderData) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    // Generate mock order ID
    final orderId = DateTime.now().millisecondsSinceEpoch;

    // Convert cart items to order item structure
    final cartItems = orderData['cart']['items'] as List<dynamic>;
    final orderItems = cartItems.map((cartItem) => {
      'id': DateTime.now().millisecondsSinceEpoch + cartItems.indexOf(cartItem),
      'product': {
        'id': cartItem['product_id'],
        'name': cartItem['name'],
        'manufacturer': cartItem['manufacturer'],
        'strength': cartItem['strength'],
        'form': cartItem['form'],
        'price': cartItem['price'],
        'mrp': cartItem['mrp'],
        'imageUrl': cartItem['image_url'],
        'requiresPrescription': cartItem['requires_prescription'],
        'displayName': cartItem['strength'] != null && cartItem['form'] != null
            ? '${cartItem['name']} ${cartItem['strength']} ${cartItem['form']}'
            : cartItem['name'],
      },
      'quantity': cartItem['quantity'],
      'price': cartItem['price'],
      'totalPrice': cartItem['price'] * cartItem['quantity'],
    }).toList();

    return {
      'success': true,
      'order_id': orderId,
      'order': {
        'id': orderId,
        'order_number': 'ORD${orderId.toString().substring(8)}',
        'status': 'Confirmed',
        'total_amount': orderData['cart']['total'],
        'delivery_address': orderData['delivery_address'],
        'payment_method': orderData['payment_method'],
        'estimated_delivery': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        'items': orderItems,
        'created_at': DateTime.now().toIso8601String(),
      },
      'message': 'Order placed successfully',
    };
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
      return {
        'success': false,
        'error': 'Payment processing failed: $e',
      };
    }
  }

  // Get order status updates
  Future<List<Map<String, dynamic>>> getOrderStatusUpdates(int orderId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId/status-updates/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
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

  // Mock status updates for demo
  List<Map<String, dynamic>> getMockStatusUpdates() {
    return [
      {
        'status': 'Order Confirmed',
        'description': 'Your order has been confirmed and is being prepared',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'icon': 'check_circle',
      },
      {
        'status': 'Prescription Verified',
        'description': 'Your prescription has been verified by our pharmacist',
        'timestamp': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'icon': 'verified',
      },
      {
        'status': 'Order Packed',
        'description': 'Your medicines have been packed and ready for dispatch',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
        'icon': 'inventory',
      },
      {
        'status': 'Out for Delivery',
        'description': 'Your order is out for delivery',
        'timestamp': DateTime.now().toIso8601String(),
        'icon': 'local_shipping',
      },
    ];
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
