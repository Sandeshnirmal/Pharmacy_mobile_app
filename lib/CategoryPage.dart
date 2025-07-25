import 'package:flutter/material.dart';
import 'AccountScreen.dart';
import 'CartScreen.dart';
import 'ScannerScreen.dart';
import 'SearchResultsScreen.dart';
import 'main.dart';

// --- Category Model ---
class Category {
  final String id;
  final String name;
  final IconData icon;

  const Category({required this.id, required this.name, required this.icon});
}

// --- CategoryPage Widget ---
class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final TextEditingController _searchController = TextEditingController();
  
  final List<Category> categories = const [
    Category(id: '1', name: 'Prescription Drugs', icon: Icons.medication_liquid),
    Category(id: '2', name: 'Over-the-Counter', icon: Icons.healing),
    Category(id: '3', name: 'Vitamins & Supplements', icon: Icons.medication),
    Category(id: '4', name: 'Personal Care', icon: Icons.shower),
    Category(id: '5', name: 'Baby Care', icon: Icons.child_care),
    Category(id: '6', name: 'First Aid', icon: Icons.medical_services),
    Category(id: '7', name: 'Homeopathy', icon: Icons.biotech),
    Category(id: '8', name: 'Ayurveda', icon: Icons.grass),
    Category(id: '9', name: 'Healthcare Devices', icon: Icons.monitor_heart),
    Category(id: '10', name: 'Pet Care', icon: Icons.pets),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchCategory(String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          searchQuery: categoryName,
          isFromPrescription: false,
        ),
      ),
    );
  }

  void _performSearch(String query) {
    if (query.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsScreen(
            searchQuery: query,
            isFromPrescription: false,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Shop by Category'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search medicines by category...',
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt_outlined, color: Colors.teal),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ScannerScreen()),
                        );
                      },
                      tooltip: 'Scan Prescription',
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Colors.teal, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              onSubmitted: _performSearch,
            ),
          ),

          // Categories Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _buildCategoryCard(category);
                },
              ),
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const PharmacyHomePage()),
                );
              },
              iconSize: 30.0,
              color: Colors.grey[700],
            ),
            IconButton(
              icon: const Icon(Icons.category),
              onPressed: () {},
              iconSize: 30.0,
              color: Colors.teal,
            ),
            const SizedBox(width: 48), // Space for FAB
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
              iconSize: 30.0,
              color: Colors.grey[700],
            ),
            IconButton(
              icon: const Icon(Icons.person_outlined),
              onPressed: () {
                Navigator.push(
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScannerScreen()),
          );
        },
        backgroundColor: Colors.teal,
        elevation: 8.0,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          _searchCategory(category.name);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.teal.shade50,
                Colors.teal.shade100,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  category.icon,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
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
