import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/order.dart';
import '../models/prescription.dart';

class EnhancedOrderService {
  static const String _tag = 'EnhancedOrderService';

  /// Step 1: Create order after successful payment, before prescription verification
  static Future<Map<String, dynamic>> createPaidOrderForPrescription({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> deliveryAddress,
    required Map<String, dynamic> paymentData,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.createPaidOrderUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'items': items,
          'delivery_address': deliveryAddress,
          'payment_data': paymentData,
        }),
      );

      if (ApiConfig.enableLogging) {
        print('$_tag - Create Paid Order Response: ${response.statusCode}');
        print('$_tag - Response Body: ${response.body}');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to create paid order',
        };
      }
    } catch (e) {
      if (ApiConfig.enableLogging) {
        print('$_tag - Error creating paid order: $e');
      }
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Step 2: Link uploaded prescription to paid order
  static Future<Map<String, dynamic>> linkPrescriptionToOrder({
    required int orderId,
    required int prescriptionId,
    required String token,
  }) async {
    try {
      final url = ApiConfig.linkPrescriptionUrl.replaceAll('{id}', orderId.toString());
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'prescription_id': prescriptionId,
        }),
      );

      if (ApiConfig.enableLogging) {
        print('$_tag - Link Prescription Response: ${response.statusCode}');
        print('$_tag - Response Body: ${response.body}');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to link prescription',
        };
      }
    } catch (e) {
      if (ApiConfig.enableLogging) {
        print('$_tag - Error linking prescription: $e');
      }
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Get orders that have been paid but are waiting for prescription upload
  static Future<Map<String, dynamic>> getPaidOrdersAwaitingPrescription({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.awaitingPrescriptionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (ApiConfig.enableLogging) {
        print('$_tag - Get Awaiting Prescription Orders Response: ${response.statusCode}');
        print('$_tag - Response Body: ${response.body}');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<Order> orders = [];
        if (responseData['orders'] != null) {
          orders = (responseData['orders'] as List)
              .map((orderJson) => Order.fromJson(orderJson))
              .toList();
        }

        return {
          'success': true,
          'orders': orders,
          'total_orders': responseData['total_orders'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to fetch orders',
          'orders': <Order>[],
        };
      }
    } catch (e) {
      if (ApiConfig.enableLogging) {
        print('$_tag - Error fetching awaiting prescription orders: $e');
      }
      return {
        'success': false,
        'error': 'Network error: $e',
        'orders': <Order>[],
      };
    }
  }

  /// Get order tracking information
  static Future<Map<String, dynamic>> getOrderTracking({
    required int orderId,
    required String token,
  }) async {
    try {
      final url = '${ApiConfig.orderTrackingUrl}$orderId/';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (ApiConfig.enableLogging) {
        print('$_tag - Get Order Tracking Response: ${response.statusCode}');
        print('$_tag - Response Body: ${response.body}');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'tracking_data': responseData,
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to fetch tracking information',
        };
      }
    } catch (e) {
      if (ApiConfig.enableLogging) {
        print('$_tag - Error fetching order tracking: $e');
      }
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Get order status history
  static Future<Map<String, dynamic>> getOrderStatusHistory({
    required int orderId,
    required String token,
  }) async {
    try {
      final url = '${ApiConfig.orderStatusHistoryUrl}$orderId/';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (ApiConfig.enableLogging) {
        print('$_tag - Get Order Status History Response: ${response.statusCode}');
        print('$_tag - Response Body: ${response.body}');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'status_history': responseData,
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to fetch status history',
        };
      }
    } catch (e) {
      if (ApiConfig.enableLogging) {
        print('$_tag - Error fetching order status history: $e');
      }
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Track courier shipment
  static Future<Map<String, dynamic>> trackCourierShipment({
    required String trackingNumber,
    String? token,
  }) async {
    try {
      final url = '${ApiConfig.courierTrackingUrl}?tracking_number=$trackingNumber';
      
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (ApiConfig.enableLogging) {
        print('$_tag - Track Courier Shipment Response: ${response.statusCode}');
        print('$_tag - Response Body: ${response.body}');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'tracking_data': responseData,
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to track shipment',
        };
      }
    } catch (e) {
      if (ApiConfig.enableLogging) {
        print('$_tag - Error tracking courier shipment: $e');
      }
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
}
