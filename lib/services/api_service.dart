// API Service for Flutter Pharmacy App
import 'dart:async'; // Import for StreamController
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/user_model.dart';
import '../models/prescription_model.dart';
import '../models/prescription_detail_model.dart'; // Import the new model
import '../models/product_model.dart';
import '../utils/api_logger.dart';
import '../utils/network_helper.dart';

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

  // Stream controller for logout events
  final _logoutController = StreamController<bool>.broadcast();
  Stream<bool> get onLogout => _logoutController.stream;

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
  Future<Map<String, String>> getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Generic method to send HTTP requests with token refresh logic
  Future<http.Response> _sendRequest(
    Future<http.Response> Function() request, {
    bool includeAuth = true,
    bool isRetry = false,
  }) async {
    try {
      http.Response response = await request();

      if (response.statusCode == 401 && includeAuth && !isRetry) {
        ApiLogger.logError('401 Unauthorized. Attempting token refresh...');
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          ApiLogger.log('Token refreshed successfully. Retrying request...');
          // Re-create headers with new token for retry
          // This assumes the original request builder will fetch new headers
          // For simplicity, we'll just re-run the request.
          // A more robust solution might involve passing a function to get headers.
          return await request(); // Retry the original request
        } else {
          ApiLogger.logError(
            'Token refresh failed. Clearing tokens and logging out.',
          );
          await clearTokens();
          _logoutController.add(true); // Notify listeners to log out
          return response; // Return original 401 response
        }
      } else if (response.statusCode == 401 && includeAuth && isRetry) {
        ApiLogger.logError(
          '401 Unauthorized on retry. Clearing tokens and logging out.',
        );
        await clearTokens();
        _logoutController.add(true); // Notify listeners to log out
      }
      return response;
    } catch (e) {
      ApiLogger.logError('Request failed: $e');
      rethrow; // Re-throw to be caught by individual API methods
    }
  }

  // Handle HTTP response with better error handling
  ApiResponse<T> handleResponse<T>(
    // Made public
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      ApiLogger.logResponse(response.statusCode, response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        return ApiResponse.success(fromJson(data));
      } else {
        String errorMessage = 'Request failed';
        try {
          final errorData = json.decode(response.body);
          errorMessage =
              errorData['error'] ??
              errorData['detail'] ??
              errorData['message'] ??
              errorData['non_field_errors']?.first ??
              'Request failed with status ${response.statusCode}';
        } catch (e) {
          errorMessage = 'Request failed with status ${response.statusCode}';
        }

        // Handle 401 Unauthorized specifically
        if (response.statusCode == 401) {
          ApiLogger.logError(
            '401 Unauthorized: Token expired or invalid. Attempting refresh.',
          );
          // Do not clear tokens here, let the retry mechanism handle it
          // The actual retry logic will be implemented in a wrapper function
          // that calls this handleResponse. For now, just return an error
          // indicating a 401, which the wrapper will catch.
        }
        return ApiResponse.error(errorMessage, response.statusCode);
      }
    } catch (e) {
      return ApiResponse.error(
        'Failed to parse response: $e',
        response.statusCode,
      );
    }
  }

  // Test API connectivity
  Future<ApiResponse<bool>> testConnection() async {
    try {
      ApiLogger.log('Testing API connectivity...');

      // First check network connectivity
      final hasInternet = await NetworkHelper.hasInternetConnection();
      if (!hasInternet) {
        return ApiResponse.error('No internet connection', 0);
      }

      // Test server connectivity
      final response = await _sendRequest(
        () async => _client
            .get(
              // Mark the lambda as async
              Uri.parse('${ApiConfig.baseUrl}/'),
              headers: await getHeaders(includeAuth: false),
            )
            .timeout(Duration(milliseconds: 10000)),
        includeAuth: false,
      );

      ApiLogger.logResponse(response.statusCode, 'Connection test response');

      if (response.statusCode < 500) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error(
          'Server error: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      ApiLogger.logError('Connection test failed: $e');
      return ApiResponse.error('Connection failed: $e', 0);
    }
  }

  // Comprehensive connectivity check
  Future<Map<String, dynamic>> checkSystemHealth() async {
    ApiLogger.log('Performing system health check...');

    final connectivity = await NetworkHelper.checkConnectivity();
    final message = NetworkHelper.getConnectivityMessage(connectivity);

    return {
      'connectivity': connectivity,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Authentication APIs
  Future<ApiResponse<UserModel>> login(String email, String password) async {
    try {
      ApiLogger.logRequest('POST', ApiConfig.loginUrl);

      final response = await _client
          .post(
            Uri.parse(ApiConfig.loginUrl),
            headers: await getHeaders(includeAuth: false),
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(Duration(milliseconds: timeoutDuration));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response formats
        String accessToken =
            data['access'] ?? data['token'] ?? data['access_token'] ?? '';
        String refreshToken = data['refresh'] ?? data['refresh_token'] ?? '';

        if (accessToken.isNotEmpty) {
          await setTokens(accessToken, refreshToken);
        }

        // Get user profile from response data
        final userData = data['user'] ?? data;
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
      final response = await _sendRequest(
        () async => _client
            .get(
              Uri.parse(ApiConfig.userProfileUrl),
              headers: await getHeaders(),
            )
            .timeout(Duration(milliseconds: timeoutDuration)),
      );

      return handleResponse(response, (data) => UserModel.fromJson(data));
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Prescription APIs

  // Simple prescription upload for order verification (NO AI/OCR processing)
  Future<ApiResponse<Map<String, dynamic>>> uploadPrescriptionForOrder(
    File imageFile,
  ) async {
    try {
      ApiLogger.log(
        'Uploading prescription for order verification (NO AI/OCR)',
      );
      ApiLogger.log('File path: ${imageFile.path}');

      // Validate file exists and is readable
      if (!await imageFile.exists()) {
        return ApiResponse.error('Image file not found', 0);
      }

      // Check file size (max 10MB)
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        return ApiResponse.error(
          'File size too large. Maximum 10MB allowed.',
          0,
        );
      }

      // Validate file extension
      final fileName = imageFile.path.split('/').last.toLowerCase();
      final allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
      final fileExtension = fileName.split('.').last;

      if (!allowedExtensions.contains(fileExtension)) {
        return ApiResponse.error(
          'Invalid file format. Only JPG, PNG, and WebP images are allowed.',
          0,
        );
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.prescriptionForOrderUrl),
      );

      // Add headers (remove Content-Type for multipart)
      final headers = await getHeaders();
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      // Determine proper MIME type
      String mimeType = 'image/jpeg';
      switch (fileExtension) {
        case 'png':
          mimeType = 'image/png';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg';
      }

      // Add image file with proper field name and MIME type
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // Changed field name to 'image'
          imageFile.path,
          filename: 'prescription.$fileExtension',
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send();
      http.Response response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401) {
        ApiLogger.logError(
          '401 Unauthorized for multipart request. Attempting token refresh...',
        );
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          ApiLogger.log(
            'Token refreshed successfully. Retrying multipart request...',
          );
          // Re-create request with new headers
          final newRequest = http.MultipartRequest(
            'POST',
            Uri.parse(ApiConfig.prescriptionForOrderUrl),
          );
          final newHeaders = await getHeaders();
          newHeaders.remove('Content-Type');
          newRequest.headers.addAll(newHeaders);
          newRequest.files.add(
            await http.MultipartFile.fromPath(
              'image',
              imageFile.path,
              filename: 'prescription.$fileExtension',
              contentType: MediaType.parse(mimeType),
            ),
          );
          final newStreamedResponse = await newRequest.send();
          response = await http.Response.fromStream(newStreamedResponse);
        } else {
          ApiLogger.logError(
            'Token refresh failed for multipart request. Clearing tokens and logging out.',
          );
          await clearTokens();
          _logoutController.add(true);
          return ApiResponse.error(
            'Authentication failed. Please log in again.',
            response.statusCode,
          );
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ApiResponse.success(data);
      } else {
        String errorMessage = 'Upload failed';
        try {
          final errorData = json.decode(response.body);
          errorMessage =
              errorData['error'] ?? errorData['detail'] ?? errorMessage;
        } catch (e) {
          // If error body is not JSON, use generic message
        }
        return ApiResponse.error(errorMessage, response.statusCode);
      }
    } catch (e) {
      ApiLogger.logError('Upload prescription for order error: $e');
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Full prescription upload with processing (for medicine discovery)
  Future<ApiResponse<PrescriptionUploadResponse>> uploadPrescription(
    File imageFile,
  ) async {
    try {
      ApiLogger.log(
        'Uploading prescription to: ${ApiConfig.prescriptionUploadUrl}',
      );
      ApiLogger.log('File path: ${imageFile.path}');
      ApiLogger.log('File size: ${await imageFile.length()} bytes');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.prescriptionUploadUrl),
      );

      // Add headers (remove Content-Type for multipart)
      final headers = await getHeaders();
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      // Validate file exists and is readable
      if (!await imageFile.exists()) {
        return ApiResponse.error('Image file not found', 0);
      }

      // Determine proper MIME type and filename
      final fileName = imageFile.path.split('/').last.toLowerCase();
      final fileExtension = fileName.split('.').last;
      String mimeType = 'image/jpeg'; // Default
      switch (fileExtension) {
        case 'png':
          mimeType = 'image/png';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        case 'heic': // Add HEIC support if needed by backend
          mimeType = 'image/heic';
          break;
        default:
          mimeType = 'image/jpeg';
      }

      // Add image file with proper field name and MIME type
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // Changed field name to 'image'
          imageFile.path,
          filename: 'prescription.$fileExtension',
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send().timeout(
        Duration(milliseconds: timeoutDuration * 3),
      );
      http.Response response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401) {
        ApiLogger.logError(
          '401 Unauthorized for multipart request. Attempting token refresh...',
        );
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          ApiLogger.log(
            'Token refreshed successfully. Retrying multipart request...',
          );
          // Re-create request with new headers
          final newRequest = http.MultipartRequest(
            'POST',
            Uri.parse(ApiConfig.prescriptionUploadUrl),
          );
          final newHeaders = await getHeaders();
          newHeaders.remove('Content-Type');
          newRequest.headers.addAll(newHeaders);
          newRequest.files.add(
            await http.MultipartFile.fromPath(
              'image',
              imageFile.path,
              filename: 'prescription.$fileExtension',
              contentType: MediaType.parse(mimeType),
            ),
          );
          final newStreamedResponse = await newRequest.send().timeout(
            Duration(milliseconds: timeoutDuration * 3),
          );
          response = await http.Response.fromStream(newStreamedResponse);
        } else {
          ApiLogger.logError(
            'Token refresh failed for multipart request. Clearing tokens and logging out.',
          );
          await clearTokens();
          _logoutController.add(true);
          return ApiResponse.error(
            'Authentication failed. Please log in again.',
            response.statusCode,
          );
        }
      }

      ApiLogger.logResponse(response.statusCode, response.body);

      return handleResponse(
        response,
        (data) => PrescriptionUploadResponse.fromJson(data),
      );
    } catch (e) {
      ApiLogger.logError('Upload error: $e');
      return ApiResponse.error('Upload failed: $e', 0);
    }
  }

  // Get a single prescription detail by ID
  Future<ApiResponse<PrescriptionDetailModel>> getPrescriptionDetail(
    String prescriptionId,
  ) async {
    try {
      final url =
          '${ApiConfig.baseUrl}/prescription/mobile/detail/$prescriptionId/';
      ApiLogger.logRequest('GET', url);

      final response = await _sendRequest(
        () async => _client
            .get(Uri.parse(url), headers: await getHeaders())
            .timeout(Duration(milliseconds: timeoutDuration)),
      );

      return handleResponse(
        response,
        (data) => PrescriptionDetailModel.fromJson(data),
      );
    } catch (e) {
      ApiLogger.logError('Get prescription detail error: $e');
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  Future<ApiResponse<PrescriptionStatusResponse>> getPrescriptionStatus(
    String prescriptionId, // Changed to String
  ) async {
    try {
      final url =
          '${ApiConfig.baseUrl}/prescription/mobile/status/$prescriptionId/';
      ApiLogger.logRequest('GET', url);

      final response = await _sendRequest(
        () async => _client
            .get(Uri.parse(url), headers: await getHeaders())
            .timeout(Duration(milliseconds: timeoutDuration)),
      );

      return handleResponse(
        response,
        (data) => PrescriptionStatusResponse.fromJson(data),
      );
    } catch (e) {
      ApiLogger.logError('Prescription status error: $e');
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  Future<ApiResponse<PrescriptionSuggestionsResponse>> getMedicineSuggestions(
    String prescriptionId, // Changed to String
  ) async {
    try {
      final url =
          '${ApiConfig.baseUrl}/prescription/mobile/suggestions/$prescriptionId/';
      ApiLogger.logRequest('GET', url);

      final response = await _sendRequest(
        () async => _client
            .get(Uri.parse(url), headers: await getHeaders())
            .timeout(Duration(milliseconds: timeoutDuration)),
      );

      return handleResponse(
        response,
        (data) => PrescriptionSuggestionsResponse.fromJson(data),
      );
    } catch (e) {
      ApiLogger.logError('Medicine suggestions error: $e');
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  Future<ApiResponse<OrderResponse>> createPrescriptionOrder(
    Map<String, dynamic> orderData,
  ) async {
    try {
      final response = await _sendRequest(
        () async => _client
            .post(
              Uri.parse(ApiConfig.prescriptionCreateOrderUrl),
              headers: await getHeaders(),
              body: json.encode(orderData),
            )
            .timeout(Duration(milliseconds: timeoutDuration)),
      );

      return handleResponse(response, (data) => OrderResponse.fromJson(data));
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Product APIs
  Future<ApiResponse<List<ProductModel>>> getProducts({
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse(
        ApiConfig.enhancedProductsUrl,
      ).replace(queryParameters: queryParams);

      final response = await _sendRequest(
        () async => _client
            .get(uri, headers: await getHeaders())
            .timeout(Duration(milliseconds: timeoutDuration)),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        if (data is List) {
          final list = data
              .map(
                (item) => ProductModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();
          return ApiResponse.success(list);
        } else if (data is Map && data.containsKey('results')) {
          final results = data['results'] as List;
          final list = results
              .map(
                (item) => ProductModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();
          return ApiResponse.success(list);
        } else {
          return ApiResponse.error(
            'Invalid response format',
            response.statusCode,
          );
        }
      } else {
        final errorData = json.decode(response.body);
        final errorMessage =
            errorData['error'] ?? errorData['detail'] ?? 'Request failed';
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

  // Search prescription-based medicines
  Future<ApiResponse<List<ProductModel>>> searchPrescriptionMedicines(
    String query,
  ) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.prescriptionSearchUrl}?q=$query&limit=20'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> productsJson = data['products'];
          final products = productsJson
              .map(
                (json) => ProductModel(
                  id: json['id'],
                  name: json['name'],
                  manufacturer: json['manufacturer'],
                  price: json['price'].toDouble(),
                  mrp: json['mrp'].toDouble(),
                  imageUrl:
                      json['image_url'] ??
                      'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400',
                  description: json['description'] ?? 'Medicine',
                  genericName: json['generic_name'] ?? '',
                  requiresPrescription:
                      json['is_prescription_required'] ?? false,
                  stockQuantity: json['stock_quantity'] ?? 0,
                  isActive: json['in_stock'] ?? false,
                  strength: json['strength'] ?? '',
                  form: json['form'] ?? '',
                ),
              )
              .toList();

          return ApiResponse.success(products);
        } else {
          return ApiResponse.error(
            data['error'] ?? 'Search failed',
            response.statusCode,
          );
        }
      } else {
        return ApiResponse.error(
          'HTTP ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Get prescription-based products for search
  Future<ApiResponse<List<ProductModel>>> getPrescriptionProducts(
    int prescriptionId,
  ) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/prescription/mobile/products/$prescriptionId/'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> productsJson = data['products'];
          final products = productsJson
              .map(
                (json) => ProductModel(
                  id: json['id'],
                  name: json['name'],
                  manufacturer: json['manufacturer'],
                  price: json['price'].toDouble(),
                  mrp: json['mrp'].toDouble(),
                  imageUrl:
                      'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400',
                  description:
                      json['extracted_medicine'] ?? 'Prescription medicine',
                  genericName: json['extracted_medicine'],
                  requiresPrescription:
                      json['is_prescription_required'] ?? true,
                  stockQuantity: json['stock_quantity'] ?? 0,
                  isActive: json['in_stock'] ?? false,
                ),
              )
              .toList();

          return ApiResponse.success(products);
        } else {
          return ApiResponse.error(
            data['error'] ?? 'Failed to get prescription products',
            response.statusCode,
          );
        }
      } else {
        return ApiResponse.error(
          'HTTP ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Get orders
  Future<ApiResponse<List<OrderModel>>> getOrders() async {
    try {
      final response = await _client
          .get(Uri.parse(ApiConfig.ordersUrl), headers: await getHeaders())
          .timeout(Duration(milliseconds: timeoutDuration));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        if (data is List) {
          final list = data
              .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
              .toList();
          return ApiResponse.success(list);
        } else if (data is Map && data.containsKey('results')) {
          final results = data['results'] as List;
          final list = results
              .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
              .toList();
          return ApiResponse.success(list);
        } else {
          return ApiResponse.error(
            'Invalid response format',
            response.statusCode,
          );
        }
      } else {
        final errorData = json.decode(response.body);
        final errorMessage =
            errorData['error'] ?? errorData['detail'] ?? 'Request failed';
        return ApiResponse.error(errorMessage, response.statusCode);
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Get order details
  Future<ApiResponse<OrderModel>> getOrderDetails(int orderId) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/order/orders/$orderId/'),
            headers: await getHeaders(),
          )
          .timeout(Duration(milliseconds: timeoutDuration));

      return handleResponse(response, (data) => OrderModel.fromJson(data));
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Get order tracking information
  Future<ApiResponse<Map<String, dynamic>>> getOrderTracking(
    int orderId,
  ) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/order/tracking/$orderId/'),
            headers: await getHeaders(),
          )
          .timeout(Duration(milliseconds: timeoutDuration));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          errorData['error'] ?? 'Failed to load tracking data',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Intelligent Medicine Search
  Future<ApiResponse<Map<String, dynamic>>> intelligentMedicineSearch(
    List<String> medicines,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/prescription/search/medicines/'),
            headers: await getHeaders(),
            body: json.encode({'medicines': medicines, 'limit': 5}),
          )
          .timeout(Duration(milliseconds: timeoutDuration));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          errorData['error'] ?? 'Medicine search failed',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Search by Composition
  Future<ApiResponse<Map<String, dynamic>>> searchByComposition(
    List<Map<String, String>> compositions,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/prescription/search/composition/'),
            headers: await getHeaders(),
            body: json.encode({'compositions': compositions}),
          )
          .timeout(Duration(milliseconds: timeoutDuration));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          errorData['error'] ?? 'Composition search failed',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Upload prescription with OCR processing
  Future<ApiResponse<Map<String, dynamic>>> uploadPrescriptionWithOCR(
    String base64Image,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/prescription/mobile/upload/'),
            headers: await getHeaders(),
            body: json.encode({'image': base64Image, 'process_with_ai': true}),
          )
          .timeout(
            Duration(milliseconds: timeoutDuration * 3),
          ); // Longer timeout for OCR

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ApiResponse.success(data);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          errorData['error'] ?? 'Prescription upload failed',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // OCR Analysis of prescription image
  Future<ApiResponse<Map<String, dynamic>>> analyzePrescriptionOCR(
    String base64Image,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/prescription/ocr/analyze/'),
            headers: await getHeaders(),
            body: json.encode({'image': base64Image}),
          )
          .timeout(
            Duration(milliseconds: timeoutDuration * 3),
          ); // Longer timeout for OCR

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          errorData['error'] ?? 'OCR analysis failed',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Create pending order (before prescription verification)
  Future<ApiResponse<Map<String, dynamic>>> createPendingOrder(
    Map<String, dynamic> orderData,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.ordersUrl}/pending/'),
            headers: await getHeaders(),
            body: json.encode(orderData),
          )
          .timeout(Duration(milliseconds: timeoutDuration));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ApiResponse.success(data);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          errorData['error'] ?? 'Failed to create pending order',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Upload prescription for paid order verification (after payment)
  Future<ApiResponse<Map<String, dynamic>>> uploadPrescriptionForPaidOrder(
    Map<String, dynamic> prescriptionData,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/prescriptions/upload-for-paid-order/'),
            headers: await getHeaders(),
            body: json.encode(prescriptionData),
          )
          .timeout(Duration(milliseconds: timeoutDuration * 2));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ApiResponse.success(data);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          errorData['error'] ?? 'Failed to upload prescription',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Get prescription verification status
  Future<ApiResponse<Map<String, dynamic>>> getPrescriptionVerificationStatus(
    int prescriptionId,
  ) async {
    try {
      final response = await _client
          .get(
            Uri.parse(
              '$baseUrl/api/prescriptions/verification-status/$prescriptionId/',
            ),
            headers: await getHeaders(),
          )
          .timeout(Duration(milliseconds: timeoutDuration));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          errorData['error'] ?? 'Failed to get verification status',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Confirm prescription order after verification
  Future<ApiResponse<Map<String, dynamic>>> confirmPrescriptionOrder(
    int orderId,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/order/confirm-prescription/$orderId/'),
            headers: await getHeaders(),
            body: json.encode({}),
          )
          .timeout(Duration(milliseconds: timeoutDuration));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          errorData['error'] ?? 'Failed to confirm order',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Register user
  Future<ApiResponse<Map<String, dynamic>>> register(
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse(ApiConfig.registerUrl),
            headers: await getHeaders(includeAuth: false),
            body: json.encode(userData),
          )
          .timeout(Duration(milliseconds: timeoutDuration));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        return ApiResponse.success(data);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage =
            errorData['error'] ?? errorData['detail'] ?? 'Registration failed';
        return ApiResponse.error(errorMessage, response.statusCode);
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Update user profile
  Future<ApiResponse<UserModel>> updateUserProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await _client
          .put(
            Uri.parse(ApiConfig.userProfileUrl),
            headers: await getHeaders(),
            body: json.encode(profileData),
          )
          .timeout(Duration(milliseconds: timeoutDuration));

      return handleResponse(response, (data) => UserModel.fromJson(data));
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Logout
  Future<ApiResponse<Map<String, dynamic>>> logout() async {
    try {
      final refreshToken = await getRefreshToken();
      // No server-side logout endpoint is explicitly defined for JWT blacklisting.
      // Logout is handled by clearing local tokens.
      // If a server-side logout is needed, it must be implemented in the backend.

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

      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/token/refresh/'),
            headers: await getHeaders(includeAuth: false),
            body: json.encode({'refresh': refreshToken}),
          )
          .timeout(Duration(milliseconds: timeoutDuration));

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
  Future<ApiResponse<Map<String, dynamic>>> applyCoupon(
    String couponCode,
    double cartTotal,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse(ApiConfig.applyCouponUrl),
            headers: await getHeaders(),
            body: json.encode({
              'coupon_code': couponCode,
              'cart_total': cartTotal,
            }),
          )
          .timeout(Duration(milliseconds: timeoutDuration));

      return handleResponse(response, (data) => data);
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Create order
  Future<ApiResponse<Map<String, dynamic>>> createOrder(
    Map<String, dynamic> orderData,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse(ApiConfig.createOrderUrl),
            headers: await getHeaders(),
            body: json.encode(orderData),
          )
          .timeout(Duration(milliseconds: timeoutDuration));

      return handleResponse(response, (data) => data);
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Additional API methods for profile features

  // Forgot Password
  Future<ApiResponse<Map<String, dynamic>>> forgotPassword(String email) async {
    try {
      final response = await _client
          .post(
            Uri.parse(ApiConfig.forgotPasswordUrl),
            headers: await getHeaders(includeAuth: false),
            body: json.encode({'email': email}),
          )
          .timeout(Duration(milliseconds: timeoutDuration));

      return handleResponse(response, (data) => data as Map<String, dynamic>);
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Change Password
  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.changePasswordUrl),
        headers: await getHeaders(),
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to change password',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Address Management
  Future<Map<String, dynamic>> getAddresses() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.getAddresses),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to load addresses',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> addAddress(
    Map<String, dynamic> addressData,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/user/addresses/'),
        headers: await getHeaders(),
        body: json.encode(addressData),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to add address',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateAddress(
    int id,
    Map<String, dynamic> addressData,
  ) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/user/addresses/$id/'),
        headers: await getHeaders(),
        body: json.encode(addressData),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to update address',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteAddress(int id) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/user/addresses/$id/'),
        headers: await getHeaders(),
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
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Prescription Management
  Future<ApiResponse<List<PrescriptionDetailModel>>>
  getUserPrescriptions() async {
    try {
      final url = '${ApiConfig.prescriptionEndpoint}/mobile/list/';
      ApiLogger.logRequest('GET', url);

      final response = await _client
          .get(Uri.parse(url), headers: await getHeaders())
          .timeout(Duration(milliseconds: timeoutDuration));

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        if (decodedData is List) {
          final prescriptions = decodedData
              .map(
                (json) => PrescriptionDetailModel.fromJson(
                  json as Map<String, dynamic>,
                ),
              )
              .toList();
          return ApiResponse.success(prescriptions);
        } else if (decodedData is Map &&
            decodedData.containsKey('prescriptions') &&
            decodedData['prescriptions'] is List) {
          // Handle cases where the response is a map containing a 'prescriptions' list
          final List<dynamic> prescriptionsList = decodedData['prescriptions'];
          final prescriptions = prescriptionsList
              .map(
                (json) => PrescriptionDetailModel.fromJson(
                  json as Map<String, dynamic>,
                ),
              )
              .toList();
          return ApiResponse.success(prescriptions);
        } else if (decodedData is Map && decodedData.isEmpty) {
          // Handle empty map response as an empty list
          return ApiResponse.success([]);
        } else {
          // If the response is not a list or a map with a 'prescriptions' list, treat as empty
          ApiLogger.logError(
            'Unexpected response format for getUserPrescriptions: $decodedData',
          );
          return ApiResponse.success([]);
        }
      } else {
        String errorMessage = 'Failed to load prescriptions';
        try {
          final errorData = json.decode(response.body);
          errorMessage =
              errorData['error'] ?? errorData['detail'] ?? errorMessage;
        } catch (e) {
          // If error body is not JSON, use generic message
        }
        return ApiResponse.error(errorMessage, response.statusCode);
      }
    } catch (e) {
      ApiLogger.logError('Get user prescriptions error: $e');
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  Future<Map<String, dynamic>> getPrescriptions() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/prescription/prescriptions/'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to load prescriptions',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Dispose
  void dispose() {
    _client.close();
    _logoutController.close(); // Close the stream controller
  }
}
