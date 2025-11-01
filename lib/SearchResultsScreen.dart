import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'models/product_model.dart';
import 'services/api_service.dart';
import 'services/cart_service.dart';
import 'ProductDetailsScreen.dart';
import 'CartScreen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String searchQuery;
  final List<String>? extractedMedicines; // From prescription scanning
  final bool isFromPrescription;
  final int? prescriptionId; // For direct prescription-based search
  final int? categoryId; // New: For category-based product listing

  const SearchResultsScreen({
    super.key,
    required this.searchQuery,
    this.extractedMedicines,
    this.isFromPrescription = false,
    this.prescriptionId,
    this.categoryId, // Initialize new parameter
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final ApiService _apiService = ApiService();
  final CartService _cartService = CartService();
  final TextEditingController _searchController = TextEditingController();

  List<ProductModel> _searchResults = [];
  List<ProductModel> _allProducts = [];
  bool _isLoading = true;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
    _currentQuery = widget.searchQuery;
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isFromPrescription && widget.prescriptionId != null) {
        // Load prescription-based products using medicine suggestions API
        await _loadPrescriptionBasedProducts();
      } else {
        // Load products for regular search, using categoryId or searchQuery
        final response = await _apiService.getProducts(
          categoryId: widget.categoryId?.toString(), // Pass category ID if available
          searchQuery: widget.categoryId == null
              ? _currentQuery
              : null, // Only pass searchQuery if no categoryId
        );
        if (response.isSuccess && response.data != null) {
          setState(() {
            _allProducts = response.data!.products;
            _searchResults = response.data!.products; // Directly set search results as they are already filtered by API
          });
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error loading products: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPrescriptionBasedProducts() async {
    try {
      // Use the new prescription products API
      final prescriptionProductsResponse = await _apiService
          .getPrescriptionProducts(widget.prescriptionId!);

      if (prescriptionProductsResponse.isSuccess &&
          prescriptionProductsResponse.data != null) {
        final prescriptionProducts = prescriptionProductsResponse.data!;

        setState(() {
          _allProducts = prescriptionProducts;
          _searchResults =
              prescriptionProducts; // Show all prescription products initially
        });
      } else {
        // Fallback to medicine suggestions API
        final suggestionsResponse = await _apiService.getMedicineSuggestions(
          widget.prescriptionId!.toString(),
        );

        if (suggestionsResponse.isSuccess && suggestionsResponse.data != null) {
          final suggestions = suggestionsResponse.data!;
          List<ProductModel> prescriptionProducts = [];

          // Convert medicine suggestions to product models
          for (var medicine in suggestions.medicines) {
            if (medicine.isAvailable && medicine.productInfo != null) {
              final productInfo = medicine.productInfo!;
              prescriptionProducts.add(
                ProductModel(
                  id: productInfo.productId,
                  name: productInfo.name,
                  manufacturer: productInfo.manufacturer,
                  currentSellingPrice: productInfo.currentSellingPrice,
                  imageUrl:
                      'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400',
                  description:
                      'Prescription medicine: ${medicine.medicineName}',
                  genericName: medicine.medicineName,
                  requiresPrescription: true,
                  stockQuantity: productInfo.stockQuantity,
                  isActive: productInfo.inStock,
                ),
              );
            }
          }

          setState(() {
          _allProducts = prescriptionProducts;
          _searchResults = prescriptionProducts;
          });
        }
      }
    } catch (e) {
      // Error loading prescription products, fallback to regular search
      final response = await _apiService.getProducts();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _allProducts = response.data!.products;
        });
        _performSearch(_currentQuery);
      }
    }
  }

  void _performSearch(String query) async {
    if (query.isEmpty && !widget.isFromPrescription) {
      setState(() {
        _searchResults = [];
        _currentQuery = '';
      });
      return;
    }

    List<ProductModel> results = [];

    if (widget.isFromPrescription) {
      if (widget.prescriptionId != null) {
        // For prescription-based search, show all prescription products if no specific query
        if (query.isEmpty || query == 'Prescription medicines') {
          results = _allProducts;
        } else {
          // Use the new prescription search API for better results
          try {
            final response = await _apiService.searchPrescriptionMedicines(
              query,
            );
            if (response.isSuccess && response.data != null) {
              results = response.data!;
            } else {
              // Fallback to local search
              results = _allProducts
                  .where(
                    (product) =>
                        product.name.toLowerCase().contains(
                          query.toLowerCase(),
                        ) ||
                        product.manufacturer.toLowerCase().contains(
                          query.toLowerCase(),
                        ) ||
                        (product.genericName?.toLowerCase().contains(
                              query.toLowerCase(),
                            ) ??
                            false) ||
                        (product.description?.toLowerCase().contains(
                              query.toLowerCase(),
                            ) ??
                            false),
                  )
                  .toList();
            }
          } catch (e) {
            // Fallback to local search on error
            results = _allProducts
                .where(
                  (product) =>
                      product.name.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ||
                      product.manufacturer.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ||
                      (product.genericName?.toLowerCase().contains(
                            query.toLowerCase(),
                          ) ??
                          false) ||
                      (product.description?.toLowerCase().contains(
                            query.toLowerCase(),
                          ) ??
                          false),
                )
                .toList();
          }
        }
      } else if (widget.extractedMedicines != null) {
        // Fallback: Search based on extracted medicine names
        for (String medicine in widget.extractedMedicines!) {
          final medicineResults = _allProducts
              .where(
                (product) =>
                    product.name.toLowerCase().contains(
                      medicine.toLowerCase(),
                    ) ||
                    product.manufacturer.toLowerCase().contains(
                      medicine.toLowerCase(),
                    ) ||
                    (product.genericName?.toLowerCase().contains(
                          medicine.toLowerCase(),
                        ) ??
                        false) ||
                    (product.description?.toLowerCase().contains(
                          medicine.toLowerCase(),
                        ) ??
                        false),
              )
              .toList();
          results.addAll(medicineResults);
        }

        // Remove duplicates
        results = results.toSet().toList();
      }
    } else {
      // For regular search, if the query changes, refetch from API with search parameter
      // If a categoryId was provided initially, prioritize searching within that category
      if (query.isNotEmpty && query != _currentQuery) {
        final response = await _apiService.getProducts(
          searchQuery: query,
          categoryId: widget.categoryId?.toString(), // Keep category filter if present
        );
        if (response.isSuccess && response.data != null) {
          results = response.data!.products;
        }
      } else {
        results =
            _allProducts; // If query is empty or same as initial category, show all loaded products
      }
    }

    setState(() {
      _searchResults = results;
      _currentQuery = query;
    });
  }

  Future<void> _addToCart(ProductModel product) async {
    try {
      await _cartService.addToCart(product);
      Fluttertoast.showToast(
        msg: '${product.name} added to cart',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error adding to cart: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Consistent white background
      appBar: AppBar(
        title: Text(
          widget.isFromPrescription ? 'Prescription Results' : 'Search Results',
          style: const TextStyle(
            color: Colors.teal, // Teal title for consistency
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal, // Teal icons
        elevation: 1, // Subtle elevation for app bar
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined), // Outlined icon
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100], // Lighter grey for search bar background
                borderRadius: BorderRadius.circular(25.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3), // subtle shadow
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search medicines...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  ),
                  border: InputBorder.none, // No border
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14.0,
                    horizontal: 20.0,
                  ),
                ),
                onSubmitted: _performSearch,
                onChanged: (value) {
                  if (value.isEmpty) {
                    _performSearch('');
                  }
                },
              ),
            ),
          ),

          // Prescription Info Banner (if from prescription)
          if (widget.isFromPrescription) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50, // Light teal for banner
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long, color: Colors.teal.shade600, size: 28), // More prominent icon
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prescription-based Results',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Medicines matched from your uploaded prescription',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.teal.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Results
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                    ),
                  )
                : _searchResults.isEmpty
                ? _buildEmptyState()
                : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.isFromPrescription
                ? Icons.medical_services_outlined
                : Icons.search_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            widget.isFromPrescription
                ? 'No medicines found for your prescription'
                : _currentQuery.isEmpty
                ? 'Enter a search term to find medicines'
                : 'No results found for "$_currentQuery"',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.isFromPrescription
                ? 'Try uploading a clearer prescription image'
                : 'Try different keywords or check spelling',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '${_searchResults.length} result${_searchResults.length == 1 ? '' : 's'} found',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final product = _searchResults[index];
              return _buildProductCard(product);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final bool isOnSale =
        product.currentBatch != null &&
        product.currentBatch!.mrp > product.currentBatch!.sellingPrice;
    final double discountPercent =
        product.currentBatch?.discountPercentage ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 5, // Increased elevation for a more prominent card
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), // More rounded corners
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(
                product: product,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white, // Solid white background for card
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
              children: [
                // Product Image
                Stack(
                  children: [
                    Container(
                      width: 90, // Slightly larger image
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14), // More rounded image corners
                        color: Colors.grey.shade100,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          product.imageUrl != null && product.imageUrl!.isNotEmpty
                              ? product.imageUrl!
                              : 'https://via.placeholder.com/150', // Default image if imageUrl is null or empty
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.teal.shade100, // Lighter teal gradient
                                    Colors.teal.shade300,
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.image_not_supported, // More appropriate icon
                                color: Colors.teal.shade700,
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Display discount percentage badge
                    if (product.currentBatch != null &&
                        ((product.currentBatch!.onlineDiscountPercentage != null && product.currentBatch!.onlineDiscountPercentage! > 0) ||
                            (product.currentBatch!.discountPercentage != null && product.currentBatch!.discountPercentage! > 0)))
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600, // Darker red for discount
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(14),
                              bottomLeft: Radius.circular(10),
                            ),
                          ),
                          child: Text(
                            '${(product.currentBatch!.onlineDiscountPercentage ?? product.currentBatch!.discountPercentage)?.toStringAsFixed(0)}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 16),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 18, // Slightly larger font
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Manufacturer
                      Text(
                        product.manufacturer,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Generic name if available
                      if (product.genericName != null &&
                          product.genericName!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Generic: ${product.genericName!}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      // Price and badges row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Price
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹${product.currentBatch?.sellingPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20, // More prominent price
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                              if (product.currentBatch?.mrp != null &&
                                  product.currentBatch!.mrp >
                                      (product.currentBatch?.sellingPrice ??
                                          product.currentSellingPrice))
                                Text(
                                  'MRP: ₹${product.currentBatch?.mrp.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),

                          // Stock status and prescription badge
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Stock status
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: product.isActive
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: product.isActive
                                        ? Colors.green
                                        : Colors.red,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      product.isActive
                                          ? Icons.check_circle_outline
                                          : Icons.highlight_off,
                                      size: 14,
                                      color: product.isActive
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      product.isActive
                                          ? 'In Stock'
                                          : 'Out of Stock',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: product.isActive
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Prescription badge
                              if (product.requiresPrescription)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.receipt_long,
                                        size: 14,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Rx Required',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
