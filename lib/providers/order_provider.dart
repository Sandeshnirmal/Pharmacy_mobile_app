// Order Provider for Flutter Pharmacy App
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // State variables
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Order> get orders => _orders;
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

      if (result.isSuccess && result.data != null) {
        // Convert OrderModel list to Order list
        _orders = result.data!.map((orderModel) => Order(
          id: orderModel.id,
          status: orderModel.status,
          createdAt: orderModel.orderDate,
          totalAmount: orderModel.totalAmount,
          items: orderModel.items.map((item) => OrderItem(
            id: item.id,
            productId: item.product.id,
            productName: item.product.displayName,
            productImage: item.product.imageUrl,
            quantity: item.quantity,
            unitPrice: item.price,
            totalPrice: item.totalPrice,
          )).toList(),
          userId: 0, // Default value
        )).toList();
        _setLoading(false);
      } else {
        _setError(result.error ?? 'Failed to load orders');
        _setLoading(false);
      }
    } catch (e) {
      _setError('Failed to load orders: $e');
      _setLoading(false);
    }
  }

  // Get order by ID
  Future<Order?> getOrderById(int orderId) async {
    try {
      final result = await _apiService.getOrderDetails(orderId);

      if (result.isSuccess && result.data != null) {
        final orderModel = result.data!;
        return Order(
          id: orderModel.id,
          status: orderModel.status,
          createdAt: orderModel.orderDate,
          totalAmount: orderModel.totalAmount,
          items: orderModel.items.map((item) => OrderItem(
            id: item.id,
            productId: item.product.id,
            productName: item.product.displayName,
            productImage: item.product.imageUrl,
            quantity: item.quantity,
            unitPrice: item.price,
            totalPrice: item.totalPrice,
          )).toList(),
          userId: 0, // Default value
        );
      } else {
        _setError(result.error ?? 'Failed to get order details');
        return null;
      }
    } catch (e) {
      _setError('Failed to get order details: $e');
      return null;
    }
  }

  // Get orders by status
  List<Order> getOrdersByStatus(String status) {
    return _orders.where((order) => order.status.toLowerCase() == status.toLowerCase()).toList();
  }

  // Get recent orders
  List<Order> getRecentOrders({int limit = 5}) {
    final sortedOrders = List<Order>.from(_orders);
    sortedOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedOrders.take(limit).toList();
  }

  // Get prescription orders
  List<Order> getPrescriptionOrders() {
    return _orders.where((order) => order.notes?.contains('prescription') == true).toList();
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

}
