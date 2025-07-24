import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_service.dart';
import '../utils/logger.dart';
class AuthService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final ApiService _apiService = ApiService();

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Check if user is authenticated (with caching to avoid repeated API calls)
  static bool? _cachedAuthState;
  static DateTime? _lastAuthCheck;

  Future<bool> isAuthenticated() async {
    try {
      // Use cached result if it's less than 30 seconds old
      if (_cachedAuthState != null && _lastAuthCheck != null) {
        final timeDiff = DateTime.now().difference(_lastAuthCheck!);
        if (timeDiff.inSeconds < 30) {
          return _cachedAuthState!;
        }
      }

      final token = await _secureStorage.read(key: 'access_token');
      if (token == null) {
        _cachedAuthState = false;
        _lastAuthCheck = DateTime.now();
        return false;
      }

      // Verify token is still valid by making a test API call
      final response = await http.get(
        Uri.parse(ApiConfig.userProfileUrl),
        headers: {
          'Authorization': 'Token $token',  // Django TokenAuthentication uses 'Token' not 'Bearer'
          'Content-Type': 'application/json',
        },
      );

      final isAuth = response.statusCode == 200;
      _cachedAuthState = isAuth;
      _lastAuthCheck = DateTime.now();

      // If token is invalid, clear it
      if (!isAuth) {
        await _secureStorage.delete(key: 'access_token');
        await _secureStorage.delete(key: 'refresh_token');
        await _clearUserData();
      }

      return isAuth;
    } catch (e) {
      Logger.auth('Auth check error: $e');
      _cachedAuthState = false;
      _lastAuthCheck = DateTime.now();
      return false;
    }
  }

  // Get current user
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final token = await _secureStorage.read(key: 'access_token');
      if (token == null) return null;

      final response = await http.get(
        Uri.parse(ApiConfig.userProfileUrl),
        headers: {
          'Authorization': 'Token $token',  // Django TokenAuthentication uses 'Token' not 'Bearer'
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);

        // Store user data locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', json.encode(userData));

        return userData;
      }
      return null;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  // Login user with real API
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Store auth token securely
        if (responseData['access'] != null) {
          await _secureStorage.write(key: 'access_token', value: responseData['access']);
          await _secureStorage.write(key: 'refresh_token', value: responseData['refresh']);
        }

        // Store user data
        if (responseData['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', json.encode(responseData['user']));
        }

        // Clear authentication cache to force refresh
        _cachedAuthState = true;
        _lastAuthCheck = DateTime.now();

        return {
          'success': true,
          'user': responseData['user'],
          'message': 'Login successful',
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Access forbidden. Please check backend CORS configuration.',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? responseData['detail'] ?? 'Login failed',
        };
      }
    } catch (e) {
      Logger.auth('Login error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Register user with real API
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
    // print('Attempting registration with data: $userData'); // Debug print removed

      final response = await http.post(
        Uri.parse(ApiConfig.registerUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest', // Helps with CORS
        },
        body: json.encode(userData),
      );

    // print('Registration response status: ${response.statusCode}'); // Debug print removed
    // print('Registration response body: ${response.body}'); // Debug print removed

      final responseData = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Registration successful. Please login with your credentials.',
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Access forbidden. Please check backend CORS configuration.',
        };
      } else {
        // Handle validation errors
        String errorMessage = 'Registration failed';
        if (responseData is Map) {
          if (responseData['email'] != null) {
            errorMessage = 'Email: ${responseData['email'][0]}';
          } else if (responseData['password'] != null) {
            errorMessage = 'Password: ${responseData['password'][0]}';
          } else if (responseData['error'] != null) {
            errorMessage = responseData['error'];
          } else if (responseData['detail'] != null) {
            errorMessage = responseData['detail'];
          } else if (responseData['message'] != null) {
            errorMessage = responseData['message'];
          }
        }

        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      print('Registration error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      await _apiService.logout();
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      await _clearUserData();

      // Clear authentication cache
      _cachedAuthState = false;
      _lastAuthCheck = DateTime.now();
    } catch (e) {
      print('Logout error: $e');
      // Clear local data even if API call fails
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      await _clearUserData();

      // Clear authentication cache
      _cachedAuthState = false;
      _lastAuthCheck = DateTime.now();
    }
  }

  // Clear user data
  Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('cart_data');
    } catch (e) {
      print('Clear user data error: $e');
    }
  }

  // Get auth token for API calls
  Future<String?> getAuthToken() async {
    try {
      return await _secureStorage.read(key: 'access_token');
    } catch (e) {
      print('Get auth token error: $e');
      return null;
    }
  }

  // Mock login for demo purposes
  Future<Map<String, dynamic>> mockLogin(String email, String password) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock validation
    if (email.isEmpty || password.isEmpty) {
      return {
        'success': false,
        'message': 'Email and password are required',
      };
    }

    if (!email.contains('@')) {
      return {
        'success': false,
        'message': 'Please enter a valid email address',
      };
    }

    if (password.length < 6) {
      return {
        'success': false,
        'message': 'Password must be at least 6 characters',
      };
    }

    // Mock successful login
    final mockUser = {
      'id': 1,
      'email': email,
      'first_name': 'John',
      'last_name': 'Doe',
      'phone': '+1234567890',
      'is_verified': true,
    };

    // Store mock auth token
    await _secureStorage.write(key: 'access_token', value: 'mock_token_${DateTime.now().millisecondsSinceEpoch}');
    
    // Store user data
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(mockUser));

    return {
      'success': true,
      'user': mockUser,
      'message': 'Login successful',
    };
  }

  // Mock register for demo purposes
  Future<Map<String, dynamic>> mockRegister(Map<String, dynamic> userData) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock validation
    if (userData['email'] == null || userData['email'].isEmpty) {
      return {
        'success': false,
        'message': 'Email is required',
      };
    }

    if (userData['password'] == null || userData['password'].isEmpty) {
      return {
        'success': false,
        'message': 'Password is required',
      };
    }

    if (userData['first_name'] == null || userData['first_name'].isEmpty) {
      return {
        'success': false,
        'message': 'First name is required',
      };
    }

    if (!userData['email'].contains('@')) {
      return {
        'success': false,
        'message': 'Please enter a valid email address',
      };
    }

    if (userData['password'].length < 6) {
      return {
        'success': false,
        'message': 'Password must be at least 6 characters',
      };
    }

    // Mock successful registration
    return {
      'success': true,
      'message': 'Registration successful! Please login with your credentials.',
    };
  }

  // Check if user is authenticated (mock version)
  Future<bool> isMockAuthenticated() async {
    try {
      final token = await _secureStorage.read(key: 'access_token');
      return token != null && token.startsWith('mock_token_');
    } catch (e) {
      return false;
    }
  }

  // Get mock user data
  Future<Map<String, dynamic>?> getMockUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) {
        return json.decode(userData);
      }
      return null;
    } catch (e) {
      print('Get mock user error: $e');
      return null;
    }
  }

  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate password strength
  static String? validatePassword(String password) {
    if (password.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null; // Password is valid
  }

  // Validate phone number
  static bool isValidPhoneNumber(String phoneNumber) {
    return RegExp(r'^[+]?[1-9][\d]{9,14}$').hasMatch(phoneNumber);
  }
}
