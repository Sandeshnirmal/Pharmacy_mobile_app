// Intelligent Medicine Search Screen
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/product_model.dart';
import '../../utils/api_logger.dart';
// import '../../providers/cart_provider.dart';

class MedicineSearchScreen extends StatefulWidget {
  const MedicineSearchScreen({super.key});

  @override
  State<MedicineSearchScreen> createState() => _MedicineSearchScreenState();
}

class _MedicineSearchScreenState extends State<MedicineSearchScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final List<TextEditingController> _medicineControllers = [
    TextEditingController(),
  ];

  List<MedicineSearchResult> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    for (var controller in _medicineControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addMedicineField() {
    setState(() {
      _medicineControllers.add(TextEditingController());
    });
  }

  void _removeMedicineField(int index) {
    if (_medicineControllers.length > 1) {
      setState(() {
        _medicineControllers[index].dispose();
        _medicineControllers.removeAt(index);
      });
    }
  }

  Future<void> _searchMedicines() async {
    final medicines = _medicineControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (medicines.isEmpty) {
      setState(() {
        _error = 'Please enter at least one medicine name';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _searchResults = [];
    });

    try {
      final response = await _apiService.intelligentMedicineSearch(medicines);

      if (response.isSuccess && response.data != null) {
        final results = response.data!['results'] as List;
        setState(() {
          _searchResults = results
              .map((result) => MedicineSearchResult.fromJson(result))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Search failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Search error: $e';
        _isLoading = false;
      });
      ApiLogger.logError('Medicine search error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Search'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchForm(),
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter Medicine Names',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter medicine names with strength and form (e.g., "Paracetamol 500mg tablet")',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Medicine input fields
          ...List.generate(_medicineControllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _medicineControllers[index],
                      decoration: InputDecoration(
                        hintText:
                            'Medicine ${index + 1} (e.g., Paracetamol 500mg tablet)',
                        prefixIcon: const Icon(
                          Icons.medication,
                          color: Colors.teal,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.teal,
                            width: 2,
                          ),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  if (_medicineControllers.length > 1)
                    IconButton(
                      onPressed: () => _removeMedicineField(index),
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                    ),
                ],
              ),
            );
          }),

          // Add medicine button
          Row(
            children: [
              TextButton.icon(
                onPressed: _addMedicineField,
                icon: const Icon(Icons.add, color: Colors.teal),
                label: const Text(
                  'Add Another Medicine',
                  style: TextStyle(color: Colors.teal),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _searchMedicines,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(_isLoading ? 'Searching...' : 'Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.teal),
            SizedBox(height: 16),
            Text('Searching for medicines...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _searchMedicines,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Enter medicine names above to search',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildSearchResultCard(result);
      },
    );
  }

  Widget _buildSearchResultCard(MedicineSearchResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.search, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Search: "${result.searchText}"',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (result.matches.isEmpty)
              const Text(
                'No matches found for this medicine',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...result.matches.map((match) => _buildMedicineMatch(match)),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineMatch(MedicineMatch match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (match.genericName != null)
                      Text(
                        'Generic: ${match.genericName}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    Text(
                      '${match.strength} • ${match.form}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      'By ${match.manufacturer}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(match.confidence),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(match.confidence * 100).toInt()}% match',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${match.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  if (match.mrp > match.price)
                    Text(
                      '₹${match.mrp.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ],
          ),

          if (match.compositions.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Composition:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: match.compositions.map((comp) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Text(
                    '${comp.name} ${comp.strength}${comp.unit}',
                    style: const TextStyle(fontSize: 10, color: Colors.teal),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              if (match.isPrescriptionRequired)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Prescription Required',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                'Stock: ${match.stockQuantity}',
                style: TextStyle(
                  fontSize: 12,
                  color: match.stockQuantity > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: match.stockQuantity > 0
                    ? () => _addToCart(match)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Add to Cart',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  void _addToCart(MedicineMatch match) {
    final product = ProductModel(
      id: match.id,
      name: match.name,
      description: match.genericName,
      strength: match.strength,
      form: match.form,
      price: match.price,
      mrp: match.mrp,
      manufacturer: match.manufacturer,
      category: null,
      genericName: match.genericName,
      requiresPrescription: match.isPrescriptionRequired,
      stockQuantity: match.stockQuantity,
      isActive: true,
      imageUrl: match.imageUrl,
      expiryDate: null,
    );

    // context.read<CartProvider>().addToCart(product, 1);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${match.name} added to cart'),
        backgroundColor: Colors.teal,
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, '/cart');
          },
        ),
      ),
    );
  }
}

// Data models for medicine search
class MedicineSearchResult {
  final String searchText;
  final Map<String, dynamic> extractedInfo;
  final List<MedicineMatch> matches;

  MedicineSearchResult({
    required this.searchText,
    required this.extractedInfo,
    required this.matches,
  });

  factory MedicineSearchResult.fromJson(Map<String, dynamic> json) {
    return MedicineSearchResult(
      searchText: json['search_text'] ?? '',
      extractedInfo: json['extracted_info'] ?? {},
      matches: (json['matches'] as List? ?? [])
          .map((match) => MedicineMatch.fromJson(match))
          .toList(),
    );
  }
}

class MedicineMatch {
  final int id;
  final String name;
  final String? genericName;
  final String manufacturer;
  final String strength;
  final String form;
  final double price;
  final double mrp;
  final int stockQuantity;
  final bool isPrescriptionRequired;
  final String? imageUrl;
  final double confidence;
  final String matchType;
  final List<CompositionInfo> compositions;

  MedicineMatch({
    required this.id,
    required this.name,
    this.genericName,
    required this.manufacturer,
    required this.strength,
    required this.form,
    required this.price,
    required this.mrp,
    required this.stockQuantity,
    required this.isPrescriptionRequired,
    this.imageUrl,
    required this.confidence,
    required this.matchType,
    required this.compositions,
  });

  factory MedicineMatch.fromJson(Map<String, dynamic> json) {
    return MedicineMatch(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      genericName: json['generic_name'],
      manufacturer: json['manufacturer'] ?? '',
      strength: json['strength'] ?? '',
      form: json['form'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      mrp: (json['mrp'] ?? 0).toDouble(),
      stockQuantity: json['stock_quantity'] ?? 0,
      isPrescriptionRequired: json['is_prescription_required'] ?? false,
      imageUrl: json['image_url'],
      confidence: (json['confidence'] ?? 0).toDouble(),
      matchType: json['match_type'] ?? '',
      compositions: (json['compositions'] as List? ?? [])
          .map((comp) => CompositionInfo.fromJson(comp))
          .toList(),
    );
  }
}

class CompositionInfo {
  final String name;
  final String strength;
  final String unit;

  CompositionInfo({
    required this.name,
    required this.strength,
    required this.unit,
  });

  factory CompositionInfo.fromJson(Map<String, dynamic> json) {
    return CompositionInfo(
      name: json['name'] ?? '',
      strength: json['strength'] ?? '',
      unit: json['unit'] ?? '',
    );
  }
}
