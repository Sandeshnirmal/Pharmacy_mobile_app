// Network Helper Utility
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_logger.dart';

class NetworkHelper {
  // Check if device has internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  // Check if backend server is reachable
  static Future<bool> isServerReachable() async {
    try {
      ApiLogger.log('Testing server connectivity to: ${ApiConfig.baseUrl}');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      ApiLogger.log('Server response status: ${response.statusCode}');
      return response.statusCode < 500; // Accept any non-server-error response
    } catch (e) {
      ApiLogger.logError('Server connectivity test failed: $e');
      return false;
    }
  }

  // Check if API endpoints are working
  static Future<bool> isApiHealthy() async {
    try {
      ApiLogger.log('Testing API health at: ${ApiConfig.baseUrl}/api/');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      ApiLogger.log('API health response status: ${response.statusCode}');
      return response.statusCode < 500;
    } catch (e) {
      ApiLogger.logError('API health check failed: $e');
      return false;
    }
  }

  // Comprehensive connectivity check
  static Future<Map<String, bool>> checkConnectivity() async {
    final results = <String, bool>{};
    
    ApiLogger.log('Starting comprehensive connectivity check...');
    
    results['internet'] = await hasInternetConnection();
    ApiLogger.log('Internet connectivity: ${results['internet']}');
    
    if (results['internet'] == true) {
      results['server'] = await isServerReachable();
      ApiLogger.log('Server reachability: ${results['server']}');
      
      if (results['server'] == true) {
        results['api'] = await isApiHealthy();
        ApiLogger.log('API health: ${results['api']}');
      } else {
        results['api'] = false;
      }
    } else {
      results['server'] = false;
      results['api'] = false;
    }
    
    return results;
  }

  // Get connectivity status message
  static String getConnectivityMessage(Map<String, bool> status) {
    if (status['internet'] != true) {
      return 'No internet connection. Please check your network settings.';
    } else if (status['server'] != true) {
      return 'Cannot reach server at ${ApiConfig.baseUrl}. Please check server status.';
    } else if (status['api'] != true) {
      return 'API endpoints are not responding. Please try again later.';
    } else {
      return 'All systems operational.';
    }
  }
}
