// API Service for Flutter Pharmacy App
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/user_model.dart';
import '../models/prescription_model.dart';
import '../models/product_model.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;
  static int get timeoutDuration => ApiConfig.timeoutDuration;
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // HTTP client with timeout
  final http.Client _client = http.Client();

  // Secure storage for tokens
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Token management
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  Future<void> setTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: 'access_token', value: accessToken);
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
  }

  // Get headers with authentication
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Token $token';  // Django TokenAuthentication uses 'Token' not 'Bearer'
      }
    }

    return headers;
  }

  // Handle HTTP response
  ApiResponse<T> _handleResponse<T>(http.Response response, T Function(Map<String, dynamic>) fromJson) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        return ApiResponse.success(fromJson(data));
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? errorData['detail'] ?? 'Request failed';
        return ApiResponse.error(errorMessage, response.statusCode);
      }
    } catch (e) {
      return ApiResponse.error('Failed to parse response: $e', response.statusCode);
    }
  }

  // Authentication APIs
  Future<ApiResponse<UserModel>> login(String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: await _getHeaders(includeAuth: false),
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(Duration(milliseconds: timeoutDuration));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await setTokens(data['access'], data['refresh']);

        // Get user profile from response data
        final userData = data['user'];
        final user = UserModel.fromJson(userData);
        return ApiResponse.success(user);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['detail'] ?? 'Login failed';
        return ApiResponse.error(errorMessage, response.statusCode);
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  Future<ApiResponse<UserModel>> getUserProfile() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/user/profile/'),
        headers: await _getHeaders(),
      ).timeout(Duration(milliseconds: timeoutDuration));

      return _handleResponse(response, (data) => UserModel.fromJson(data));
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Prescription APIs

  // Simple prescription upload for order verification (no AI processing)
  Future<ApiResponse<bool>> uploadPrescriptionForOrder(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.prescriptionForOrderUrl),
      );

      // Add headers
      final headers = await _getHeaders();
      request.headers.addAll(headers);

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath('prescription_image', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(true);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          errorData['error'] ?? 'Upload failed',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Full prescription upload with AI processing (for medicine discovery)
  Future<ApiResponse<PrescriptionUploadResponse>> uploadPrescription(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.prescriptionUploadUrl),
      );

      // Add headers
      final headers = await _getHeaders();
      request.headers.addAll(headers);

      // Add file
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ));

      final streamedResponse = await request.send().timeout(Duration(milliseconds: timeoutDuration * 3));
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response, (data) => PrescriptionUploadResponse.fromJson(data));
    } catch (e) {
      return ApiResponse.error('Upload failed: $e', 0);
    }
  }

  Future<ApiResponse<PrescriptionStatusResponse>> getPrescriptionStatus(int prescriptionId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/prescription/mobile/status/$prescriptionId/'),
        headers: await _getHeaders(),
      ).timeout(Duration(milliseconds: timeoutDuration));

      return _handleResponse(response, (data) => PrescriptionStatusResponse.fromJson(data));
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  Future<ApiResponse<PrescriptionSuggestionsResponse>> getMedicineSuggestions(int prescriptionId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/prescription/mobile/suggestions/$prescriptionId/'),
        headers: await _getHeaders(),
      ).timeout(Duration(milliseconds: timeoutDuration));

      return _handleResponse(response, (data) => PrescriptionSuggestionsResponse.fromJson(data));
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  Future<ApiResponse<OrderResponse>> createPrescriptionOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.prescriptionCreateOrderUrl),
        headers: await _getHeaders(),
        body: json.encode(orderData),
      ).timeout(Duration(milliseconds: timeoutDuration));

      return _handleResponse(response, (data) => OrderResponse.fromJson(data));
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Product APIs
  Future<ApiResponse<List<ProductModel>>> getProducts({Map<String, String>? queryParams}) async {
    try {
      final uri = Uri.parse(ApiConfig.productsUrl).replace(queryParameters: queryParams);
      
      final response = await _client.get(
        uri,
        headers: await _getHeaders(),
      ).timeout(Duration(milliseconds: timeoutDuration));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        if (data is List) {
          final list = data.map((item) => ProductModel.fromJson(item as Map<String, dynamic>)).toList();
          return ApiResponse.success(list);
        } else if (data is Map && data.containsKey('results')) {
          final results = data['results'] as List;
          final list = results.map((item) => ProductModel.fromJson(item as Map<String, dynamic>)).toList();
          return ApiResponse.success(list);
        } else {
          return ApiResponse.error('Invalid response format', response.statusCode);
        }
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? errorData['detail'] ?? 'Request failed';
        return ApiResponse.error(errorMessage, response.statusCode);
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Search products
  Future<ApiResponse<List<ProductModel>>> searchProducts(String query) async {
    return getProducts(queryParams: {'search': query});
  }

  // Get prescription-based products for search
  Future<ApiResponse<List<ProductModel>>> getPrescriptionProducts(int prescriptionId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/prescription/mobile/products/$prescriptionId/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> productsJson = data['products'];
          final products = productsJson.map((json) => ProductModel(
            id: json['id'],
            name: json['name'],
            manufacturer: json['manufacturer'],
            price: json['price'].toDouble(),
            mrp: json['mrp'].toDouble(),
            imageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400',
            description: json['extracted_medicine'] ?? 'Prescription medicine',
            genericName: json['extracted_medicine'],
            requiresPrescription: json['is_prescription_required'] ?? true,
            stockQuantity: json['stock_quantity'] ?? 0,
            isActive: json['in_stock'] ?? false,
          )).toList();

          return ApiResponse.success(products);
        } else {
          return ApiResponse.error(data['error'] ?? 'Failed to get prescription products', response.statusCode);
        }
      } else {
        return ApiResponse.error('HTTP ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Get orders
  Future<ApiResponse<List<OrderModel>>> getOrders() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.ordersUrl),
        headers: await _getHeaders(),
      ).timeout(Duration(milliseconds: timeoutDuration));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        if (data is List) {
          final list = data.map((item) => OrderModel.fromJson(item as Map<String, dynamic>)).toList();
          return ApiResponse.success(list);
        } else if (data is Map && data.containsKey('results')) {
          final results = data['results'] as List;
          final list = results.map((item) => OrderModel.fromJson(item as Map<String, dynamic>)).toList();
          return ApiResponse.success(list);
        } else {
          return ApiResponse.error('Invalid response format', response.statusCode);
        }
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? errorData['detail'] ?? 'Request failed';
        return ApiResponse.error(errorMessage, response.statusCode);
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Get order details
  Future<ApiResponse<OrderModel>> getOrderDetails(int orderId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/order/orders/$orderId/'),
        headers: await _getHeaders(),
      ).timeout(Duration(milliseconds: timeoutDuration));

      return _handleResponse(response, (data) => OrderModel.fromJson(data));
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Register user
  Future<ApiResponse<Map<String, dynamic>>> register(Map<String, dynamic> userData) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/user/register/'),
        headers: await _getHeaders(includeAuth: false),
        body: json.encode(userData),
      ).timeout(Duration(milliseconds: timeoutDuration));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        return ApiResponse.success(data);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? errorData['detail'] ?? 'Registration failed';
        return ApiResponse.error(errorMessage, response.statusCode);
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Update user profile
  Future<ApiResponse<UserModel>> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/user/profile/'),
        headers: await _getHeaders(),
        body: json.encode(profileData),
      ).timeout(Duration(milliseconds: timeoutDuration));

      return _handleResponse(response, (data) => UserModel.fromJson(data));
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Logout
  Future<ApiResponse<Map<String, dynamic>>> logout() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken != null) {
        await _client.post(
          Uri.parse('$baseUrl/api/token/logout/'),
          headers: await _getHeaders(),
          body: json.encode({'refresh': refreshToken}),
        ).timeout(Duration(milliseconds: timeoutDuration));
      }

      await clearTokens();
      return ApiResponse.success({'message': 'Logged out successfully'});
    } catch (e) {
      // Even if logout fails on server, clear local tokens
      await clearTokens();
      return ApiResponse.success({'message': 'Logged out locally'});
    }
  }

  // Refresh token
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _client.post(
        Uri.parse('$baseUrl/api/token/refresh/'),
        headers: await _getHeaders(includeAuth: false),
        body: json.encode({'refresh': refreshToken}),
      ).timeout(Duration(milliseconds: timeoutDuration));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await setTokens(data['access'], refreshToken);
        return true;
      } else {
        await clearTokens();
        return false;
      }
    } catch (e) {
      await clearTokens();
      return false;
    }
  }



  // Apply coupon
  Future<ApiResponse<Map<String, dynamic>>> applyCoupon(String couponCode, double cartTotal) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.applyCouponUrl),
        headers: await _getHeaders(),
        body: json.encode({
          'coupon_code': couponCode,
          'cart_total': cartTotal,
        }),
      ).timeout(Duration(milliseconds: timeoutDuration));

      return _handleResponse(response, (data) => data);
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Create order
  Future<ApiResponse<Map<String, dynamic>>> createOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.createOrderUrl),
        headers: await _getHeaders(),
        body: json.encode(orderData),
      ).timeout(Duration(milliseconds: timeoutDuration));

      return _handleResponse(response, (data) => data);
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Additional API methods for profile features

  // Forgot Password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/user/forgot-password/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to send reset email',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Change Password
  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/user/change-password/'),
        headers: await _getHeaders(),
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to change password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Address Management
  Future<Map<String, dynamic>> getAddresses() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/user/addresses/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to load addresses',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> addAddress(Map<String, dynamic> addressData) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/user/addresses/'),
        headers: await _getHeaders(),
        body: json.encode(addressData),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to add address',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateAddress(int id, Map<String, dynamic> addressData) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/user/addresses/$id/'),
        headers: await _getHeaders(),
        body: json.encode(addressData),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to update address',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteAddress(int id) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/user/addresses/$id/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 204) {
        return {'success': true};
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to delete address',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Prescription Management
  Future<Map<String, dynamic>> getPrescriptions() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/prescription/prescriptions/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to load prescriptions',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Dispose
  void dispose() {
    _client.close();
  }
}
