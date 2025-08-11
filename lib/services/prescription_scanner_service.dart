import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class PrescriptionScannerService {
  static const String _tag = 'PrescriptionScannerService';

  /// Scan prescription text and get medicine suggestions
  /// This is for search-only functionality, not for placing orders
  static Future<Map<String, dynamic>> scanPrescription({
    required String prescriptionText,
    String? token,
  }) async {
    try {
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        Uri.parse(ApiConfig.prescriptionScanUrl),
        headers: headers,
        body: jsonEncode({
          'prescription_text': prescriptionText,
        }),
      );

      if (ApiConfig.enableLogging) {
        print('$_tag - Scan Prescription Response: ${response.statusCode}');
        print('$_tag - Response Body: ${response.body}');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': responseData['success'] ?? true,
          'extracted_medicines': responseData['extracted_medicines'] ?? [],
          'suggestions': responseData['suggestions'] ?? [],
          'total_suggestions': responseData['total_suggestions'] ?? 0,
          'scan_result_id': responseData['scan_result_id'],
          'message': responseData['message'] ?? 'Scan completed successfully',
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to scan prescription',
          'suggestions': [],
          'total_suggestions': 0,
        };
      }
    } catch (e) {
      if (ApiConfig.enableLogging) {
        print('$_tag - Error scanning prescription: $e');
      }
      return {
        'success': false,
        'error': 'Network error: $e',
        'suggestions': [],
        'total_suggestions': 0,
      };
    }
  }

  /// Search medicines by name or composition
  static Future<Map<String, dynamic>> searchMedicines({
    required String query,
    String searchType = 'name', // name, composition, generic
    String? token,
  }) async {
    try {
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final url = '${ApiConfig.medicineSearchUrl}?q=${Uri.encodeComponent(query)}&type=$searchType';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (ApiConfig.enableLogging) {
        print('$_tag - Search Medicines Response: ${response.statusCode}');
        print('$_tag - Response Body: ${response.body}');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': responseData['success'] ?? true,
          'query': responseData['query'] ?? query,
          'search_type': responseData['search_type'] ?? searchType,
          'suggestions': responseData['suggestions'] ?? [],
          'total_suggestions': responseData['total_suggestions'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to search medicines',
          'suggestions': [],
          'total_suggestions': 0,
        };
      }
    } catch (e) {
      if (ApiConfig.enableLogging) {
        print('$_tag - Error searching medicines: $e');
      }
      return {
        'success': false,
        'error': 'Network error: $e',
        'suggestions': [],
        'total_suggestions': 0,
      };
    }
  }

  /// Get scan history for authenticated user
  static Future<Map<String, dynamic>> getScanHistory({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.scanHistoryUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (ApiConfig.enableLogging) {
        print('$_tag - Get Scan History Response: ${response.statusCode}');
        print('$_tag - Response Body: ${response.body}');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': responseData['success'] ?? true,
          'scans': responseData['scans'] ?? [],
          'total_scans': responseData['total_scans'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to fetch scan history',
          'scans': [],
          'total_scans': 0,
        };
      }
    } catch (e) {
      if (ApiConfig.enableLogging) {
        print('$_tag - Error fetching scan history: $e');
      }
      return {
        'success': false,
        'error': 'Network error: $e',
        'scans': [],
        'total_scans': 0,
      };
    }
  }

  /// Parse medicine suggestions into a more usable format
  static List<MedicineSuggestion> parseMedicineSuggestions(List<dynamic> suggestions) {
    return suggestions.map((suggestion) => MedicineSuggestion.fromJson(suggestion)).toList();
  }
}

/// Model for medicine suggestions
class MedicineSuggestion {
  final int productId;
  final String name;
  final String brandName;
  final String genericName;
  final String manufacturer;
  final String category;
  final List<CompositionInfo> compositions;
  final double price;
  final double mrp;
  final bool isPrescriptionRequired;
  final int stockQuantity;
  final String? imageUrl;
  final String matchType;
  final String searchTerm;
  final double confidenceScore;

  MedicineSuggestion({
    required this.productId,
    required this.name,
    required this.brandName,
    required this.genericName,
    required this.manufacturer,
    required this.category,
    required this.compositions,
    required this.price,
    required this.mrp,
    required this.isPrescriptionRequired,
    required this.stockQuantity,
    this.imageUrl,
    required this.matchType,
    required this.searchTerm,
    required this.confidenceScore,
  });

  factory MedicineSuggestion.fromJson(Map<String, dynamic> json) {
    return MedicineSuggestion(
      productId: json['product_id'] ?? 0,
      name: json['name'] ?? '',
      brandName: json['brand_name'] ?? '',
      genericName: json['generic_name'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      category: json['category'] ?? '',
      compositions: (json['compositions'] as List<dynamic>? ?? [])
          .map((comp) => CompositionInfo.fromJson(comp))
          .toList(),
      price: _parseDouble(json['price']),
      mrp: _parseDouble(json['mrp']),
      isPrescriptionRequired: json['is_prescription_required'] ?? false,
      stockQuantity: json['stock_quantity'] ?? 0,
      imageUrl: json['image_url'],
      matchType: json['match_type'] ?? '',
      searchTerm: json['search_term'] ?? '',
      confidenceScore: _parseDouble(json['confidence_score']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}

/// Model for composition information
class CompositionInfo {
  final String name;
  final String strength;
  final String unit;
  final bool isPrimary;

  CompositionInfo({
    required this.name,
    required this.strength,
    required this.unit,
    this.isPrimary = false,
  });

  factory CompositionInfo.fromJson(Map<String, dynamic> json) {
    return CompositionInfo(
      name: json['name'] ?? '',
      strength: json['strength'] ?? '',
      unit: json['unit'] ?? '',
      isPrimary: json['is_primary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'strength': strength,
      'unit': unit,
      'is_primary': isPrimary,
    };
  }
}
