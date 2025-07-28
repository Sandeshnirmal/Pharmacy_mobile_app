
/// API Configuration for Pharmacy Mobile App
///
/// This file contains all API-related configuration including base URLs,
/// endpoints, and other API settings. Update the base URL here to change
/// it across the entire application.

class ApiConfig {
  // Base URL Configuration
  // Update this IP address when your backend server IP changes
  static const String _baseIP = '192.168.29.197';
  static const String _basePort = '8001';

  // Main API Base URLs
  static const String baseUrl = 'http://$_baseIP:$_basePort';
  static const String apiBaseUrl = 'http://$_baseIP:$_basePort/api';

  // API Endpoints
  static const String authEndpoint = '$apiBaseUrl/auth';
  static const String userEndpoint = '$apiBaseUrl/user';
  static const String prescriptionEndpoint = '$apiBaseUrl/prescription';
  static const String orderEndpoint = '$apiBaseUrl/order';
  static const String productEndpoint = '$apiBaseUrl/product';
  static const String cartEndpoint = '$apiBaseUrl/cart';

  // Specific Auth URLs
  static const String loginUrl = '$authEndpoint/login/';
  static const String registerUrl = '$authEndpoint/register/';
  static const String userProfileUrl = '$authEndpoint/user/';
  static const String logoutUrl = '$authEndpoint/logout/';

  // Product URLs
  static const String productsUrl = '$baseUrl/product/products/';
  static const String enhancedProductsUrl = '$baseUrl/product/enhanced-products/';

  // Prescription URLs
  static const String prescriptionUploadUrl = '$baseUrl/prescription/mobile/upload/';
  static const String prescriptionStatusUrl = '$baseUrl/prescription/mobile/status/';
  static const String medicineSuggestionsUrl = '$baseUrl/prescription/mobile/suggestions/';
  static const String prescriptionForOrderUrl = '$baseUrl/prescription/upload-for-order/';
  static const String prescriptionCreateOrderUrl = '$baseUrl/prescription/mobile/create-order/';

  // Order URLs
  static const String ordersUrl = '$baseUrl/order/orders/';
  static const String orderDetailsUrl = '$baseUrl/order/details/';
  static const String createOrderUrl = '$baseUrl/order/orders/';
  static const String applyCouponUrl = '$baseUrl/order/apply-coupon/';

  // API Configuration
  static const int timeoutDuration = 30000; // milliseconds
  static const int maxRetryAttempts = 3;

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Development/Production Environment
  static const bool isDevelopment = true;
  static const bool enableLogging = true;

  // Helper Methods
  static String getFullUrl(String endpoint) {
    if (endpoint.startsWith('http')) {
      return endpoint;
    }
    return '$baseUrl$endpoint';
  }

  static String getApiUrl(String endpoint) {
    if (endpoint.startsWith('http')) {
      return endpoint;
    }
    return '$apiBaseUrl$endpoint';
  }

  // Debug Information
  static void printConfig() {
    if (isDevelopment && enableLogging) {
      print('=== API Configuration ===');
      print('Base URL: $baseUrl');
      print('API Base URL: $apiBaseUrl');
      print('Auth Endpoint: $authEndpoint');
      print('User Endpoint: $userEndpoint');
      print('Prescription Endpoint: $prescriptionEndpoint');
      print('Order Endpoint: $orderEndpoint');
      print('Product Endpoint: $productEndpoint');
      print('Cart Endpoint: $cartEndpoint');
      print('========================');
    }
  }
}
