import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:pharmacy/screens/home/home_screen.dart';
import 'CheckoutScreen.dart';
import 'LoginScreen.dart';
import 'models/cart_item.dart';
import 'models/cart_model.dart';
import 'services/cart_service.dart';
import 'services/auth_service.dart';
// import 'main.dart';
import 'CategoryPage.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final AuthService _authService = AuthService();
  final TextEditingController _couponCodeController = TextEditingController();

  Cart _cart = Cart();
  bool _isLoading = true;
  bool _isApplyingCoupon = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  @override
  void dispose() {
    _couponCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadCart() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final cart = await _cartService.getCart();
      if (!mounted) return;

      setState(() {
        _cart = cart;
        _couponCodeController.text = cart.couponCode ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      _showErrorToast('Failed to load cart');
    }
  }

  Future<void> _incrementQuantity(int productId) async {
    try {
      final item = _cart.items.firstWhere(
        (item) => item.productId == productId,
      );
      final updatedCart = await _cartService.updateQuantity(
        productId,
        item.quantity + 1,
      );
      setState(() {
        _cart = updatedCart;
      });
    } catch (e) {
      _showErrorToast('Failed to update quantity');
    }
  }

  Future<void> _decrementQuantity(int productId) async {
    try {
      final item = _cart.items.firstWhere(
        (item) => item.productId == productId,
      );
      if (item.quantity > 1) {
        final updatedCart = await _cartService.updateQuantity(
          productId,
          item.quantity - 1,
        );
        setState(() {
          _cart = updatedCart;
        });
      } else {
        await _removeFromCart(productId);
      }
    } catch (e) {
      _showErrorToast('Failed to update quantity');
    }
  }

  Future<void> _removeFromCart(int productId) async {
    try {
      final updatedCart = await _cartService.removeFromCart(productId);
      setState(() {
        _cart = updatedCart;
      });
      _showSuccessToast('Item removed from cart');
    } catch (e) {
      _showErrorToast('Failed to remove item');
    }
  }

  Future<void> _applyCoupon() async {
    if (_couponCodeController.text.trim().isEmpty) {
      _showErrorToast('Please enter a coupon code');
      return;
    }

    setState(() {
      _isApplyingCoupon = true;
    });

    try {
      final response = await _cartService.applyCoupon(
        _couponCodeController.text.trim(),
        _cart.subtotal,
      );

      if (response.isSuccess && response.data != null) {
        if (response.data!.isValid) {
          final updatedCart = _cart.copyWith(
            couponCode: response.data!.couponCode,
            couponDiscount: response.data!.discountAmount,
          );
          await _cartService.saveCart(updatedCart);
          setState(() {
            _cart = updatedCart;
          });
          _showSuccessToast('Coupon applied successfully!');
        } else {
          _showErrorToast(response.data!.message);
        }
      } else {
        _showErrorToast(response.error ?? 'Failed to apply coupon');
      }
    } catch (e) {
      _showErrorToast('Failed to apply coupon');
    } finally {
      setState(() {
        _isApplyingCoupon = false;
      });
    }
  }

  Future<void> _removeCoupon() async {
    try {
      final updatedCart = await _cartService.removeCoupon();
      setState(() {
        _cart = updatedCart;
        _couponCodeController.clear();
      });
      _showSuccessToast('Coupon removed');
    } catch (e) {
      _showErrorToast('Failed to remove coupon');
    }
  }

  Future<void> _proceedToCheckout() async {
    if (_cart.isEmpty) {
      _showErrorToast('Your cart is empty');
      return;
    }

    // Check authentication first
    final isAuthenticated = await _authService.isAuthenticated();
    if (!isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }

    // Check if cart has prescription items - use payment-first flow
    final prescriptionItems = _cart.items
        .where((item) => item.requiresPrescription)
        .toList();
    // if (prescriptionItems.isNotEmpty) {
    //   // Navigate to prescription checkout (payment-first flow)
    //   if (mounted) {
    //     Navigator.push(
    //       context,
    //       MaterialPageRoute(
    //         builder: (context) => PrescriptionCheckoutScreen(
    //           cartItems: _cart.items,
    //           totalAmount: _cart.total,
    //         ),
    //       ),
    //     );
    //   }
    //   return;
    // }

    // Navigate to regular checkout screen for non-prescription items
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CheckoutScreen(cart: _cart)),
      );
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.login, color: Colors.teal.shade600),
            const SizedBox(width: 8),
            const Text('Login Required'),
          ],
        ),
        content: const Text(
          'You need to be logged in to proceed with checkout. Please login or create an account to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text(
          'Are you sure you want to remove all items from your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cartService.clearCart();
              await _loadCart();
              _showSuccessToast('Cart cleared');
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Cart',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (_cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showClearCartDialog(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _cart.isEmpty
          ? _buildEmptyCart()
          : _buildCartContent(),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some medicines to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoryPage()),
              ),
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cart Items List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _cart.items.length,
                  itemBuilder: (context, index) {
                    final item = _cart.items[index];
                    return _buildCartItem(item);
                  },
                ),
                const SizedBox(height: 24),

                // Prescription Notice
                if (_cart.hasRxItems) _buildPrescriptionNotice(),

                // Coupon Code Section
                _buildCouponSection(),
                const SizedBox(height: 24),

                // Price Summary
                _buildPriceSummary(),
              ],
            ),
          ),
        ),
        // Checkout Button
        _buildCheckoutButton(),
      ],
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Medicine Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8.0),
                image: item.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(item.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: item.imageUrl == null
                  ? Icon(
                      Icons.medical_services,
                      color: Colors.teal.shade600,
                      size: 30,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Medicine Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2, // Limit to 2 lines
                    overflow:
                        TextOverflow.ellipsis, // Add ellipsis if overflows
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.manufacturer} ${item.strength ?? ''}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 1, // Limit to 1 line
                    overflow:
                        TextOverflow.ellipsis, // Add ellipsis if overflows
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '₹${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      if (item.mrp > item.price) ...[
                        const SizedBox(width: 8),
                        Text(
                          '₹${item.mrp.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                      if (item.requiresPrescription) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Rx',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Quantity Controls
            Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _decrementQuantity(item.productId),
                      icon: const Icon(Icons.remove_circle_outline),
                      color: Colors.red,
                      iconSize: 24,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _incrementQuantity(item.productId),
                      icon: const Icon(Icons.add_circle_outline),
                      color: Colors.teal,
                      iconSize: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${item.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionNotice() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.medical_services, color: Colors.orange.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prescription Required for Order',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Some items in your cart require a valid prescription. You will be asked to upload your prescription during checkout for order verification.',
                  style: TextStyle(fontSize: 14, color: Colors.orange.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Coupon Code',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          if (_cart.couponCode != null) ...[
            // Applied coupon display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coupon "${_cart.couponCode}" applied',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _removeCoupon,
                    child: const Text('Remove'),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Coupon input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponCodeController,
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: Colors.teal),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isApplyingCoupon ? null : _applyCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: _isApplyingCoupon
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Apply'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPriceRow('Subtotal', '₹${_cart.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          if (_cart.productSavings > 0)
            _buildPriceRow(
              'Product Savings',
              '-₹${_cart.productSavings.toStringAsFixed(2)}',
              color: Colors.green,
            ),
          if (_cart.couponDiscount > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              'Coupon Discount',
              '-₹${_cart.couponDiscount.toStringAsFixed(2)}',
              color: Colors.green,
            ),
          ],
          const SizedBox(height: 8),
          _buildPriceRow('Tax (GST)', '₹${_cart.taxAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildPriceRow('Shipping', 'FREE', color: Colors.green),
          const Divider(height: 24, thickness: 1),
          _buildPriceRow(
            'Total',
            '₹${_cart.total.toStringAsFixed(2)}',
            isTotal: true,
          ),
          if (_cart.totalSavings > 0) ...[
            const SizedBox(height: 8),
            Text(
              'You save ₹${_cart.totalSavings.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: color ?? (isTotal ? Colors.black87 : Colors.grey[700]),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: color ?? (isTotal ? Colors.black87 : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutButton() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _cart.isEmpty ? null : _proceedToCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 2,
            ),
            child: Flexible(
              child: Text(
                'Proceed to Checkout • ₹${_cart.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
