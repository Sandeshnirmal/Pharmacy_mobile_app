// Order Provider for Flutter Pharmacy App
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // State variables
  List<Order> _allOrders = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Order> get orders => _allOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasOrders => _allOrders.isNotEmpty;

  // Load user orders
  Future<void> loadOrders({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    _setLoading(true);
    _clearError();

    try {
      // Always fetch all orders from the API
      final result = await _apiService.getOrders();

      if (result.isSuccess && result.data != null) {
        print(
          'OrderProvider: Successfully fetched ${result.data!.length} orders from API.',
        );
        _allOrders = result.data!
            .map<Order>((orderJson) => Order.fromJson(orderJson))
            .toList();
        _setLoading(false);
      } else {
        print('OrderProvider: Failed to load orders. Error: ${result.error}');
        _setError(result.error ?? 'Failed to load orders');
        _setLoading(false);
      }
    } catch (e) {
      print('OrderProvider: Exception during order loading: $e');
      _setError('Failed to load orders: $e');
      _setLoading(false);
    }
  }

  // Get order by ID
  Future<Order?> getOrderById(int orderId) async {
    try {
      final result = await _apiService.getOrderDetails(orderId);

      if (result.isSuccess && result.data != null) {
        final orderJson = result.data!;
        print(
          'OrderProvider: Successfully fetched OrderDetail for ID: ${orderJson['id']}',
        );
        return Order.fromJson(orderJson);
      } else {
        print(
          'OrderProvider: Failed to get order details for ID: $orderId. Error: ${result.error}',
        );
        _setError(result.error ?? 'Failed to get order details');
        return null;
      }
    } catch (e) {
      print(
        'OrderProvider: Exception during order detail loading for ID: $orderId: $e',
      );
      _setError('Failed to get order details: $e');
      return null;
    }
  }

  // Get orders by status
  List<Order> getOrdersByStatus(String status) {
    return _allOrders
        .where((order) => order.status.toLowerCase() == status.toLowerCase())
        .toList();
  }

  // Get recent orders
  List<Order> getRecentOrders({int limit = 5}) {
    final sortedOrders = List<Order>.from(_allOrders);
    sortedOrders.sort(
      (a, b) => b.orderDate.compareTo(a.orderDate),
    ); // Use orderDate for sorting
    return sortedOrders.take(limit).toList();
  }

  // Get prescription orders
  List<Order> getPrescriptionOrders() {
    return _allOrders.where((order) => order.isPrescriptionOrder).toList();
  }

  // Calculate total spent
  double getTotalSpent() {
    return _allOrders.fold(0.0, (total, order) => total + order.totalAmount);
  }

  // Get order statistics
  Map<String, int> getOrderStatistics() {
    final stats = <String, int>{};

    for (final order in _allOrders) {
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
}
