// Cart Service for Flutter Pharmacy App
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class CartService {
  static const String _cartKey = 'pharmacy_cart';
  static const String _couponKey = 'applied_coupon';

  final ApiService _apiService = ApiService();

  // Singleton pattern
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  // Helper method to safely parse double from various types
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Get cart from local storage
  Future<Cart> getCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);
      final couponJson = prefs.getString(_couponKey);
      
      if (cartJson != null) {
        final cartData = json.decode(cartJson);
        final items = (cartData['items'] as List? ?? [])
            .map((item) => CartItem.fromJson(item))
            .toList();
        
        double couponDiscount = 0.0;
        String? couponCode;
        
        if (couponJson != null) {
          final couponData = json.decode(couponJson);
          couponDiscount = _parseDouble(couponData['discount_amount']);
          couponCode = couponData['coupon_code'];
        }
        
        return Cart(
          items: items,
          couponCode: couponCode,
          couponDiscount: couponDiscount,
        );
      }
      
      return Cart(); // Empty cart
    } catch (e) {
      print('Error loading cart: $e');
      return Cart(); // Return empty cart on error
    }
  }

  // Save cart to local storage
  Future<void> saveCart(Cart cart) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cartKey, json.encode(cart.toJson()));
      
      if (cart.couponCode != null) {
        await prefs.setString(_couponKey, json.encode({
          'coupon_code': cart.couponCode,
          'discount_amount': cart.couponDiscount,
        }));
      } else {
        await prefs.remove(_couponKey);
      }
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  // Add item to cart
  Future<Cart> addToCart(ProductModel product, {int quantity = 1}) async {
    final cart = await getCart();
    final items = List<CartItem>.from(cart.items);
    
    // Check if item already exists in cart
    final existingIndex = items.indexWhere((item) => item.productId == product.id);
    
    if (existingIndex != -1) {
      // Update quantity of existing item
      items[existingIndex].quantity += quantity;
    } else {
      // Add new item to cart
      final cartItem = CartItem(
        productId: product.id,
        name: product.name,
        manufacturer: product.manufacturer,
        strength: product.strength,
        form: product.form,
        price: product.price,
        mrp: product.mrp,
        imageUrl: product.imageUrl,
        requiresPrescription: product.requiresPrescription,
        quantity: quantity,
      );
      items.add(cartItem);
    }
    
    final updatedCart = cart.copyWith(items: items);
    await saveCart(updatedCart);
    return updatedCart;
  }

  // Remove item from cart
  Future<Cart> removeFromCart(int productId) async {
    final cart = await getCart();
    final items = cart.items.where((item) => item.productId != productId).toList();
    
    final updatedCart = cart.copyWith(items: items);
    await saveCart(updatedCart);
    return updatedCart;
  }

  // Update item quantity
  Future<Cart> updateQuantity(int productId, int quantity) async {
    final cart = await getCart();
    final items = List<CartItem>.from(cart.items);
    
    if (quantity <= 0) {
      // Remove item if quantity is 0 or less
      return removeFromCart(productId);
    }
    
    final itemIndex = items.indexWhere((item) => item.productId == productId);
    if (itemIndex != -1) {
      items[itemIndex].quantity = quantity;
    }
    
    final updatedCart = cart.copyWith(items: items);
    await saveCart(updatedCart);
    return updatedCart;
  }

  // Clear cart
  Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
    await prefs.remove(_couponKey);
  }

  // Apply coupon
  Future<ApiResponse<CouponResponse>> applyCoupon(String couponCode, double cartTotal) async {
    try {
      final response = await _apiService.applyCoupon(couponCode, cartTotal);

      if (response.isSuccess && response.data != null) {
        final couponResponse = CouponResponse.fromJson(response.data!);

        if (couponResponse.isValid) {
          // Save coupon to local storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_couponKey, json.encode({
            'coupon_code': couponCode,
            'discount_amount': couponResponse.discountAmount,
          }));
        }

        return ApiResponse.success(couponResponse);
      } else {
        return ApiResponse.error(response.error ?? 'Failed to apply coupon', response.statusCode);
      }
    } catch (e) {
      return ApiResponse.error('Failed to apply coupon: $e', 0);
    }
  }

  // Remove coupon
  Future<Cart> removeCoupon() async {
    final cart = await getCart();
    final updatedCart = cart.copyWith(
      couponCode: null,
      couponDiscount: 0.0,
    );
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_couponKey);
    await saveCart(updatedCart);
    
    return updatedCart;
  }

  // Create order from cart
  Future<ApiResponse<Map<String, dynamic>>> createOrder(Cart cart, {
    String? deliveryAddress,
    String? notes,
  }) async {
    try {
      final orderRequest = OrderRequest(
        items: cart.items,
        couponCode: cart.couponCode,
        total: cart.total,
        deliveryAddress: deliveryAddress,
        notes: notes,
      );
      
      final response = await _apiService.createOrder(orderRequest.toJson());
      
      if (response.isSuccess) {
        // Clear cart after successful order
        await clearCart();
      }
      
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to create order: $e', 0);
    }
  }

  // Get cart item count
  Future<int> getCartItemCount() async {
    final cart = await getCart();
    return cart.totalItems;
  }

  // Check if product is in cart
  Future<bool> isInCart(int productId) async {
    final cart = await getCart();
    return cart.items.any((item) => item.productId == productId);
  }

  // Get quantity of specific product in cart
  Future<int> getProductQuantity(int productId) async {
    final cart = await getCart();
    final item = cart.items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(
        productId: 0,
        name: '',
        manufacturer: '',
        price: 0,
        mrp: 0,
        requiresPrescription: false,
        quantity: 0,
      ),
    );
    return item.quantity;
  }
}
