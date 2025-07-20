import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:carousel_slider/carousel_slider.dart' as carousel;
// import 'package:shimmer/shimmer.dart';
// import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'AccountScreen.dart';
import 'CartScreen.dart';
import 'ScannerScreen.dart';
import 'ProductDetailsScreen.dart';
import 'CategoryPage.dart';
import 'SearchResultsScreen.dart';
import 'services/api_service.dart';
import 'services/cart_service.dart';
import 'models/product_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharmacy App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to the PharmacyHomePage after 3 seconds
    // This duration is set to 3 seconds as requested.
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          // Changed navigation target from LoginPage to PharmacyHomePage
          MaterialPageRoute(builder: (context) => const PharmacyHomePage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // A background color for your splash screen
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your app logo for the splash screen
            Image.asset(
              'assets/images/full_logo.png', // Placeholder for your app logo
              height: 300,
              width: 300,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.local_pharmacy,
                size: 150,
                color: Colors.white, // White icon on teal background
              ),
            ),


            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
          ],
        ),
      ),
    );
  }
}


class PharmacyHomePage extends StatefulWidget {
  const PharmacyHomePage({super.key});

  @override
  State<PharmacyHomePage> createState() => _PharmacyHomePageState();
}

class _PharmacyHomePageState extends State<PharmacyHomePage> {
  final ApiService _apiService = ApiService();
  final CartService _cartService = CartService();
  final TextEditingController _searchController = TextEditingController();
  // final carousel.CarouselController _carouselController = carousel.CarouselController();

  List<ProductModel> _featuredProducts = [];
  List<ProductModel> _everydayProducts = [];
  List<ProductModel> _coldCoughProducts = [];
  List<ProductModel> _trendingProducts = [];
  List<ProductModel> _allProducts = [];
  List<String> _bannerImages = [];
  List<String> _categories = [];

