// API Logger Utility
import '../config/api_config.dart';

class ApiLogger {
  static void log(String message) {
    if (ApiConfig.isDevelopment && ApiConfig.enableLogging) {
      // In development, we can use print for debugging
      // In production, this would be replaced with a proper logging framework
      // ignore: avoid_print
      print('[API] $message');
    }
  }

  static void logRequest(String method, String url, {Map<String, dynamic>? body}) {
    if (ApiConfig.isDevelopment && ApiConfig.enableLogging) {
      // ignore: avoid_print
      print('[API REQUEST] $method $url');
      if (body != null) {
        // ignore: avoid_print
        print('[API REQUEST BODY] $body');
      }
    }
  }

  static void logResponse(int statusCode, String body) {
    if (ApiConfig.isDevelopment && ApiConfig.enableLogging) {
      // ignore: avoid_print
      print('[API RESPONSE] Status: $statusCode');
      // ignore: avoid_print
      print('[API RESPONSE BODY] $body');
    }
  }

  static void logError(String error) {
    if (ApiConfig.isDevelopment && ApiConfig.enableLogging) {
      // ignore: avoid_print
      print('[API ERROR] $error');
    }
  }
}
