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

  const SearchResultsScreen({
    super.key,
    required this.searchQuery,
    this.extractedMedicines,
    this.isFromPrescription = false,
    this.prescriptionId,
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
        // Load all products for regular search
        final response = await _apiService.getProducts();
        if (response.isSuccess && response.data != null) {
          setState(() {
            _allProducts = response.data!;
          });
          _performSearch(_currentQuery);
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
      final prescriptionProductsResponse = await _apiService.getPrescriptionProducts(widget.prescriptionId!);

      if (prescriptionProductsResponse.isSuccess && prescriptionProductsResponse.data != null) {
        final prescriptionProducts = prescriptionProductsResponse.data!;

        setState(() {
          _allProducts = prescriptionProducts;
          _searchResults = prescriptionProducts; // Show all prescription products initially
        });
      } else {
        // Fallback to medicine suggestions API
        final suggestionsResponse = await _apiService.getMedicineSuggestions(widget.prescriptionId!);

        if (suggestionsResponse.isSuccess && suggestionsResponse.data != null) {
          final suggestions = suggestionsResponse.data!;
          List<ProductModel> prescriptionProducts = [];

          // Convert medicine suggestions to product models
          for (var medicine in suggestions.medicines) {
            if (medicine.isAvailable && medicine.productInfo != null) {
              final productInfo = medicine.productInfo!;
              prescriptionProducts.add(ProductModel(
                id: productInfo.productId,
                name: productInfo.name,
                manufacturer: productInfo.manufacturer,
                price: productInfo.price,
                mrp: productInfo.mrp,
                imageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400',
                description: 'Prescription medicine: ${medicine.medicineName}',
                genericName: medicine.medicineName,
                requiresPrescription: true,
                stockQuantity: productInfo.stockQuantity,
                isActive: productInfo.inStock,
              ));
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
          _allProducts = response.data!;
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
            final response = await _apiService.searchPrescriptionMedicines(query);
            if (response.isSuccess && response.data != null) {
              results = response.data!;
            } else {
              // Fallback to local search
              results = _allProducts.where((product) =>
                product.name.toLowerCase().contains(query.toLowerCase()) ||
                product.manufacturer.toLowerCase().contains(query.toLowerCase()) ||
                (product.genericName?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                (product.description?.toLowerCase().contains(query.toLowerCase()) ?? false)
              ).toList();
            }
          } catch (e) {
            // Fallback to local search on error
            results = _allProducts.where((product) =>
              product.name.toLowerCase().contains(query.toLowerCase()) ||
              product.manufacturer.toLowerCase().contains(query.toLowerCase()) ||
              (product.genericName?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
              (product.description?.toLowerCase().contains(query.toLowerCase()) ?? false)
            ).toList();
          }
        }
      } else if (widget.extractedMedicines != null) {
        // Fallback: Search based on extracted medicine names
        for (String medicine in widget.extractedMedicines!) {
          final medicineResults = _allProducts.where((product) =>
            product.name.toLowerCase().contains(medicine.toLowerCase()) ||
            product.manufacturer.toLowerCase().contains(medicine.toLowerCase()) ||
            (product.genericName?.toLowerCase().contains(medicine.toLowerCase()) ?? false) ||
            (product.description?.toLowerCase().contains(medicine.toLowerCase()) ?? false)
          ).toList();
          results.addAll(medicineResults);
        }

        // Remove duplicates
        results = results.toSet().toList();
      }
    } else {
      // Regular search
      results = _allProducts.where((product) =>
        product.name.toLowerCase().contains(query.toLowerCase()) ||
        product.manufacturer.toLowerCase().contains(query.toLowerCase()) ||
        (product.genericName?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
        (product.description?.toLowerCase().contains(query.toLowerCase()) ?? false)
      ).toList();
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

  Map<String, dynamic> _productToMap(ProductModel product) {
    return {
      'id': product.id,
      'name': product.name,
      'manufacturer': product.manufacturer,
      'price': product.price,
      'mrp': product.mrp,
      'imageUrl': product.imageUrl,
      'description': product.description,
      'genericName': product.genericName,
      'requiresPrescription': product.requiresPrescription,
      'stockQuantity': product.stockQuantity,
      'isActive': product.isActive,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.isFromPrescription ? 'Prescription Results' : 'Search Results'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
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
                hintText: 'Search medicines...',
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
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
              onChanged: (value) {
                if (value.isEmpty) {
                  _performSearch('');
                }
              },
            ),
          ),

          // Prescription Info Banner (if from prescription)
          if (widget.isFromPrescription) ...[
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.medical_services, color: Colors.blue.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prescription-based Results',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Showing medicines based on your uploaded prescription',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade600,
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
            widget.isFromPrescription ? Icons.medical_services_outlined : Icons.search_off,
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
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.isFromPrescription
                ? 'Try uploading a clearer prescription image'
                : 'Try different keywords or check spelling',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
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
    final bool isOnSale = product.mrp > product.price;
    final double discountPercent = isOnSale ? ((product.mrp - product.price) / product.mrp * 100) : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(product: _productToMap(product)),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Enhanced Product Image
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.2),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          product.imageUrl ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.teal.withValues(alpha: 0.1), Colors.teal.withValues(alpha: 0.3)],
                                ),
                              ),
                              child: Icon(
                                Icons.medical_services,
                                color: Colors.teal,
                                size: 35,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (isOnSale)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${discountPercent.toInt()}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 16),

                // Enhanced Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Generic name if available
                      if (product.genericName != null && product.genericName!.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.science, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                product.genericName!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                      // Manufacturer
                      Row(
                        children: [
                          Icon(Icons.business, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product.manufacturer,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Price and badges row
                      Row(
                        children: [
                          // Price
                          Text(
                            '₹${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          if (isOnSale) ...[
                            const SizedBox(width: 8),
                            Text(
                              '₹${product.mrp.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                          const Spacer(),

                          // Prescription badge
                          if (product.requiresPrescription)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.receipt, size: 12, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Rx',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Stock status and prescription badge
                      Row(
                        children: [
                          // Stock status
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: product.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: product.isActive ? Colors.green : Colors.red,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  product.isActive ? Icons.check_circle : Icons.cancel,
                                  size: 12,
                                  color: product.isActive ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  product.isActive ? 'In Stock' : 'Out of Stock',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: product.isActive ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Prescription-based badge
                          if (widget.isFromPrescription)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.assignment, size: 12, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Prescribed',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue,
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
                ),

                // Enhanced Add to Cart Button
                Container(
                  decoration: BoxDecoration(
                    color: product.isActive ? Colors.teal : Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: product.isActive ? [
                      BoxShadow(
                        color: Colors.teal.withValues(alpha: 0.3),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: IconButton(
                    onPressed: product.isActive ? () => _addToCart(product) : null,
                    icon: const Icon(Icons.add_shopping_cart),
                    color: Colors.white,
                    iconSize: 22,
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
