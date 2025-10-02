// Product Provider for Flutter Pharmacy App
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/category_model.dart'; // Import CategoryModel
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // State variables
  List<ProductModel> _products = [];
  List<ProductModel> _searchResults = [];
  List<CategoryModel> _categories = []; // New: Store categories
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  String _searchQuery = '';

  // Getters
  List<ProductModel> get products => _products;
  List<ProductModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  bool get hasProducts => _products.isNotEmpty;
  bool get hasSearchResults => _searchResults.isNotEmpty;
  List<CategoryModel> get categories =>
      _categories; // New: Getter for categories

  // Load all products
  Future<void> loadProducts({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    _setLoading(true);
    _clearError();

    try {
      final result = await _apiService.getProducts();

      if (result.isSuccess) {
        _products = result.data!;
        _setLoading(false);
      } else {
        _setError(result.error!);
        _setLoading(false);
      }
    } catch (e) {
      _setError('Failed to load products: $e');
      _setLoading(false);
    }
  }

  // Search products
  Future<void> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      _searchResults.clear();
      _searchQuery = '';
      notifyListeners();
      return;
    }

    _setSearching(true);
    _clearError();
    _searchQuery = query;

    try {
      final result = await _apiService.searchProducts(query);

      if (result.isSuccess) {
        _searchResults = result.data!;
        _setSearching(false);
      } else {
        _setError(result.error!);
        _setSearching(false);
      }
    } catch (e) {
      _setError('Search failed: $e');
      _setSearching(false);
    }
  }

  // Load categories
  Future<void> loadCategories() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _apiService.getCategories();
      if (result.isSuccess) {
        _categories = result.data!;
        _setLoading(false);
      } else {
        _setError(result.error!);
        _setLoading(false);
      }
    } catch (e) {
      _setError('Failed to load categories: $e');
      _setLoading(false);
    }
  }

  // Get products by category
  Future<void> getProductsByCategory(int categoryId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _apiService.getProducts(categoryId: categoryId);

      if (result.isSuccess) {
        _products = result.data!;
        _setLoading(false);
      } else {
        _setError(result.error!);
        _setLoading(false);
      }
    } catch (e) {
      _setError('Failed to load category products: $e');
      _setLoading(false);
    }
  }

  // Get featured products
  List<ProductModel> getFeaturedProducts() {
    return _products.where((product) => product.isActive).take(10).toList();
  }

  // Get products on sale
  List<ProductModel> getProductsOnSale() {
    return _products.where((product) => product.isOnSale).toList();
  }

  // Get products by prescription requirement
  List<ProductModel> getProductsByPrescriptionRequirement(
    bool requiresPrescription,
  ) {
    return _products
        .where(
          (product) => product.requiresPrescription == requiresPrescription,
        )
        .toList();
  }

  // Get product by ID
  ProductModel? getProductById(int id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  // Clear search results
  void clearSearch() {
    _searchResults.clear();
    _searchQuery = '';
    notifyListeners();
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

  void _setSearching(bool searching) {
    _isSearching = searching;
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
