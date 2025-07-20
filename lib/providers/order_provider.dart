// Order Provider for Flutter Pharmacy App
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';

class OrderProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // State variables
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasOrders => _orders.isNotEmpty;

  // Load user orders
  Future<void> loadOrders({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    _setLoading(true);
    _clearError();

    try {
      final result = await _apiService.getOrders();
      
      if (result.isSuccess) {
        _orders = result.data!;
        _setLoading(false);
      } else {
        _setError(result.error!);
        _setLoading(false);
      }
    } catch (e) {
      _setError('Failed to load orders: $e');
      _setLoading(false);
    }
  }

  // Get order by ID
  Future<OrderModel?> getOrderById(int orderId) async {
    try {
      final result = await _apiService.getOrderDetails(orderId);
      
      if (result.isSuccess) {
        return result.data!;
      } else {
        _setError(result.error!);
        return null;
      }
    } catch (e) {
      _setError('Failed to get order details: $e');
      return null;
    }
  }

  // Get orders by status
  List<OrderModel> getOrdersByStatus(String status) {
    return _orders.where((order) => order.status.toLowerCase() == status.toLowerCase()).toList();
  }

  // Get recent orders
  List<OrderModel> getRecentOrders({int limit = 5}) {
    final sortedOrders = List<OrderModel>.from(_orders);
    sortedOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return sortedOrders.take(limit).toList();
  }

  // Get prescription orders
  List<OrderModel> getPrescriptionOrders() {
    return _orders.where((order) => order.isPrescriptionOrder).toList();
  }

  // Calculate total spent
  double getTotalSpent() {
    return _orders.fold(0.0, (total, order) => total + order.totalAmount);
  }

  // Get order statistics
  Map<String, int> getOrderStatistics() {
    final stats = <String, int>{};
    
    for (final order in _orders) {
      final status = order.status.toLowerCase();
      stats[status] = (stats[status] ?? 0) + 1;
    }
    
    return stats;
  }

  // Clear error
  void clearError() {
    _clearError();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
