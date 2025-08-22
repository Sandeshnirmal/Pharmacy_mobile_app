// Cart Service for Flutter Pharmacy App
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';
import '../models/cart_model.dart';
import '../models/cart_item.dart';
import '../models/product_model.dart';
import '../models/api_response.dart';
import 'api_service.dart';

import '../models/cart_item.dart';

class CartService {
  static const String _cartKey = 'pharmacy_cart';
  static const String _couponKey = 'applied_coupon';

  final ApiService _apiService = ApiService();

  // Singleton pattern
  static final CartService _instance = CartService._internal();

  factory CartService() {
    return _instance;
  }

  CartService._internal() {
    // Initialize any required resources
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_cartKey)) {
        // Initialize with empty cart if none exists
        await saveCart(Cart());
      }
    } catch (e) {
      print('Error initializing cart service: $e');
    }
  }

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

  // Recovery method for corrupted cart data
  Future<void> _recoverCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cartKey);
      await prefs.remove(_couponKey);
      print('Cart data recovery completed');
    } catch (e) {
      print('Error during cart recovery: $e');
    }
  }

  // Get cart from local storage
  Future<Cart> getCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);
      final couponJson = prefs.getString(_couponKey);

      if (cartJson != null) {
        try {
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
        } catch (parseError) {
          print('Error parsing cart data: $parseError');
          // Attempt to recover from corrupted data
          await _recoverCart();
        }
      }

      return Cart(); // Empty cart
    } catch (e) {
      print('Error loading cart: $e');
      // Attempt to recover from any error
      await _recoverCart();
      return Cart(); // Return empty cart on error
    }
  }

  // Save cart to local storage

  Future<void> saveCart(Cart cart) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cartKey, json.encode(cart.toJson()));

      if (cart.couponCode != null) {
        await prefs.setString(
          _couponKey,
          json.encode({
            'coupon_code': cart.couponCode,
            'discount_amount': cart.couponDiscount,
          }),
        );
      } else {
        await prefs.remove(_couponKey);
      }
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  // Add item to cart
  Future<Cart> addToCart(ProductModel product, {int quantity = 1}) async {
    try {
      final cart = await getCart();
      final items = List<CartItem>.from(cart.items);

      // Validate quantity
      if (quantity <= 0) {
        print('Warning: Invalid quantity ($quantity), defaulting to 1');
        quantity = 1;
      }

      // Check if item already exists in cart
      final existingIndex = items.indexWhere(
        (item) => item.productId == product.id,
      );

      if (existingIndex != -1) {
        // Update quantity of existing item
        items[existingIndex].quantity += quantity;
        print(
          'Updated quantity for ${product.name} to ${items[existingIndex].quantity}',
        );
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
        print('Added ${product.name} to cart with quantity $quantity');
      }

      final updatedCart = cart.copyWith(items: items);
      await saveCart(updatedCart);
      return updatedCart;
    } catch (e) {
      print('Error adding item to cart: $e');
      // Return original cart on error to maintain state
      return getCart();
    }
  }

  // Remove item from cart
  Future<Cart> removeFromCart(int productId) async {
    try {
      final cart = await getCart();

      // Check if item exists in cart
      final hasItem = cart.items.any((item) => item.productId == productId);
      if (!hasItem) {
        print(
          'Warning: Attempted to remove non-existent item (ID: $productId)',
        );
        return cart; // Return unchanged cart
      }

      // Get item details for logging before removal
      final itemToRemove = cart.items.firstWhere(
        (item) => item.productId == productId,
      );

      final items = cart.items
          .where((item) => item.productId != productId)
          .toList();

      print('Removed ${itemToRemove.name} from cart');

      final updatedCart = cart.copyWith(items: items);
      await saveCart(updatedCart);
      return updatedCart;
    } catch (e) {
      print('Error removing item from cart: $e');
      // Return original cart on error to maintain state
      return getCart();
    }
  }

  // Update item quantity
  Future<Cart> updateQuantity(int productId, int quantity) async {
    try {
      final cart = await getCart();

      // Verify item exists before updating
      final itemIndex = cart.items.indexWhere(
        (item) => item.productId == productId,
      );
      if (itemIndex == -1) {
        print(
          'Warning: Attempted to update quantity for non-existent item (ID: $productId)',
        );
        return cart; // Return unchanged cart
      }

      if (quantity <= 0) {
        print('Removing item as quantity is 0 or negative');
        // Remove item if quantity is 0 or less
        return removeFromCart(productId);
      }

      final items = List<CartItem>.from(cart.items);
      final oldQuantity = items[itemIndex].quantity;
      items[itemIndex].quantity = quantity;

      print(
        'Updated quantity for ${items[itemIndex].name} from $oldQuantity to $quantity',
      );

      final updatedCart = cart.copyWith(items: items);
      await saveCart(updatedCart);
      return updatedCart;
    } catch (e) {
      print('Error updating item quantity: $e');
      // Return original cart on error to maintain state
      return getCart();
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cartKey);
      await prefs.remove(_couponKey);
      print('Cart cleared successfully');
    } catch (e) {
      print('Error clearing cart: $e');
      // Attempt recovery
      await _recoverCart();
    }
  }

  // Apply coupon
  Future<ApiResponse<CouponResponse>> applyCoupon(
    String couponCode,
    double cartTotal,
  ) async {
    try {
      final response = await _apiService.applyCoupon(couponCode, cartTotal);

      if (response.isSuccess && response.data != null) {
        final couponResponse = CouponResponse.fromJson(response.data!);

        if (couponResponse.isValid) {
          // Save coupon to local storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            _couponKey,
            json.encode({
              'coupon_code': couponCode,
              'discount_amount': couponResponse.discountAmount,
            }),
          );
        }

        return ApiResponse.success(couponResponse);
      } else {
        return ApiResponse.error(
          response.error ?? 'Failed to apply coupon',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to apply coupon: $e', 0);
    }
  }

  // Remove coupon
  Future<Cart> removeCoupon() async {
    try {
      final cart = await getCart();

      // Check if there's a coupon to remove
      if (cart.couponCode == null) {
        print('Warning: No coupon applied to remove');
        return cart;
      }

      final currentCode = cart.couponCode;
      final updatedCart = cart.copyWith(couponCode: null, couponDiscount: 0.0);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_couponKey);
      await saveCart(updatedCart);

      print('Successfully removed coupon: $currentCode');
      return updatedCart;
    } catch (e) {
      print('Error removing coupon: $e');
      // Return original cart on error to maintain state
      return getCart();
    }
  }

  // Create order from cart
  Future<ApiResponse<Map<String, dynamic>>> createOrder(
    Cart cart, {
    String? deliveryAddress,
    String? notes,
  }) async {
    try {
      // Validate cart is not empty
      if (cart.items.isEmpty) {
        print('Error: Cannot create order with empty cart');
        return ApiResponse.error('Cannot create order with empty cart', 400);
      }

      // Validate delivery address if required
      if (deliveryAddress == null || deliveryAddress.trim().isEmpty) {
        print('Error: Delivery address is required');
        return ApiResponse.error('Delivery address is required', 400);
      }

      final orderRequest = OrderRequest(
        items: cart.items,
        couponCode: cart.couponCode,
        total: cart.total,
        deliveryAddress: deliveryAddress,
        notes: notes,
      );

      print('Creating order with ${cart.items.length} items...');
      final response = await _apiService.createOrder(orderRequest.toJson());

      if (response.isSuccess) {
        print('Order created successfully. Clearing cart...');
        // Clear cart after successful order
        await clearCart();
      } else {
        print('Failed to create order: ${response.error}');
      }

      return response;
    } catch (e) {
      print('Error creating order: $e');
      return ApiResponse.error('Failed to create order: $e', 0);
    }
  }

  // Get cart item count
  Future<int> getCartItemCount() async {
    try {
      final cart = await getCart();
      return cart.totalItems;
    } catch (e) {
      print('Error getting cart item count: $e');
      return 0;
    }
  }

  // Check if product is in cart
  Future<bool> isInCart(int productId) async {
    try {
      final cart = await getCart();
      return cart.items.any((item) => item.productId == productId);
    } catch (e) {
      print('Error checking if product is in cart: $e');
      return false;
    }
  }

  // Get quantity of specific product in cart
  Future<int> getProductQuantity(int productId) async {
    try {
      final cart = await getCart();

      // Check if product exists in cart
      final itemExists = cart.items.any((item) => item.productId == productId);
      if (!itemExists) {
        print('Product ID $productId not found in cart');
        return 0;
      }

      final item = cart.items.firstWhere((item) => item.productId == productId);

      print('Found quantity ${item.quantity} for product ${item.name} in cart');
      return item.quantity;
    } catch (e) {
      print('Error getting product quantity: $e');
      return 0;
    }
  }
}
