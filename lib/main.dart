import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel;
// import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:async'; // Import for StreamSubscription
import 'dart:convert'; // Import for JSON encoding/decoding and base64
// Import for File
import 'package:http/http.dart' as http; // Import for http requests
import 'package:image_picker/image_picker.dart'; // Import for image_picker
// import 'package:carousel_slider/carousel_slider.dart' as carousel;
// import 'package:shimmer/shimmer.dart';
// import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'AccountScreen.dart';
import 'CartScreen.dart';
// import 'ScannerScreen.dart'; // Removed as direct camera access is implemented
import 'ProductDetailsScreen.dart';
import 'ShopPage.dart';
import 'SearchResultsScreen.dart';
import 'screens/prescription_tracking_screen.dart'; // Import for Prescription Tracking
import 'OrderPrescriptionUploadScreen.dart'; // Import for OrderPrescriptionUploadScreen
import 'LoginScreen.dart'; // Import LoginScreen
import 'services/api_service.dart';
import 'services/cart_service.dart';
import 'models/product_model.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'providers/prescription_provider.dart';
import 'providers/cart_provider.dart';
import 'dart:ui' as ui;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // Determine the environment and load the appropriate .env file
  // You can use Flutter build flavors or a simple conditional check
  // For example, to load based on a FLUTTER_ENV environment variable set during build:
  const String flutterEnv = String.fromEnvironment(
    'FLUTTER_ENV',
    defaultValue: 'development',
  );

  if (flutterEnv == 'production') {
    await dotenv.load(fileName: ".env.production");
  } else {
    await dotenv.load(fileName: ".env.development");
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription _logoutSubscription;

  @override
  void initState() {
    super.initState();
    _logoutSubscription = ApiService().onLogout.listen((_) {
      // Navigate to login screen and clear all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    });
  }

  @override
  void dispose() {
    _logoutSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => PrescriptionProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Pharmacy App',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// Calculates a height that is inversely proportional to the screen height.
double calculateInverseHeight(BuildContext context) {
  // --- Define Your Ranges ---
  // The screen height range you want to design for.
  const double minScreenHeight = 600.0; // e.g., a small phone
  const double maxScreenHeight = 1200.0; // e.g., a large tablet

  // The corresponding widget height you want at those screen sizes.
  const double minWidgetHeight = 200.0; // Height on the largest screen
  const double maxWidgetHeight = 300.0; // Height on the smallest screen
  // --------------------------

  final screenHeight = MediaQuery.of(context).size.height;

  // Calculate the percentage of where the current screen height falls within your range.
  final percentage =
      (screenHeight - minScreenHeight) / (maxScreenHeight - minScreenHeight);

  // Use the percentage to interpolate between your min and max widget heights.
  // We use 1.0 - percentage because we want an INVERSE relationship.
  final newHeight = ui.lerpDouble(
    minWidgetHeight,
    maxWidgetHeight,
    1.0 - percentage.clamp(0.0, 1.0),
  );

  return newHeight!;
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuthAndNavigate();
    });
  }

  Future<void> _initializeAuthAndNavigate() async {
    // Ensure the AuthProvider is available in the context
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();

    if (mounted) {
      // Always navigate to PharmacyHomePage initially, allowing exploration without login.
      // Authentication will be handled for specific actions like checkout.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PharmacyHomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.white, // A background color for your splash screen
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
  int _currentBannerIndex = 0;

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
        final paginatedProducts = response.data!;

        setState(() {
          // Store all products for search functionality
          _allProducts = paginatedProducts.products;

          // Get featured products (first 4 products)
          _featuredProducts = paginatedProducts.products.take(4).toList();

          // Get everyday medicines (non-prescription products)
          _everydayProducts = paginatedProducts.products
              .where((product) => !product.requiresPrescription)
              .take(6)
              .toList();

          // Get cold & cough medicines (filter by category or name)
          _coldCoughProducts = paginatedProducts.products
              .where(
                (product) =>
                    product.category?.toLowerCase().contains('cold') == true ||
                    product.category?.toLowerCase().contains('cough') == true ||
                    product.name.toLowerCase().contains('cough') ||
                    product.name.toLowerCase().contains('cold') ||
                    product.name.toLowerCase().contains('fever'),
              )
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

  // Function to handle prescription scanning and OCR
  Future<void> _scanPrescription() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _isLoading = true; // Show loading indicator
        _error = '';
      });

      try {
        final imageBytes = await image.readAsBytes();
        final base64Image = base64Encode(imageBytes);

        var response = await http.post(
          Uri.parse(
            '${dotenv.env['API_BASE_URL']}/api/prescriptions/ocr/analyze/',
          ),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'image': base64Image,
            'filename': image.name, // Include filename if backend needs it
          }),
        );

        if (response.statusCode == 200) {
          final ocrResult = response.body; // Assuming the body is the OCR text

          // Display the OCR result in an AlertDialog
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Prescription Scan Result'),
                content: SingleChildScrollView(
                  child: Text(ocrResult),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Search Products'),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                      _performSearch(ocrResult); // Perform search with OCR result
                    },
                  ),
                  TextButton(
                    child: const Text('Close'),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                  ),
                ],
              );
            },
          );
        } else {
          Fluttertoast.showToast(
            msg: 'OCR API failed with status: ${response.statusCode}',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Error during OCR: $e',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } finally {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  // Search functionality
  void _performSearch(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SearchResultsScreen(searchQuery: query, isFromPrescription: false),
      ),
    );
  }

  // Filter products by category
  void _filterByCategory(String category) {
    final categoryProducts = _allProducts
        .where(
          (product) =>
              product.category?.toLowerCase().contains(
                category.toLowerCase(),
              ) ==
              true,
        )
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
                      subtitle: Text(
                        '${product.manufacturer} - ₹${product.currentBatch?.sellingPrice ?? product.currentSellingPrice}',
                      ),
                      trailing: product.requiresPrescription
                          ? const Icon(
                              Icons.medical_services,
                              color: Colors.red,
                              size: 16,
                            )
                          : const Icon(
                              Icons.shopping_cart,
                              color: Colors.green,
                              size: 16,
                            ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailsScreen(
                              product: product, // Pass ProductModel directly
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
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.local_pharmacy,
                size: 40,
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              // Wrap with Expanded to prevent overflow
              child: const Text(
                'InfxMart',
                style: TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                overflow: TextOverflow.ellipsis, // Add overflow handling
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.teal,
                ),
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
                      maxLines: 1, // Ensure text doesn't overflow vertically
                      overflow:
                          TextOverflow.ellipsis, // Handle horizontal overflow
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                ), // Removed top padding here as it's handled by logo section
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors
                        .grey[100], // Lighter grey for search bar background
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
                            icon: const Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.teal,
                            ),
                            onPressed:
                                _scanPrescription, // Call the new function
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
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14.0,
                        horizontal: 20.0,
                      ),
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
                carousel.CarouselSlider(
                  items: _bannerImages.map((imageUrl) {
                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.teal.shade50,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                        );
                      },
                    );
                  }).toList(),
                  options: carousel.CarouselOptions(
                    height: MediaQuery.of(context).size.height * 0.25,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 3),
                    enlargeCenterPage: true,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentBannerIndex = index;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: AnimatedSmoothIndicator(
                    activeIndex: _currentBannerIndex,
                    count: _bannerImages.length,
                    effect: WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: Colors.teal,
                      dotColor: Colors.grey.shade300,
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
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
              //   child: Container(
              //     height:
              //         MediaQuery.of(context).size.height *
              //         0.25, // Responsive height
              //     width: double.infinity,
              //     decoration: BoxDecoration(
              //       color: Colors
              //           .teal
              //           .shade100, // Placeholder color for the banner
              //       borderRadius: BorderRadius.circular(15.0),
              //       boxShadow: [
              //         BoxShadow(
              //           color: Colors.teal.withValues(
              //             alpha: 0.2,
              //           ), // Subtle teal shadow
              //           spreadRadius: 2,
              //           blurRadius: 8,
              //           offset: const Offset(0, 4),
              //         ),
              //       ],
              //       // Removed AssetImage to avoid errors if not present, relying on network/errorBuilder
              //     ),
              //     child: ClipRRect(
              //       borderRadius: BorderRadius.circular(15.0),
              //       child: Image.network(
              //         'https://placehold.co/400x180/ADD8E6/000000?text=Pharmacy+Banner',
              //         fit: BoxFit.cover,
              //         errorBuilder: (context, error, stackTrace) => Container(
              //           color: Colors.teal.shade100,
              //           child: const Center(
              //             child: Text(
              //               'Promotional Banner',
              //               style: TextStyle(
              //                 color: Colors.teal,
              //                 fontSize: 18,
              //                 fontWeight: FontWeight.bold,
              //               ),
              //             ),
              //           ),
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 15),

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
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 25),

              // Featured Medicines Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 17.0),
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
                height: calculateInverseHeight(context),
                // Responsive height
                // Responsive height
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.teal),
                      )
                    : _error.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error,
                              style: const TextStyle(color: Colors.red),
                            ),
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
                          final product = _featuredProducts[index];
                          return ProductCard(
                            product: product, // Pass ProductModel directly
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProductDetailsScreen(product: product),
                                ),
                              );
                            },
                            onAddToCart: () => _addToCart(product),
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
                      onPressed: _loadTrendingProducts,
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
              const SizedBox(height: 17),
              SizedBox(
                height: calculateInverseHeight(context), // Responsive height
                child: _isLoadingTrending
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.teal),
                      )
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
                          final product = _trendingProducts[index];
                          return ProductCard(
                            product: product, // Pass ProductModel directly
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProductDetailsScreen(product: product),
                                ),
                              );
                            },
                            onAddToCart: () => _addToCart(product),
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
              const SizedBox(height: 20),
              SizedBox(
                height: calculateInverseHeight(context), // Responsive height
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.teal),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: _everydayProducts.length,
                        itemBuilder: (context, index) {
                          final product = _everydayProducts[index];
                          return ProductCard(
                            product: product, // Pass ProductModel directly
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProductDetailsScreen(product: product),
                                ),
                              );
                            },
                            onAddToCart: () => _addToCart(product),
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
              const SizedBox(height: 17),
              SizedBox(
                height: calculateInverseHeight(context), // Responsive height
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.teal),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: _coldCoughProducts.length,
                        itemBuilder: (context, index) {
                          final product = _coldCoughProducts[index];
                          return ProductCard(
                            product: product, // Pass ProductModel directly
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProductDetailsScreen(product: product),
                                ),
                              );
                            },
                            onAddToCart: () => _addToCart(product),
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
        color: Colors.white,
        elevation: 10.0, // Added elevation for a subtle lift
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceEvenly, // Distribute items evenly
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.home_outlined),
              onPressed: () {
                // This is the current page, so no navigation needed
                // Already on home screen
              },
              iconSize: 30.0, // Increased icon size
              color:
                  Colors.teal, // Highlight Home icon as it's the current screen
            ),
            IconButton(
              icon: const Icon(Icons.category_outlined),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ShopPage()),
                );
              },
              iconSize: 30.0, // Increased icon size
              color: Colors.grey[700],
            ),
            IconButton(
              icon: const Icon(
                Icons.upload_file,
              ), // Icon for Prescription Tracking/Review
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrescriptionTrackingScreen(),
                  ),
                );
              },
              iconSize: 30.0, // Increased icon size
              color: Colors.grey[700],
            ),
            // IconButton(
            //   icon: const Icon(
            //     Icons.upload_file,
            //   ), // Icon for Upload Prescription
            //   onPressed: () {
            //     Navigator.pushReplacement(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => const OrderPrescriptionUploadScreen(),
            //       ),
            //     );
            //   },
            //   iconSize: 30.0, // Increased icon size
            //   color: Colors.grey[700],
            // ),
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
                  MaterialPageRoute(
                    builder: (context) => const AccountScreen(),
                  ),
                );
              },
              iconSize: 30.0, // Increased icon size
              color: Colors.grey[700],
            ),
          ],
        ),
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
            style: TextStyle(
              color: Colors.teal.shade800,
              fontWeight: FontWeight.w600,
            ), // Teal text for chips
          ),
          backgroundColor:
              Colors.teal.shade50, // Light teal background for chips
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
            side: BorderSide(color: Colors.teal.shade100), // Subtle border
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 8.0,
          ), // Slightly more padding
        ),
      ),
    );
  }
}