  bool _isLoading = true;
  bool _isLoadingTrending = false;
  String _error = '';
  int _cartItemCount = 0;
  // int _currentBannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCartCount();
    _loadBanners();
    _loadCategories();
  }

  Future<void> _loadCartCount() async {
    try {
      final count = await _cartService.getCartItemCount();
      setState(() {
        _cartItemCount = count;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      // Fetch products from API
      final response = await _apiService.getProducts();

      if (response.isSuccess && response.data != null) {
        final allProducts = response.data!;

        setState(() {
          // Store all products for search functionality
          _allProducts = allProducts;

          // Get featured products (first 4 products)
          _featuredProducts = allProducts.take(4).toList();

          // Get everyday medicines (non-prescription products)
          _everydayProducts = allProducts
              .where((product) => !product.requiresPrescription)
              .take(6)
              .toList();

          // Get cold & cough medicines (filter by category or name)
          _coldCoughProducts = allProducts
              .where((product) =>
                  product.category?.toLowerCase().contains('cold') == true ||
                  product.category?.toLowerCase().contains('cough') == true ||
                  product.name.toLowerCase().contains('cough') ||
                  product.name.toLowerCase().contains('cold') ||
                  product.name.toLowerCase().contains('fever'))
              .take(6)
              .toList();

          _isLoading = false;
        });

        // Load trending products after main products are loaded
        _loadTrendingProducts();
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load products';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  // Search functionality
  void _performSearch(String query) {
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

  // Filter products by category
  void _filterByCategory(String category) {
    final categoryProducts = _allProducts
        .where((product) =>
            product.category?.toLowerCase().contains(category.toLowerCase()) == true)
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$category Medicines'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: categoryProducts.isEmpty
              ? const Center(child: Text('No products found in this category'))
              : ListView.builder(
                  itemCount: categoryProducts.length,
                  itemBuilder: (context, index) {
                    final product = categoryProducts[index];
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text('${product.manufacturer} - ₹${product.price}'),
                      trailing: product.requiresPrescription
                          ? const Icon(Icons.medical_services, color: Colors.red, size: 16)
                          : const Icon(Icons.shopping_cart, color: Colors.green, size: 16),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailsScreen(
                              product: _productToMap(product),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Add to cart functionality
  Future<void> _addToCart(ProductModel product) async {
    try {
      await _cartService.addToCart(product);
      await _loadCartCount();

      // Show success toast
      Fluttertoast.showToast(
        msg: '${product.name} added to cart',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      // Show error toast
      Fluttertoast.showToast(
        msg: 'Failed to add item to cart',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // Load banner images
  Future<void> _loadBanners() async {
    // For now, use placeholder banners. In production, these would come from API
    setState(() {
      _bannerImages = [
        'https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?w=800&h=300&fit=crop',
        'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800&h=300&fit=crop',
        'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=800&h=300&fit=crop',
      ];
    });
  }

  // Load categories
  Future<void> _loadCategories() async {
    // For now, use static categories. In production, these would come from API
    setState(() {
      _categories = [
        'Pain Relief',
        'Diabetes',
        'Antibiotics',
        'Vitamins',
        'Cardiovascular',
        'Respiratory',
        'Digestive',
        'Skin Care',
      ];
    });
  }

  // Load trending products
  Future<void> _loadTrendingProducts() async {
    if (_isLoadingTrending) return;

    setState(() {
      _isLoadingTrending = true;
    });

    try {
      // For now, use featured products as trending. In production, call trending API
      setState(() {
        _trendingProducts = _featuredProducts.take(6).toList();
        _isLoadingTrending = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTrending = false;
      });
    }
  }

  // Convert ProductModel to Map for compatibility with existing UI
  Map<String, dynamic> _productToMap(ProductModel product) {
    return {
      'id': product.id,
      'name': product.name,
      'brand': product.manufacturer,
      'genericName': product.genericName ?? product.name,
      'dosage': product.strength ?? 'N/A',
      'activeIngredient': product.genericName ?? 'N/A',
      'uses': product.description ?? 'Medicine for health treatment',
      'description': product.description ?? 'Quality medicine from trusted manufacturer',
      'howToUse': 'Follow doctor\'s prescription or package instructions',
      'sideEffects': 'Consult doctor if any adverse effects occur',
      'imageUrl': product.imageUrl ?? 'https://placehold.co/150x150/F0E6D2/000000?text=${Uri.encodeComponent(product.name)}',
      'price': product.price.toStringAsFixed(2),
      'mrp': product.mrp.toStringAsFixed(2),
      'inStock': product.stockQuantity > 0,
      'requiresPrescription': product.requiresPrescription,
    };
  }






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ensure the main page background is white
      appBar: AppBar(
        toolbarHeight: 60,
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'assets/images/infxmart_logo.png',
              height: 40,
              width: 40,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_pharmacy, size: 40, color: Colors.teal),
            ),
            const SizedBox(width: 8),
            const Text(
              'InfxMart',
              style: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.teal),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              ),
              if (_cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Search Bar Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0), // Removed top padding here as it's handled by logo section
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100], // Lighter grey for search bar background
                  borderRadius: BorderRadius.circular(25.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3), // subtle shadow
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search medicines or scan prescription...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                          },
                        ),
                      ],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _performSearch(value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Banner Section
            if (_bannerImages.isNotEmpty) ...[
              Container(
                height: 180,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    _bannerImages.first,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.teal.shade50,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_pharmacy,
                                size: 40,
                                color: Colors.teal.shade600,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Health & Wellness',
                                style: TextStyle(
                                  color: Colors.teal.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your trusted pharmacy partner',
                                style: TextStyle(
                                  color: Colors.teal.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Categories Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                height: 40, // Height for horizontal category list
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    return CategoryChip(
                      label: _categories[index],
                      onTap: () => _filterByCategory(_categories[index]),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Promotional Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.teal.shade100, // Placeholder color for the banner
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withValues(alpha: 0.2), // Subtle teal shadow
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  // Removed AssetImage to avoid errors if not present, relying on network/errorBuilder
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: Image.network(
                    'https://placehold.co/400x180/ADD8E6/000000?text=Pharmacy+Banner',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.teal.shade100,
                      child: const Center(
                        child: Text(
                          'Promotional Banner',
                          style: TextStyle(
                            color: Colors.teal,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Offer Text
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '15% off',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'On all health products',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Featured Medicines Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Featured Medicines',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 220, // Height for horizontal product list
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                  : _error.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_error, style: const TextStyle(color: Colors.red)),
                              ElevatedButton(
                                onPressed: _loadProducts,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _featuredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _productToMap(_featuredProducts[index]);
                            return ProductCard(
                              imageAsset: product['imageUrl'],
                              productName: product['name'],
                              brandName: product['brand'],
                              price: product['price'],
                              mrp: product['mrp'],
                              requiresPrescription: product['requiresPrescription'],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailsScreen(product: product),
                                  ),
                                );
                              },
                              onAddToCart: () => _addToCart(_featuredProducts[index]),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 20),

            // Trending Products Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Trending Now',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _loadTrendingProducts(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Refresh',
                          style: TextStyle(color: Colors.teal.shade600),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.refresh,
                          size: 16,
                          color: Colors.teal.shade600,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 220,
              child: _isLoadingTrending
                  ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                  : _trendingProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.trending_up,
                                size: 40,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No trending products yet',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _trendingProducts.length,
                          itemBuilder: (context, index) {
                            final product = _productToMap(_trendingProducts[index]);
                            return ProductCard(
                              imageAsset: product['imageUrl'],
                              productName: product['name'],
                              brandName: product['brand'],
                              price: product['price'],
                              mrp: product['mrp'],
                              requiresPrescription: product['requiresPrescription'],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailsScreen(product: product),
                                  ),
                                );
                              },
                              onAddToCart: () => _addToCart(_trendingProducts[index]),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 20),

            // Everyday Medicines Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Everyday Medicines',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 220, // Height for horizontal product list
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _everydayProducts.length,
                      itemBuilder: (context, index) {
                        final product = _productToMap(_everydayProducts[index]);
                        return ProductCard(
                          imageAsset: product['imageUrl'],
                          productName: product['name'],
                          brandName: product['brand'],
                          price: product['price'],
                          mrp: product['mrp'],
                          requiresPrescription: product['requiresPrescription'],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailsScreen(product: product),
                              ),
                            );
                          },
                          onAddToCart: () => _addToCart(_everydayProducts[index]),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),

            // Cold and Cough Medicine Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Cold and Cough Medicine',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 220, // Height for horizontal product list
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _coldCoughProducts.length,
                      itemBuilder: (context, index) {
                        final product = _productToMap(_coldCoughProducts[index]);
                        return ProductCard(
                          imageAsset: product['imageUrl'],
                          productName: product['name'],
                          brandName: product['brand'],
                          price: product['price'],
                          mrp: product['mrp'],
                          requiresPrescription: product['requiresPrescription'],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailsScreen(product: product),
                              ),
                            );
                          },
                          onAddToCart: () => _addToCart(_coldCoughProducts[index]),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
        ),
      ),
      // Modified Bottom Navigation Bar
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
                // This is the current page, so no navigation needed
                // Already on home screen
              },
              iconSize: 30.0, // Increased icon size
              color: Colors.teal, // Highlight Home icon as it's the current screen
            ),
            IconButton(
              icon: const Icon(Icons.category_outlined),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CategoryPage()),
                );
              },
              iconSize: 30.0, // Increased icon size
              color: Colors.grey[700],
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
              iconSize: 30.0, // Increased icon size
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
          borderRadius: BorderRadius.circular(30.0), // Makes it circular
        ),
        elevation: 8.0, // Added elevation for the FAB
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
    );
  }
}

