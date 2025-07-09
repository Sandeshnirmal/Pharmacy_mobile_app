import 'package:flutter/material.dart';
// You might need to import your other pages if you want to navigate from the BottomAppBar
 import 'main.dart';
// import 'categories_page.dart';
// import 'cart_screen.dart';
// import 'account_screen.dart';
// import 'scanner_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  // Now accepts product data via its constructor
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _selectedTab = 0; // 0: Description, 1: How to Use, 2: Side Effects

  @override
  Widget build(BuildContext context) {
    // Access product data using widget.product
    final Map<String, dynamic> product = widget.product;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const PharmacyHomePage()),
            );// Go back to the previous screen
          },
        ),
        title: const Text('Medicine Details'),
        centerTitle: true,
        elevation: 0, // Remove shadow from app bar
        backgroundColor: Colors.white, // White app bar
        foregroundColor: Colors.black, // Black icons and text
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image Section
                  Container(
                    width: double.infinity,
                    height: 300, // Fixed height for the image container
                    color: const Color(0xFFF9E7D2), // Light orange background from image
                    child: Center(
                      child: Image.network( // Changed to Image.network for placeholder images
                        product['imageUrl'],
                        fit: BoxFit.contain, // Ensure the image fits within the container
                        height: 250, // Adjust image size within the container
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 250,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          product['name'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Brand
                        Text(
                          'Brand: ${product['brand']}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Generic Name
                        Text(
                          'Generic Name: ${product['genericName']}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Dosage
                        Text(
                          'Dosage',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product['dosage'],
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Ingredients
                        Text(
                          'Ingredients',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Active Ingredient: ${product['activeIngredient']}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Uses
                        Text(
                          'Uses',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product['uses'],
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Tab Bar for Description, How to Use, Side Effects
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildTabButton(0, 'Description'),
                            _buildTabButton(1, 'How to Use'),
                            _buildTabButton(2, 'Side Effects'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Content based on selected tab
                        _buildTabContent(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom action buttons (Add to Cart, Save for Later)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      print('Add to Cart tapped for ${product['name']}');
                      // Add to cart logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                      shadowColor: Colors.blueAccent.withOpacity(0.4),
                    ),
                    child: const Text(
                      'Add to Cart',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      print('Save for Later tapped for ${product['name']}');
                      // Save for later logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: Colors.grey.withOpacity(0.2),
                    ),
                    child: Text(
                      'Save for Later',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 4.0,
        color: Colors.white,
        elevation: 10.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.home_outlined),
              onPressed: () {
                print('Home tapped');
                // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
              },
              iconSize: 30.0,
              color: Colors.grey[700],
            ),
            IconButton(
              icon: const Icon(Icons.category_outlined),
              onPressed: () {
                print('Categories tapped');
                // Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoriesPage()));
              },
              iconSize: 30.0,
              color: Colors.grey[700],
            ),
            const SizedBox(width: 48), // Space for the FAB
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () {
                print('Cart tapped');
                // Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
              },
              iconSize: 30.0,
              color: Colors.grey[700],
            ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                print('Profile tapped');
                // Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountScreen()));
              },
              iconSize: 30.0,
              color: Colors.grey[700],
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('Scanner tapped');
          // Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerScreen()));
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

  Widget _buildTabButton(int index, String title) {
    return TextButton(
      onPressed: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: _selectedTab == index ? FontWeight.bold : FontWeight.normal,
              color: _selectedTab == index ? Colors.blueAccent : Colors.grey[600],
            ),
          ),
          if (_selectedTab == index)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 30, // Underline width
              color: Colors.blueAccent,
            ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    String content = '';
    // Access product data using widget.product
    final Map<String, dynamic> product = widget.product;

    switch (_selectedTab) {
      case 0:
        content = product['description'] ?? 'No description available.'; // Use a description from product data
        break;
      case 1:
        content = product['howToUse'] ?? 'No usage instructions available.'; // Use howToUse from product data
        break;
      case 2:
        content = product['sideEffects'] ?? 'No side effects information available.'; // Use sideEffects from product data
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
      child: Text(
        content,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[700],
          height: 1.5, // Line height
        ),
      ),
    );
  }
}
