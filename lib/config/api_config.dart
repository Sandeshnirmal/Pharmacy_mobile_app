/// API Configuration for Pharmacy Mobile App
///
/// This file contains all API-related configuration including base URLs,
/// endpoints, and other API settings. Update the base URL here to change
/// it across the entire application.
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Base URL Configuration
  static final String baseUrl =
      dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000';
  static final String apiBaseUrl = '$baseUrl/api';

  // API Endpoints (Fixed to match backend structure)
  static final String authEndpoint = '$apiBaseUrl/auth';
  static final String userEndpoint = '$apiBaseUrl/users';
  static final String prescriptionEndpoint = '$apiBaseUrl/prescriptions';
  static final String orderEndpoint = '$apiBaseUrl/order';
  static final String productEndpoint = '$apiBaseUrl/products';
  static final String cartEndpoint = '$apiBaseUrl/cart';

  // Specific Auth URLs
  static final String loginUrl = '$baseUrl/user/login/';
  static final String registerUrl = '$baseUrl/api/auth/register/';
  static final String userProfileUrl = '$userEndpoint/auth-me/';
  static final String logoutUrl =
      '$baseUrl/logout/'; // Assuming logout will also be directly under base URL or handled differently
  static final String changePasswordUrl = '$baseUrl/change-password/';
  static final String forgotPasswordUrl = '$baseUrl/forgot-password/';

  // Product URLs (Fixed to match backend)
  static final String productsUrl = '$productEndpoint/products/';
  static final String enhancedProductsUrl =
      '$productEndpoint/enhanced-products/';
  static final String categoriesUrl = '$productEndpoint/legacy/categories/';
  static final String genericNamesUrl =
      '$productEndpoint/legacy/generic-names/';
  static final String compositionsUrl = '$productEndpoint/compositions/';

  // Prescription URLs - OCR/AI Processing (for medicine discovery)
  static final String prescriptionUploadUrl =
      '$prescriptionEndpoint/mobile/upload/';
  static final String prescriptionStatusUrl =
      '$prescriptionEndpoint/mobile/status/';
  static final String medicineSuggestionsUrl =
      '$prescriptionEndpoint/mobile/suggestions/';
  static final String prescriptionSearchUrl =
      '$prescriptionEndpoint/mobile/search/';
  static final String prescriptionProductsUrl =
      '$prescriptionEndpoint/mobile/products/';

  // Prescription Scanner URLs (New enhanced features)
  static final String prescriptionScanUrl =
      '$prescriptionEndpoint/scanner/scan_prescription/';
  static final String medicineSearchUrl =
      '$prescriptionEndpoint/scanner/search_medicines/';
  static final String scanHistoryUrl =
      '$prescriptionEndpoint/scanner/scan_history/';

  // Prescription URLs - Simple Upload (for order verification - NO AI/OCR)
  static final String prescriptionForOrderUrl =
      '$prescriptionEndpoint/upload-for-order/';
  static final String prescriptionForPaidOrderUrl =
      '$prescriptionEndpoint/upload-for-paid-order/';

  // Prescription Order Creation
  static final String prescriptionCreateOrderUrl =
      '$prescriptionEndpoint/mobile/create-order/';

  // Order URLs (Fixed to match backend)
  static final String ordersUrl = '$orderEndpoint/orders/';
  static final String orderDetailsUrl = '$orderEndpoint/orders/';
  static final String createOrderUrl = '$orderEndpoint/orders/';
  static final String applyCouponUrl = '$orderEndpoint/apply-coupon/';
  static final String orderTrackingUrl = '$orderEndpoint/tracking/';
  static final String orderStatusHistoryUrl = '$orderEndpoint/status-history/';
  static final String getAddresses = '$apiBaseUrl/users/addresses/';

  // Enhanced Order Flow URLs (Payment First Approach)
  static final String createPaidOrderUrl =
      '$orderEndpoint/enhanced/create-paid-order/';
  static final String linkPrescriptionUrl =
      '$orderEndpoint/enhanced/link-prescription/';
  static final String verifyPrescriptionUrl =
      '$orderEndpoint/enhanced/verify-prescription/';
  static final String prescriptionReviewUrl =
      '$orderEndpoint/enhanced/prescription-review/';
  static final String awaitingPrescriptionUrl =
      '$orderEndpoint/enhanced/awaiting-prescription/';

  // Payment URLs
  static final String createPaymentUrl = '$baseUrl/payment/create/';
  static final String verifyPaymentUrl = '$baseUrl/payment/verify/';

  // Courier URLs (Professional courier integration)
  static final String courierPartnersUrl = '$apiBaseUrl/courier/partners/';
  static final String courierShipmentsUrl = '$apiBaseUrl/courier/shipments/';
  static final String courierTrackingUrl =
      '$apiBaseUrl/courier/shipments/track/';
  static final String courierSchedulePickupUrl =
      '$apiBaseUrl/courier/shipments/schedule_pickup/';

  // Razorpay Configuration (Update these with your actual keys)
  static final String razorpayKeyId =
      dotenv.env['RAZORPAY_KEY_ID'] ??
      'rzp_test_u32HLv2OyCBfAN'; // Replace with your key
  static final String razorpayKeySecret =
      dotenv.env['RAZORPAY_KEY_SECRET'] ??
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
  static final bool isDevelopment = dotenv.env['IS_DEVELOPMENT'] == 'true';
  static final bool enableLogging = dotenv.env['ENABLE_LOGGING'] == 'true';

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
