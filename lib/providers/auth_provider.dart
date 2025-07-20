// Authentication Provider for Flutter Pharmacy App
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  UserModel? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;

  // Check if user is logged in on app start
  Future<void> checkAuthStatus() async {
    _setLoading(true);
    
    try {
      final token = await _apiService.getAccessToken();
      if (token != null) {
        // Try to get user profile to verify token validity
        final result = await _apiService.getUserProfile();
        if (result.isSuccess) {
          _user = result.data;
          _isAuthenticated = true;
          _error = null;
        } else {
          // Token is invalid, clear it
          await _apiService.clearTokens();
          _isAuthenticated = false;
          _user = null;
        }
      } else {
        _isAuthenticated = false;
        _user = null;
      }
    } catch (e) {
      print('Auth check error: $e');
      _isAuthenticated = false;
      _user = null;
      _error = 'Failed to check authentication status';
    }
    
    _setLoading(false);
  }

  // Login user
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final result = await _apiService.login(email, password);
      
      if (result.isSuccess) {
        _user = result.data;
        _isAuthenticated = true;
        _error = null;
        _setLoading(false);
        return true;
      } else {
        _error = result.error;
        _isAuthenticated = false;
        _user = null;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Login failed: $e';
      _isAuthenticated = false;
      _user = null;
      _setLoading(false);
      return false;
    }
  }

  // Register user
  Future<bool> register(Map<String, dynamic> userData) async {
    _setLoading(true);
    _error = null;

    try {
      final result = await _apiService.register(userData);
      
      if (result.isSuccess) {
        // Registration successful, but user needs to login
        _error = null;
        _setLoading(false);
        return true;
      } else {
        _error = result.error;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Registration failed: $e';
      _setLoading(false);
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await _apiService.logout();
      _user = null;
      _isAuthenticated = false;
      _error = null;
    } catch (e) {
      print('Logout error: $e');
      // Even if logout fails, clear local state
      _user = null;
      _isAuthenticated = false;
    }
    
    _setLoading(false);
  }

  // Update user profile
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    _setLoading(true);
    _error = null;

    try {
      final result = await _apiService.updateUserProfile(profileData);
      
      if (result.isSuccess) {
        _user = result.data;
        _error = null;
        _setLoading(false);
        return true;
      } else {
        _error = result.error;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Profile update failed: $e';
      _setLoading(false);
      return false;
    }
  }

  // Refresh user profile
  Future<void> refreshProfile() async {
    if (!_isAuthenticated) return;

    try {
      final result = await _apiService.getUserProfile();
      if (result.isSuccess) {
        _user = result.data;
        notifyListeners();
      }
    } catch (e) {
      print('Profile refresh error: $e');
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
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
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null; // Password is valid
  }

  // Validate phone number
  static bool isValidPhoneNumber(String phoneNumber) {
    return RegExp(r'^[+]?[1-9][\d]{9,14}$').hasMatch(phoneNumber);
  }


}
