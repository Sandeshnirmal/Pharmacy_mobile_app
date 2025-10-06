import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'main.dart';
import 'CartScreen.dart';
import 'services/cart_service.dart';
import 'models/product_model.dart';

class ProductDetailsScreen extends StatefulWidget {
  // Now accepts product data via its constructor
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final CartService _cartService = CartService();
  int _selectedTab =
      0; // 0: Description, 1: How to Use, 2: Side Effects, 3: Reviews
  int _quantity = 1;
  bool _isInWishlist = false;
  bool _isAddingToCart = false;
  final double _averageRating = 4.2;
  final int _totalReviews = 156;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadSampleReviews();
  }

  void _loadSampleReviews() {
    setState(() {
      _reviews = [
        {
          'userName': 'Dr. Sarah Johnson',
          'rating': 5,
          'comment':
              'Excellent quality medicine. Very effective for pain relief.',
          'date': '2024-01-15',
          'isVerified': true,
        },
        {
          'userName': 'Michael Chen',
          'rating': 4,
          'comment': 'Good product, fast delivery. Recommended by my doctor.',
          'date': '2024-01-10',
          'isVerified': true,
        },
        {
          'userName': 'Priya Sharma',
          'rating': 5,
          'comment': 'Works as expected. No side effects observed.',
          'date': '2024-01-08',
          'isVerified': false,
        },
      ];
    });
  }

  Future<void> _addToCart() async {
    setState(() {
      _isAddingToCart = true;
    });

    try {
      // Convert product map to ProductModel
      final productModel = ProductModel(
        id: widget.product['id'] ?? 0,
        name: widget.product['name'] ?? '',
        manufacturer: widget.product['brand'] ?? '',
        genericName: widget.product['genericName'],
        strength: widget.product['dosage'],
        form: widget.product['form'],
        currentSellingPrice:
            double.tryParse(widget.product['currentSellingPrice'].toString()) ??
            0.0,
        imageUrl: widget.product['imageUrl'] ?? '',
        requiresPrescription: widget.product['requiresPrescription'] ?? false,
        description: widget.product['description'],
        category: widget.product['category'],
        stockQuantity: widget.product['stockQuantity'] ?? 100,
        isActive: widget.product['isActive'] ?? true,
      );

      // Add to cart using CartService
      await _cartService.addToCart(productModel, quantity: _quantity);

      Fluttertoast.showToast(
        msg: '${widget.product['name']} added to cart',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to add to cart: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isAddingToCart = false;
      });
    }
  }

  void _toggleWishlist() {
    setState(() {
      _isInWishlist = !_isInWishlist;
    });

    Fluttertoast.showToast(
      msg: _isInWishlist ? 'Added to wishlist' : 'Removed from wishlist',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: _isInWishlist ? Colors.green : Colors.orange,
      textColor: Colors.white,
    );
  }

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
            ); // Go back to the previous screen
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
                  // Product Image Section with Wishlist Button
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 300,
                        color: const Color(0xFFF9E7D2),
                        child: Center(
                          child: Image.network(
                            product['imageUrl'],
                            fit: BoxFit.contain,
                            height: 250,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 250,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                      size: 60,
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ),
                      // Wishlist Button
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.3),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isInWishlist
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isInWishlist ? Colors.red : Colors.grey,
                            ),
                            onPressed: _toggleWishlist,
                          ),
                        ),
                      ),
                    ],
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
                        const SizedBox(height: 8),

                        // Brand and Generic Name
                        Row(
                          children: [
                            Text(
                              'Brand: ${product['brand']}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (product['requiresPrescription'] == true) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Rx Required',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Rating Section
                        Row(
                          children: [
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < _averageRating.floor()
                                      ? Icons.star
                                      : index < _averageRating
                                      ? Icons.star_half
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                );
                              }),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$_averageRating ($_totalReviews reviews)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Price Section
                        Row(
                          children: [
                            Text(
                              '₹${product['currentSellingPrice']}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Quantity Selector
                        Row(
                          children: [
                            const Text(
                              'Quantity:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: _quantity > 1
                                        ? () => setState(() => _quantity--)
                                        : null,
                                    color: Colors.teal,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      '$_quantity',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () =>
                                        setState(() => _quantity++),
                                    color: Colors.teal,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Medicine Information Cards
                        _buildInfoCard(
                          'Generic Name',
                          product['genericName'] ?? 'Not specified',
                          Icons.medical_information,
                          Colors.blue,
                        ),
                        const SizedBox(height: 12),

                        _buildInfoCard(
                          'Strength & Form',
                          '${product['dosage'] ?? 'Not specified'} • ${product['form'] ?? 'Not specified'}',
                          Icons.medication,
                          Colors.green,
                        ),
                        const SizedBox(height: 12),

                        _buildInfoCard(
                          'Active Ingredient',
                          product['activeIngredient'] ??
                              product['genericName'] ??
                              'Not specified',
                          Icons.science,
                          Colors.purple,
                        ),
                        const SizedBox(height: 12),

                        _buildInfoCard(
                          'Manufacturer',
                          product['brand'] ?? 'Not specified',
                          Icons.business,
                          Colors.orange,
                        ),
                        const SizedBox(height: 24),

                        // Tab Bar for Description, How to Use, Side Effects, Reviews
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildTabButton(0, 'Description'),
                              _buildTabButton(1, 'How to Use'),
                              _buildTabButton(2, 'Side Effects'),
                              _buildTabButton(3, 'Reviews ($_totalReviews)'),
                            ],
                          ),
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
                    onPressed: _isAddingToCart ? null : _addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                      shadowColor: Colors.blueAccent.withValues(alpha: 0.4),
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
                    onPressed: _toggleWishlist,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: Colors.grey.withValues(alpha: 0.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isInWishlist
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _isInWishlist ? Colors.red : Colors.grey[800],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isInWishlist ? 'In Wishlist' : 'Add to Wishlist',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
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
                // print('Home tapped'); // Debug print removed
                // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
              },
              iconSize: 30.0,
              color: Colors.grey[700],
            ),
            IconButton(
              icon: const Icon(Icons.category_outlined),
              onPressed: () {
                // print('Categories tapped'); // Debug print removed
                // Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoriesPage()));
              },
              iconSize: 30.0,
              color: Colors.grey[700],
            ),
            const SizedBox(width: 48), // Space for the FAB
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
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                // print('Profile tapped'); // Debug print removed
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
          // print('Scanner tapped'); // Debug print removed
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
              fontWeight: _selectedTab == index
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: _selectedTab == index
                  ? Colors.blueAccent
                  : Colors.grey[600],
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
    final Map<String, dynamic> product = widget.product;

    switch (_selectedTab) {
      case 0:
        return _buildDescriptionContent(product);
      case 1:
        return _buildUsageContent(product);
      case 2:
        return _buildSideEffectsContent(product);
      case 3:
        return _buildReviewsContent();
      default:
        return _buildTextContent('Content not available.');
    }
  }

  Widget _buildTextContent(String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
      child: Text(
        content,
        style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
      ),
    );
  }

  Widget _buildDescriptionContent(Map<String, dynamic> product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product['description'] != null &&
            product['description'].isNotEmpty) ...[
          _buildSectionHeader('Description'),
          _buildSectionContent(product['description']),
          const SizedBox(height: 16),
        ],

        if (product['composition'] != null &&
            product['composition'].isNotEmpty) ...[
          _buildSectionHeader('Composition'),
          _buildSectionContent(product['composition']),
          const SizedBox(height: 16),
        ],

        if (product['uses'] != null && product['uses'].isNotEmpty) ...[
          _buildSectionHeader('Medical Uses'),
          _buildSectionContent(product['uses']),
          const SizedBox(height: 16),
        ],

        if (product['precautions'] != null &&
            product['precautions'].isNotEmpty) ...[
          _buildSectionHeader('Precautions'),
          _buildSectionContent(product['precautions']),
        ],

        if (product['description'] == null &&
            product['composition'] == null &&
            product['uses'] == null &&
            product['precautions'] == null)
          _buildTextContent('No detailed description available.'),
      ],
    );
  }

  Widget _buildUsageContent(Map<String, dynamic> product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product['howToUse'] != null && product['howToUse'].isNotEmpty) ...[
          _buildSectionHeader('How to Use'),
          _buildSectionContent(product['howToUse']),
          const SizedBox(height: 16),
        ],

        if (product['dosage'] != null) ...[
          _buildSectionHeader('Dosage Information'),
          _buildSectionContent('Strength: ${product['dosage']}'),
          const SizedBox(height: 16),
        ],

        if (product['form'] != null) ...[
          _buildSectionHeader('Dosage Form'),
          _buildSectionContent('Form: ${product['form']}'),
          const SizedBox(height: 16),
        ],

        if (product['storage'] != null && product['storage'].isNotEmpty) ...[
          _buildSectionHeader('Storage Instructions'),
          _buildSectionContent(product['storage']),
        ],

        if (product['howToUse'] == null && product['storage'] == null)
          _buildTextContent('No usage instructions available.'),
      ],
    );
  }

  Widget _buildSideEffectsContent(Map<String, dynamic> product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product['sideEffects'] != null &&
            product['sideEffects'].isNotEmpty) ...[
          _buildSectionHeader('Possible Side Effects'),
          _buildSectionContent(product['sideEffects']),
          const SizedBox(height: 16),
        ],

        if (product['precautions'] != null &&
            product['precautions'].isNotEmpty) ...[
          _buildSectionHeader('Important Precautions'),
          _buildSectionContent(product['precautions']),
          const SizedBox(height: 16),
        ],

        // General safety information
        _buildSectionHeader('General Safety'),
        _buildSectionContent(
          '• Always follow the prescribed dosage\n'
          '• Consult your doctor if symptoms persist\n'
          '• Keep out of reach of children\n'
          '• Do not exceed recommended dose\n'
          '• Inform your doctor about other medications',
        ),

        if (product['sideEffects'] == null && product['precautions'] == null)
          _buildTextContent('No side effects information available.'),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        content,
        style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
      ),
    );
  }

  Widget _buildReviewsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _averageRating.toString(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < _averageRating.floor()
                            ? Icons.star
                            : index < _averageRating
                            ? Icons.star_half
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                  ),
                  Text(
                    '$_totalReviews reviews',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // Add review functionality
                  _showAddReviewDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Write Review'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Reviews List
        if (_reviews.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'No reviews yet. Be the first to review!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final review = _reviews[index];
              return _buildReviewItem(review);
            },
          ),
      ],
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.teal.shade100,
                child: Text(
                  review['userName'][0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.teal.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review['userName'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (review['isVerified'] == true) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < review['rating']
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          review['date'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review['comment'],
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Write a Review'),
        content: const Text(
          'Review functionality will be implemented with user authentication.',
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

  Widget _buildInfoCard(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
