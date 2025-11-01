import 'package:flutter/material.dart';
import 'AccountScreen.dart';
import 'CartScreen.dart';
import 'ScannerScreen.dart';
import 'SearchResultsScreen.dart';
import 'ProductDetailsScreen.dart';
import 'main.dart';
import 'services/api_service.dart';
import 'models/product_model.dart'; // Assuming this exists
import 'models/category_model.dart'; // For category filters

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  bool _isLoadingProducts = true;
  bool _isLoadingCategories = true;
  String? _errorProducts;
  String? _errorCategories;

  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 10; // Number of products per page

  CategoryModel? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchCategories();
  }

  Future<void> _fetchProducts({int page = 1, String? categoryId, String? searchQuery}) async {
    setState(() {
      _isLoadingProducts = true;
      _errorProducts = null;
    });

    final result = await _apiService.getProducts(
      page: page,
      pageSize: _pageSize,
      categoryId: categoryId,
      searchQuery: searchQuery,
    );

    if (result.isSuccess) {
      setState(() {
        _products = result.data!.products; // Assuming API returns a paginated response with a 'products' list
        _currentPage = result.data!.currentPage;
        _totalPages = result.data!.totalPages;
        _isLoadingProducts = false;
      });
    } else {
      setState(() {
        _errorProducts = result.error;
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _errorCategories = null;
    });

    final result = await _apiService.getCategories();
    if (result.isSuccess) {
      setState(() {
        _categories = result.data!;
        _isLoadingCategories = false;
      });
    } else {
      setState(() {
        _errorCategories = result.error;
        _isLoadingCategories = false;
      });
    }
  }

  void _performSearch(String query) {
    _fetchProducts(searchQuery: query);
  }

  void _onCategorySelected(CategoryModel? category) {
    setState(() {
      _selectedCategory = category;
      _currentPage = 1; // Reset to first page when category changes
    });
    _fetchProducts(categoryId: category?.id?.toString());
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
      });
      _fetchProducts(page: page, categoryId: _selectedCategory?.id?.toString(), searchQuery: _searchController.text);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Shop All Products'),
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
                hintText: 'Search for products...',
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.teal,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ScannerScreen(),
                          ),
                        );
                      },
                      tooltip: 'Scan Prescription',
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch(''); // Clear search results
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
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
              ),
              onSubmitted: _performSearch,
            ),
          ),

          // Category Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: _isLoadingCategories
                ? const Center(child: CircularProgressIndicator())
                : _errorCategories != null
                    ? Text('Error loading categories: $_errorCategories')
                    : DropdownButtonFormField<CategoryModel>(
                        decoration: InputDecoration(
                          labelText: 'Filter by Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        value: _selectedCategory,
                        hint: const Text('All Categories'),
                        onChanged: _onCategorySelected,
                        items: [
                          const DropdownMenuItem<CategoryModel>(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ..._categories.map((category) => DropdownMenuItem<CategoryModel>(
                            value: category,
                            child: Text(category.name),
                          )),
                        ],
                      ),
          ),

          // Products Grid
          Expanded(
            child: _isLoadingProducts
                ? const Center(child: CircularProgressIndicator())
                : _errorProducts != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: $_errorProducts'),
                            ElevatedButton(
                              onPressed: _fetchProducts,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _products.isEmpty
                        ? const Center(child: Text('No products found.'))
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.75, // Adjust as needed for product cards
                                ),
                            itemCount: _products.length,
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              return _buildProductCard(product);
                            },
                          ),
          ),

          // Pagination Controls
          if (_totalPages > 1)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                  ),
                  Text('Page $_currentPage of $_totalPages'),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PharmacyHomePage(),
                  ),
                );
              },
              iconSize: 30.0,
              color: Colors.grey[700],
            ),
            IconButton(
              icon: const Icon(Icons.category),
              onPressed: () {
                // This will now navigate to the ShopPage itself
                // No need to push a new route if already on ShopPage
              },
              iconSize: 30.0,
              color: Colors.teal, // Highlight if this is the active page
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
                  MaterialPageRoute(
                    builder: (context) => const AccountScreen(),
                  ),
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

  Widget _buildProductCard(ProductModel product) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Navigate to product details screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Image.network(
                    product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? product.imageUrl!
                        : 'https://via.placeholder.com/150', // Default image if imageUrl is null or empty
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 50), // More appropriate icon
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${product.currentSellingPrice.toStringAsFixed(2)} Rs', // Use currentSellingPrice instead of price
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Display discount percentage
              if (product.currentBatch != null &&
                  ((product.currentBatch!.onlineDiscountPercentage != null && product.currentBatch!.onlineDiscountPercentage! > 0) ||
                      (product.currentBatch!.discountPercentage != null && product.currentBatch!.discountPercentage! > 0)))
                Text(
                  '${(product.currentBatch!.onlineDiscountPercentage ?? product.currentBatch!.discountPercentage)?.toStringAsFixed(0)}% off',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12, // Smaller font for discount
                  ),
                ),
              // Add to cart button or other actions
            ],
          ),
        ),
      ),
    );
  }
}