// Custom Widget for Product Cards
class ProductCard extends StatelessWidget {
  final ProductModel product; // Changed to ProductModel
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.product, // Changed to ProductModel
    this.onTap,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Wrap with GestureDetector to detect taps
      onTap: onTap, // Assign the onTap callback
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4, // Responsive width
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15.0),
              ),
              child: Image.network(
                product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? product.imageUrl!
                    : 'https://via.placeholder.com/150', // Default image if imageUrl is null or empty
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, color: Colors.grey), // More appropriate icon
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.manufacturer,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              product.currentBatch?.onlineSellingPrice !=
                                          null &&
                                      product.currentBatch!.onlineSellingPrice >
                                          0
                                  ? '₹${product.currentBatch!.onlineSellingPrice.toStringAsFixed(2)}'
                                  : (product.currentBatch?.sellingPrice !=
                                                null &&
                                            product.currentBatch!.sellingPrice >
                                                0
                                        ? '₹${product.currentBatch!.sellingPrice.toStringAsFixed(2)}'
                                        : '₹${product.currentSellingPrice.toStringAsFixed(2)}'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if ((product.currentBatch?.onlineMrpPrice != null &&
                                    product.currentBatch!.onlineMrpPrice >
                                        (product
                                                    .currentBatch!
                                                    .onlineSellingPrice >
                                                0
                                            ? product
                                                  .currentBatch!
                                                  .onlineSellingPrice
                                            : (product
                                                          .currentBatch!
                                                          .sellingPrice >
                                                      0
                                                  ? product
                                                        .currentBatch!
                                                        .sellingPrice
                                                  : product
                                                        .currentSellingPrice))) ||
                                (product.currentBatch?.mrp != null &&
                                    product.currentBatch!.mrp >
                                        (product
                                                    .currentBatch!
                                                    .onlineSellingPrice >
                                                0
                                            ? product
                                                  .currentBatch!
                                                  .onlineSellingPrice
                                            : (product
                                                          .currentBatch!
                                                          .sellingPrice >
                                                      0
                                                  ? product
                                                        .currentBatch!
                                                        .sellingPrice
                                                  : product
                                                        .currentSellingPrice))))
                              Text(
                                '₹${product.currentBatch?.onlineMrpPrice != null && product.currentBatch!.onlineMrpPrice > 0 ? product.currentBatch!.onlineMrpPrice.toStringAsFixed(2) : product.currentBatch?.mrp.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Display discount percentage
                        if (product.currentBatch != null &&
                            ((product.currentBatch!.onlineDiscountPercentage != null && product.currentBatch!.onlineDiscountPercentage! > 0) ||
                                (product.currentBatch!.discountPercentage != null && product.currentBatch!.discountPercentage! > 0)))
                          Text(
                            '${(product.currentBatch!.onlineDiscountPercentage ?? product.currentBatch!.discountPercentage)?.toStringAsFixed(0)}% off',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (product.requiresPrescription == true) ...[
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
                              'Prescription Required',
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
                    const Spacer(),
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
                            style: TextStyle(
                              fontSize: 10, // Reduced font size
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1, // Ensure text doesn't overflow
                            overflow: TextOverflow
                                .ellipsis, // Handle overflow with ellipsis
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
