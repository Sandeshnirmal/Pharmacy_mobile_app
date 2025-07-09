import 'package:flutter/material.dart';
import 'AccountScreen.dart';
import 'CartScreen.dart';
import 'ScannerScreen.dart';
//import 'ProductDetailsScreen.dart'; // Import the ProductDetailsScreen
import 'main.dart';

// Assuming these screens exist in your project.
// Replace with your actual paths.
// For demonstration, I'm commenting them out if they don't exist yet.
// import 'package:pharmacy/screens/home_screen.dart'; // Adjust path as needed
// import 'package:pharmacy/screens/cart_screen.dart'; // Adjust path as needed
// import 'package:pharmacy/screens/account_screen.dart'; // Adjust path as needed
// import 'package:pharmacy/screens/scanner_screen.dart'; // Adjust path as needed



// --- Category Model ---
class Category {
  final String id;
  final String name;
  final IconData icon;

  const Category({required this.id, required this.name, required this.icon});
}

// --- CategoryPage Widget ---
class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  final List<Category> categories = const [
    const Category(id: '1', name: 'Prescription Drugs', icon: Icons.medication_liquid),
    const Category(id: '2', name: 'Over-the-Counter', icon: Icons.healing),
    const Category(id: '3', name: 'Vitamins & Supplements', icon: Icons.medication),
    const Category(id: '4', name: 'Personal Care', icon: Icons.shower),
    const Category(id: '5', name: 'Baby Care', icon: Icons.child_care),
    const Category(id: '6', name: 'First Aid', icon: Icons.medical_services),
    const Category(id: '7', name: 'Homeopathy', icon: Icons.biotech),
    const Category(id: '8', name: 'Ayurveda', icon: Icons.grass),
    const Category(id: '9', name: 'Healthcare Devices', icon: Icons.monitor_heart),
    const Category(id: '10', name: 'Pet Care', icon: Icons.pets),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop by Category'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            childAspectRatio: 3 / 2,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return CategoryCard(category: category);
          },
        ),
      ),

      // --- Bottom Navigation Bar ---
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
                // If this is the main nav, you might navigate back to home
                // or just stay if already there.
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const PharmacyHomePage()),
                );
                // print('Home tapped'); // Removed print for production code
              },
              iconSize: 30.0,
              color: Colors.grey[700], // CategoryPage is not Home, so set Home to grey
            ),
            IconButton(
              icon: const Icon(Icons.category_outlined),
              onPressed: () {

              },
              iconSize: 30.0, // Increased icon size
              color: Colors.teal,
            ),
            // This is the floating action button for the scanner
            const SizedBox(width: 48), // The space for the FAB
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
              iconSize: 30.0,
              color: Colors.grey[700],
            ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AccountScreen()),
                );
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ScannerScreen()),
          );
        },
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0), // Makes it circular
        ),
        elevation: 8.0, // Added elevation for the FAB
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
    );
  }
}

// --- CategoryCard Widget (No changes needed here for color, as it uses Theme.of(context).primaryColor) ---
class CategoryCard extends StatelessWidget {
  final Category category;

  const CategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigating to ${category.name} products')),
          );
          // TODO: Implement actual navigation to a ProductListPage
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => ProductListPage(categoryId: category.id, categoryName: category.name),
          //   ),
          // );
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                category.icon,
                size: 40,
                color: Colors.teal, // Explicitly set to teal
              ),
              const SizedBox(height: 10),
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}