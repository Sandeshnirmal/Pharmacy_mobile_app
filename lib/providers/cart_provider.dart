import 'package:flutter/material.dart';
import '../models/cart_model.dart';
import '../models/cart_item.dart';
import '../models/product_model.dart';

class CartProvider with ChangeNotifier {
  Cart _cart = Cart(items: []);

  Cart get cart => _cart;

  void addItem(ProductModel product, int quantity) {
    // Check if the item already exists in the cart
    int index = _cart.items.indexWhere((item) => item.productId == product.id);

    if (index != -1) {
      // If item exists, update its quantity
      _cart.items[index].quantity =
          (_cart.items[index].quantity ?? 0) + quantity;
    } else {
      // If item does not exist, add new item
      _cart.items.add(
        CartItem(
          productId: product.id,
          name: product.name,
          manufacturer: product.manufacturer ?? 'Unknown',
          price: product.price ?? 0.0,
          mrp: product.mrp ?? (product.price ?? 0.0),
          quantity: quantity,
          imageUrl: product.imageUrl,
          requiresPrescription: product.requiresPrescription ?? false,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(int productId) {
    _cart.items.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void updateItemQuantity(int productId, int newQuantity) {
    int index = _cart.items.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      if (newQuantity > 0) {
        _cart.items[index].quantity = newQuantity;
      } else {
        _cart.items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cart = Cart(items: []);
    notifyListeners();
  }

  double get totalPrice {
    return _cart.items.fold(
      0.0,
      (sum, item) => sum + (item.price ?? 0.0) * (item.quantity ?? 0),
    );
  }

  int get totalItems {
    return _cart.items.fold(0, (sum, item) => sum + (item.quantity ?? 0));
  }
}