// Custom Widget for Category Chips
class CategoryChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const CategoryChip({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Chip(
          label: Text(
            label,
            style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.w600), // Teal text for chips
          ),
          backgroundColor: Colors.teal.shade50, // Light teal background for chips
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
            side: BorderSide(color: Colors.teal.shade100), // Subtle border
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // Slightly more padding
        ),
      ),
    );
  }
}

// Custom Widget for Product Cards
class ProductCard extends StatelessWidget {
  final String imageAsset;
  final String productName;
  final String brandName;
  final String? price;
  final String? mrp;
  final bool? requiresPrescription;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.imageAsset,
    required this.productName,
    required this.brandName,
    this.price,
    this.mrp,
    this.requiresPrescription,
    this.onTap,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector( // Wrap with GestureDetector to detect taps
      onTap: onTap, // Assign the onTap callback
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 15.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15.0)),
              child: Image.network(
                imageAsset,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    brandName,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Price Row
                  if (price != null) ...[
                    Row(
                      children: [
                        Text(
                          '₹$price',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.teal,
                          ),
                        ),
                        if (mrp != null && mrp != price) ...[
                          const SizedBox(width: 8),
                          Text(
                            '₹$mrp',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Prescription indicator
                  if (requiresPrescription == true) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Prescription Required',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Add to Cart Button
                  if (onAddToCart != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onAddToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 1,
                        ),
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
