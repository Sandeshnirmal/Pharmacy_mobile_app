// Prescription AI Results Screen
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'models/prescription_model.dart';
import 'services/api_service.dart';

class PrescriptionResultScreen extends StatefulWidget {
  final int prescriptionId;
  final PrescriptionSuggestionsResponse suggestions;

  const PrescriptionResultScreen({
    Key? key,
    required this.prescriptionId,
    required this.suggestions,
  }) : super(key: key);

  @override
  State<PrescriptionResultScreen> createState() => _PrescriptionResultScreenState();
}

class _PrescriptionResultScreenState extends State<PrescriptionResultScreen> {
  final ApiService _apiService = ApiService();
  late List<MedicineModel> _selectedMedicines;
  late PricingModel _pricing;
  bool _isCreatingOrder = false;

  @override
  void initState() {
    super.initState();
    // Pre-select available medicines
    _selectedMedicines = widget.suggestions.medicines
        .where((medicine) => medicine.isAvailable && medicine.productInfo != null)
        .map((medicine) => medicine.copyWith(selectedQuantity: 1))
        .toList();
    _calculatePricing();
  }

  void _calculatePricing() {
    double subtotal = _selectedMedicines.fold(0.0, (total, medicine) {
      return total + (medicine.productInfo?.price ?? 0.0) * medicine.selectedQuantity;
    });

    double shipping = subtotal >= 500 ? 0.0 : 50.0;
    double discount = subtotal >= 1000 ? subtotal * 0.1 : 0.0;
    double total = subtotal + shipping - discount;

    setState(() {
      _pricing = PricingModel(
        subtotal: subtotal,
        shipping: shipping,
        discount: discount,
        total: total,
      );
    });
  }

