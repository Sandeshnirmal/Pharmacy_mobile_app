/// API Configuration for Pharmacy Mobile App
///
/// This file contains all API-related configuration including base URLs,
/// endpoints, and other API settings. Update the base URL here to change
/// it across the entire application.
library;

class ApiConfig {
  // Base URL Configuration
  // Update this IP address when your backend server IP changes
  static const String _baseIP = '127.0.0.1'; // Android emulator localhost
  static const String _basePort = '8000';

  // Main API Base URLs
  static const String baseUrl = 'http://$_baseIP:$_basePort';
  static const String apiBaseUrl = 'http://$_baseIP:$_basePort/api';

  // API Endpoints (Fixed to match backend structure)
  static const String authEndpoint = '$apiBaseUrl/auth';
  static const String userEndpoint = '$apiBaseUrl/users';
  static const String prescriptionEndpoint = '$apiBaseUrl/prescriptions';
  static const String orderEndpoint = '$apiBaseUrl/order';
  static const String productEndpoint = '$apiBaseUrl/products';
  static const String cartEndpoint = '$apiBaseUrl/cart';

  // Specific Auth URLs
  static const String loginUrl = '$baseUrl/user/login/';
  static const String registerUrl = '$baseUrl/api/auth/register/';
  static const String userProfileUrl = '$userEndpoint/auth-me/';
  static const String logoutUrl =
      '$baseUrl/logout/'; // Assuming logout will also be directly under base URL or handled differently
  static const String changePasswordUrl = '$baseUrl/change-password/';
  static const String forgotPasswordUrl = '$baseUrl/forgot-password/';

  // Product URLs (Fixed to match backend)
  static const String productsUrl = '$productEndpoint/products/';
  static const String enhancedProductsUrl =
      '$productEndpoint/enhanced-products/';
  static const String categoriesUrl = '$productEndpoint/legacy/categories/';
  static const String genericNamesUrl =
      '$productEndpoint/legacy/generic-names/';
  static const String compositionsUrl = '$productEndpoint/compositions/';

  // Prescription URLs - OCR/AI Processing (for medicine discovery)
  static const String prescriptionUploadUrl =
      '$prescriptionEndpoint/mobile/upload/';
  static const String prescriptionStatusUrl =
      '$prescriptionEndpoint/mobile/status/';
  static const String medicineSuggestionsUrl =
      '$prescriptionEndpoint/mobile/suggestions/';
  static const String prescriptionSearchUrl =
      '$prescriptionEndpoint/mobile/search/';
  static const String prescriptionProductsUrl =
      '$prescriptionEndpoint/mobile/products/';

  // Prescription Scanner URLs (New enhanced features)
  static const String prescriptionScanUrl =
      '$prescriptionEndpoint/scanner/scan_prescription/';
  static const String medicineSearchUrl =
      '$prescriptionEndpoint/scanner/search_medicines/';
  static const String scanHistoryUrl =
      '$prescriptionEndpoint/scanner/scan_history/';

  // Prescription URLs - Simple Upload (for order verification - NO AI/OCR)
  static const String prescriptionForOrderUrl =
      '$prescriptionEndpoint/upload-for-order/';
  static const String prescriptionForPaidOrderUrl =
      '$prescriptionEndpoint/upload-for-paid-order/';

  // Prescription Order Creation
  static const String prescriptionCreateOrderUrl =
      '$prescriptionEndpoint/mobile/create-order/';

  // Order URLs (Fixed to match backend)
  static const String ordersUrl = '$orderEndpoint/orders/';
  static const String orderDetailsUrl = '$orderEndpoint/orders/';
  static const String createOrderUrl = '$orderEndpoint/orders/';
  static const String applyCouponUrl = '$orderEndpoint/apply-coupon/';
  static const String orderTrackingUrl = '$orderEndpoint/tracking/';
  static const String orderStatusHistoryUrl = '$orderEndpoint/status-history/';
  static const String getAddresses = '$apiBaseUrl/users/addresses/';

  // Enhanced Order Flow URLs (Payment First Approach)
  static const String createPaidOrderUrl =
      '$orderEndpoint/enhanced/create-paid-order/';
  static const String linkPrescriptionUrl =
      '$orderEndpoint/enhanced/link-prescription/';
  static const String verifyPrescriptionUrl =
      '$orderEndpoint/enhanced/verify-prescription/';
  static const String prescriptionReviewUrl =
      '$orderEndpoint/enhanced/prescription-review/';
  static const String awaitingPrescriptionUrl =
      '$orderEndpoint/enhanced/awaiting-prescription/';

  // Payment URLs
  static const String createPaymentUrl = '$baseUrl/payment/create/';
  static const String verifyPaymentUrl = '$baseUrl/payment/verify/';

  // Courier URLs (Professional courier integration)
  static const String courierPartnersUrl = '$apiBaseUrl/courier/partners/';
  static const String courierShipmentsUrl = '$apiBaseUrl/courier/shipments/';
  static const String courierTrackingUrl =
      '$apiBaseUrl/courier/shipments/track/';
  static const String courierSchedulePickupUrl =
      '$apiBaseUrl/courier/shipments/schedule_pickup/';

  // Razorpay Configuration (Update these with your actual keys)
  static const String razorpayKeyId =
      'rzp_test_u32HLv2OyCBfAN'; // Replace with your key
  static const String razorpayKeySecret =
      'Owlg61rwtT7V3RQKoYGKhsUC'; // Replace with your secret

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
