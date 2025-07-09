import 'package:flutter/material.dart';
// You might need to import your other pages if you want to navigate from the BottomAppBar
import 'main.dart';
import 'AccountScreen.dart';
//import 'CartScreen.dart';
import 'ScannerScreen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Sample cart items with initial quantities
  final List<Map<String, dynamic>> _cartItems = [
    {'name': 'Ibuprofen', 'dosage': '100mg', 'quantity': 2, 'price': 10.00, 'image': 'assets/medicine_bottle.png'},
    {'name': 'Paracetamol', 'dosage': '500mg', 'quantity': 1, 'price': 5.00, 'image': 'assets/medicine_bottle.png'},
    {'name': 'Loratadine', 'dosage': '10mg', 'quantity': 3, 'price': 5.00, 'image': 'assets/medicine_bottle.png'},
  ];

  // Placeholder for coupon code
  final TextEditingController _couponCodeController = TextEditingController();

  @override
  void dispose() {
    _couponCodeController.dispose();
    super.dispose();
  }

  void _incrementQuantity(int index) {
    setState(() {
      _cartItems[index]['quantity']++;
    });
  }

  void _decrementQuantity(int index) {
    setState(() {
      if (_cartItems[index]['quantity'] > 1) {
        _cartItems[index]['quantity']--;
      } else {
        // Optionally remove item if quantity drops to 0 or less
        _cartItems.removeAt(index);
      }
    });
  }

  double _calculateSubtotal() {
    double subtotal = 0.0;
    for (var item in _cartItems) {
      subtotal += item['quantity'] * item['price'];
    }
    return subtotal;
  }

  double _calculateShipping() {
    // For simplicity, a fixed shipping cost. In a real app, this would be dynamic.
    return 5.00;
  }

  double _calculateTotal() {
    return _calculateSubtotal() + _calculateShipping();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Cart'),
        centerTitle: true,
        elevation: 0, // Remove shadow from app bar
        backgroundColor: Colors.white, // White app bar
        foregroundColor: Colors.black, // Black icons and text
      ),
      body: Column(
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
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return Card( // Use Card for a nicer look
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 2, // Subtle shadow
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15), // Rounded corners
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // Item Image
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100], // Lighter background for image container
                                  borderRadius: BorderRadius.circular(10),
                                  image: DecorationImage(
                                    image: AssetImage(item['image']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Item Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87, // Slightly darker text
                                      ),
                                    ),
                                    Text(
                                      item['dosage'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Quantity Controls
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue[50], // Light blue background for quantity controls
                                  borderRadius: BorderRadius.circular(20), // More rounded
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove), // Simpler remove icon
                                      onPressed: () => _decrementQuantity(index),
                                      color: Colors.blueAccent, // Blue icons
                                      iconSize: 20,
                                    ),
                                    Text(
                                      '${item['quantity']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add), // Simpler add icon
                                      onPressed: () => _incrementQuantity(index),
                                      color: Colors.blueAccent, // Blue icons
                                      iconSize: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Coupon Code Input
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white, // White background for input
                      borderRadius: BorderRadius.circular(15), // More rounded
                      border: Border.all(color: Colors.grey[300]!),
                      boxShadow: [ // Subtle shadow for input field
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _couponCodeController,
                      decoration: InputDecoration(
                        hintText: 'Enter coupon code',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Price Summary
                  _buildPriceRow('Subtotal', '\$${_calculateSubtotal().toStringAsFixed(2)}'),
                  const SizedBox(height: 12),
                  _buildPriceRow('Shipping', '\$${_calculateShipping().toStringAsFixed(2)}'),
                  const SizedBox(height: 12),
                  Divider( // Divider for visual separation
                    height: 1,
                    thickness: 1,
                    color: Colors.grey[300],
                    indent: 0,
                    endIndent: 0,
                  ),
                  const SizedBox(height: 12),
                  _buildPriceRow('Total', '\$${_calculateTotal().toStringAsFixed(2)}', isTotal: true),
                ],
              ),
            ),
          ),
          // Checkout Button (at the bottom)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle Checkout button press
                  print('Checkout tapped!');
                  print('Coupon code: ${_couponCodeController.text}');
                  // Navigate to checkout process or payment gateway
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent, // A nice blue for the button
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15), // More rounded button
                  ),
                  elevation: 5,
                  shadowColor: Colors.blueAccent.withOpacity(0.4), // Blue shadow
                ),
                child: const Text(
                  'Checkout',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 4.0, // Reduced notchMargin from 8.0 to 4.0
        color: Colors.white,
        elevation: 10.0, // Added elevation for a subtle lift
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.home_outlined),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const PharmacyHomePage()),
                );
              },
              iconSize: 30.0, // Increased icon size
              color: Colors.grey[700], // Highlight Home icon as it's the current screen
            ),
            IconButton(
              icon: const Icon(Icons.category_outlined),
              onPressed: () {
                // Handle Categories button press
                print('Categories tapped');
                // Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoriesPage()));
              },
              iconSize: 30.0, // Increased icon size
              color: Colors.grey[700],
            ),
            // This is the floating action button for the scanner
            const SizedBox(width: 48), // The space for the FAB
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () {

              },
              iconSize: 30.0, // Increased icon size
              color: Colors.teal,
            ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AccountScreen()),
                );
              },
              iconSize: 30.0, // Increased icon size
              color: Colors.grey[700],
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ScannerScreen()),
          );
        },
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        elevation: 8.0,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