  void _toggleMedicineSelection(MedicineModel medicine) {
    if (!medicine.isAvailable || medicine.productInfo == null) {
      Fluttertoast.showToast(
        msg: "This medicine is not available for order",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    setState(() {
      final index = _selectedMedicines.indexWhere((m) => m.id == medicine.id);
      
      if (index >= 0) {
        _selectedMedicines.removeAt(index);
      } else {
        _selectedMedicines.add(medicine.copyWith(selectedQuantity: 1));
      }
      
      _calculatePricing();
    });
  }

  void _updateQuantity(int medicineId, int quantity) {
    if (quantity < 1) return;

    setState(() {
      final index = _selectedMedicines.indexWhere((m) => m.id == medicineId);
      if (index >= 0) {
        _selectedMedicines[index] = _selectedMedicines[index].copyWith(
          selectedQuantity: quantity,
        );
        _calculatePricing();
      }
    });
  }

  bool _isMedicineSelected(int medicineId) {
    return _selectedMedicines.any((m) => m.id == medicineId);
  }

  int _getSelectedQuantity(int medicineId) {
    final medicine = _selectedMedicines.firstWhere(
      (m) => m.id == medicineId,
      orElse: () => MedicineModel(
        id: 0,
        medicineName: '',
        confidenceScore: 0.0,
        isAvailable: false,
      ),
    );
    return medicine.id != 0 ? medicine.selectedQuantity : 0;
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getConfidenceText(double confidence) {
    if (confidence >= 0.9) return 'Excellent';
    if (confidence >= 0.8) return 'Very Good';
    if (confidence >= 0.7) return 'Good';
    if (confidence >= 0.6) return 'Fair';
    return 'Poor';
  }

  Future<void> _proceedToOrder() async {
    if (_selectedMedicines.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please select at least one medicine to proceed",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    // For demo purposes, using dummy address and payment method
    // In a real app, you would navigate to address/payment selection screens
    setState(() {
      _isCreatingOrder = true;
    });

    try {
      final orderData = {
        'prescription_id': widget.prescriptionId,
        'medicines': _selectedMedicines.map((medicine) => {
          'detail_id': medicine.id,
          'quantity': medicine.selectedQuantity,
        }).toList(),
        'address_id': 1, // Dummy address ID
        'payment_method': 'UPI', // Dummy payment method
        'special_instructions': 'Order from prescription AI processing',
      };

      final result = await _apiService.createPrescriptionOrder(orderData);
      
      setState(() {
        _isCreatingOrder = false;
      });

      if (result.isSuccess) {
        final orderResponse = result.data!;
        
        Fluttertoast.showToast(
          msg: "Order created successfully! Order #${orderResponse.orderNumber}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );

        // Navigate back to home or order confirmation screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        Fluttertoast.showToast(
          msg: "Order creation failed: ${result.error}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      setState(() {
        _isCreatingOrder = false;
      });
      
      Fluttertoast.showToast(
        msg: "Order error: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Results'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // AI Summary Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Analysis Results',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('AI Confidence: '),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getConfidenceColor(widget.suggestions.aiConfidence),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(widget.suggestions.aiConfidence * 100).round()}% - ${_getConfidenceText(widget.suggestions.aiConfidence)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${widget.suggestions.summary.totalMedicines}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            const Text('Total Medicines'),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${widget.suggestions.summary.availableMedicines}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const Text('Available'),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${widget.suggestions.summary.unavailableMedicines}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const Text('Unavailable'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Medicines List
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Extracted Medicines',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.suggestions.medicines.map((medicine) => _buildMedicineCard(medicine)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Order Summary
            if (_selectedMedicines.isNotEmpty) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Selected Items:'),
                          Text('${_selectedMedicines.length}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:'),
                          Text('₹${_pricing.subtotal.toStringAsFixed(2)}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Shipping:'),
                          Text('₹${_pricing.shipping.toStringAsFixed(2)}'),
                        ],
                      ),
                      if (_pricing.discount > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Discount:'),
                            Text('-₹${_pricing.discount.toStringAsFixed(2)}'),
                          ],
                        ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${_pricing.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isCreatingOrder ? null : _proceedToOrder,
                          icon: _isCreatingOrder
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.shopping_cart),
                          label: Text(_isCreatingOrder ? 'Creating Order...' : 'Proceed to Order'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineCard(MedicineModel medicine) {
    final isSelected = _isMedicineSelected(medicine.id);
    final selectedQuantity = _getSelectedQuantity(medicine.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.medicineName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (medicine.dosage != null)
                        Text('Dosage: ${medicine.dosage}'),
                      if (medicine.quantity != null)
                        Text('Quantity: ${medicine.quantity}'),
                      if (medicine.instructions != null)
                        Text(
                          'Instructions: ${medicine.instructions}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(medicine.confidenceScore),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(medicine.confidenceScore * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (medicine.isAvailable && medicine.productInfo != null)
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleMedicineSelection(medicine),
                        activeColor: Colors.teal,
                      ),
                  ],
                ),
              ],
            ),
            
            if (medicine.productInfo != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          medicine.productInfo!.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: medicine.productInfo!.inStock ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            medicine.productInfo!.inStock ? 'In Stock' : 'Out of Stock',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '₹${medicine.productInfo!.price}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        if (medicine.productInfo!.mrp > medicine.productInfo!.price) ...[
                          const SizedBox(width: 8),
                          Text(
                            '₹${medicine.productInfo!.mrp}',
                            style: const TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          medicine.productInfo!.manufacturer,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    
                    if (isSelected) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Quantity:'),
                          Row(
                            children: [
                              IconButton(
                                onPressed: selectedQuantity > 1
                                    ? () => _updateQuantity(medicine.id, selectedQuantity - 1)
                                    : null,
                                icon: const Icon(Icons.remove),
                                iconSize: 20,
                              ),
                              Text(
                                '$selectedQuantity',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _updateQuantity(medicine.id, selectedQuantity + 1),
                                icon: const Icon(Icons.add),
                                iconSize: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This medicine is not available in our inventory',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
