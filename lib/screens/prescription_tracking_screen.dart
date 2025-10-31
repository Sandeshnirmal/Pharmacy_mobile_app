import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy/ProductDetailsScreen.dart';
import 'package:provider/provider.dart';
import 'package:pharmacy/models/prescription_detail_model.dart';
import 'package:pharmacy/services/prescription_service.dart';
import 'package:pharmacy/services/auth_service.dart'; // Import AuthService
import 'package:pharmacy/providers/cart_provider.dart';
import 'package:pharmacy/main.dart';
import 'package:pharmacy/models/product_model.dart'; // Import ProductModel
import 'package:pharmacy/LoginScreen.dart'; // Import LoginScreen
import 'package:pharmacy/OrderPrescriptionUploadScreen.dart';
import '../services/cart_service.dart'; // Import CartService

class PrescriptionTrackingScreen extends StatefulWidget {
  final String? prescriptionId; // Added optional prescriptionId

  const PrescriptionTrackingScreen({super.key, this.prescriptionId});

  @override
  State<PrescriptionTrackingScreen> createState() =>
      _PrescriptionTrackingScreenState();
}

class PrescriptionDetailViewScreen extends StatelessWidget {
  final PrescriptionDetailModel prescription;

  const PrescriptionDetailViewScreen({super.key, required this.prescription});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final cartService = CartService(); // Initialize CartService

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Details'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: (prescription.imageUrl.isNotEmpty)
                    ? Image.network(
                        prescription.imageUrl,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey.shade400,
                            size: 50,
                          ),
                        ),
                      )
                    : Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.receipt_long,
                          color: Colors.grey.shade400,
                          size: 60,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Prescription ID: ${prescription.id}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Divider(height: 20, thickness: 1),
            _buildDetailRow('Status', prescription.status),
            _buildDetailRow(
              'Uploaded At',
              DateFormat(
                'dd MMM yyyy, hh:mm a',
              ).format(prescription.uploadedAt),
            ),
            if (prescription.verifiedAt != null)
              _buildDetailRow(
                'Verified At',
                DateFormat(
                  'dd MMM yyyy, hh:mm a',
                ).format(prescription.verifiedAt!),
              ),
            if (prescription.rejectedAt != null)
              _buildDetailRow(
                'Rejected At',
                DateFormat(
                  'dd MMM yyyy, hh:mm a',
                ).format(prescription.rejectedAt!),
              ),
            const SizedBox(height: 24),
            Text(
              'OCR Extracted Medicines (${prescription.prescriptionMedicines?.length ?? 0})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Divider(height: 20, thickness: 1),
            if (prescription.prescriptionMedicines == null ||
                prescription.prescriptionMedicines!.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    'No medicines extracted by OCR yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: prescription.prescriptionMedicines!.length,
                itemBuilder: (context, index) {
                  final medicineDetail =
                      prescription.prescriptionMedicines![index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicineDetail.extractedMedicineName ?? 'N/A',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dosage: ${medicineDetail.extractedDosage ?? 'N/A'}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          Text(
                            'Quantity: ${medicineDetail.quantityPrescribed ?? 'N/A'}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          if (medicineDetail.mappedProduct != null) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Mapped Product:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  medicineDetail.mappedProduct!.imageUrl ??
                                      'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.grey.shade200,
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                ),
                              ),
                              title: Text(
                                medicineDetail.mappedProduct!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${medicineDetail.mappedProduct!.manufacturer} - ₹${medicineDetail.mappedProduct!.currentSellingPrice.toStringAsFixed(2)}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.add_shopping_cart,
                                  color: Colors.teal,
                                ),
                                onPressed: () async {
                                  await cartService.addToCart(
                                    medicineDetail.mappedProduct!,
                                    quantity: 1,
                                  );
                                  cartProvider.addItem(
                                    medicineDetail.mappedProduct!,
                                    1,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${medicineDetail.mappedProduct!.name} added to cart!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailsScreen(
                                      product: medicineDetail
                                          .mappedProduct!, // Pass ProductModel directly
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
            Text(
              'Aggregated Suggested Medicines (${prescription.suggestedMedicines?.length ?? 0})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Divider(height: 20, thickness: 1),
            if (prescription.suggestedMedicines == null ||
                prescription.suggestedMedicines!.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    'No aggregated medicines suggested yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: prescription.suggestedMedicines!.length,
                itemBuilder: (context, index) {
                  final medicine = prescription.suggestedMedicines![index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          medicine.imageUrl ??
                              'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                        ),
                      ),
                      title: Text(
                        medicine.name ?? 'Unknown Medicine',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${medicine.manufacturer.isNotEmpty ? medicine.manufacturer : 'N/A'} - ${medicine.currentSellingPrice > 0 ? '₹${medicine.currentSellingPrice.toStringAsFixed(2)}' : 'Price N/A'}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.add_shopping_cart,
                          color: Colors.teal,
                        ),
                        onPressed: () async {
                          await cartService.addToCart(medicine, quantity: 1);
                          cartProvider.addItem(medicine, 1);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${medicine.name} added to cart!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailsScreen(
                              product: medicine, // Pass ProductModel directly
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
            if (prescription.status == 'verified') ...[
              const SizedBox(height: 24),
            ] else ...[
              const SizedBox(height: 24),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: Colors.teal.shade400,
                        size: 60,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Medicine details will be available after admin verification.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            const Text(
              'Notes & Reasons',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Divider(height: 20, thickness: 1),
            if (prescription.rejectionReason != null &&
                prescription.rejectionReason!.isNotEmpty)
              _buildInfoCard(
                title: 'Rejection Reason',
                value: prescription.rejectionReason!,
                icon: Icons.cancel,
                color: Colors.red,
              ),
            if (prescription.clarificationNotes != null &&
                prescription.clarificationNotes!.isNotEmpty)
              _buildInfoCard(
                title: 'Clarification Notes',
                value: prescription.clarificationNotes!,
                icon: Icons.note_alt,
                color: Colors.orange,
              ),
            if (prescription.pharmacistNotes != null &&
                prescription.pharmacistNotes!.isNotEmpty)
              _buildInfoCard(
                title: 'Pharmacist Notes',
                value: prescription.pharmacistNotes!,
                icon: Icons.local_pharmacy,
                color: Colors.blue,
              ),
            if (prescription.verificationNotes != null &&
                prescription.verificationNotes!.isNotEmpty)
              _buildInfoCard(
                title: 'Verification Notes',
                value: prescription.verificationNotes!,
                icon: Icons.verified_user,
                color: Colors.green,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8.0), // Added margin for spacing
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
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
                  value,
                  style: TextStyle(fontSize: 16, color: color.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _PrescriptionTrackingScreenState
    extends State<PrescriptionTrackingScreen> {
  late Future<List<PrescriptionDetailModel>> _prescriptionsFuture;
  final PrescriptionService _prescriptionService = PrescriptionService();
  final AuthService _authService = AuthService(); // Initialize AuthService
  bool _isAuthenticated = false; // Track authentication status

  @override
  void initState() {
    super.initState();
    _checkAuthAndFetchPrescriptions();
  }

  Future<void> _checkAuthAndFetchPrescriptions() async {
    _isAuthenticated = await _authService.isAuthenticated();
    print('Authentication status: $_isAuthenticated'); // Debug print
    if (_isAuthenticated) {
      _fetchPrescriptions();
    } else {
      setState(() {
        _prescriptionsFuture = Future.value(
          [],
        ); // No prescriptions for unauthenticated users
      });
    }
  }

  Future<void> _fetchPrescriptions() async {
    setState(() {
      if (widget.prescriptionId != null) {
        // If a specific prescriptionId is provided, fetch only that one
        _prescriptionsFuture = _prescriptionService
            .getPrescriptionDetail(widget.prescriptionId!)
            .then((response) {
              if (response.isSuccess && response.data != null) {
                return [response.data!]; // Return as a list for consistency
              } else {
                throw Exception(
                  response.error ?? 'Failed to load specific prescription',
                );
              }
            });
      } else {
        // Otherwise, fetch all user prescriptions
        _prescriptionsFuture = _prescriptionService.getUserPrescriptions().then(
          (response) {
            if (response.isSuccess && response.data != null) {
              return response.data!;
            } else {
              throw Exception(response.error ?? 'Failed to load prescriptions');
            }
          },
        );
      }
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'processing':
        return Icons.cached;
      case 'verified':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          // Explicitly set the color here to rule out any theme issues.
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const PharmacyHomePage()),
            );
          },
        ),
        title: const Text('Prescription Tracking'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isAuthenticated
          ? FutureBuilder<List<PrescriptionDetailModel>>(
              future: _prescriptionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _fetchPrescriptions,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  print(
                    'No prescriptions found or data is empty.',
                  ); // Debug print
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          color: Colors.grey.shade400,
                          size: 60,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No prescriptions uploaded yet.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const OrderPrescriptionUploadScreen(),
                              ),
                            ).then((_) => _checkAuthAndFetchPrescriptions());
                          },
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload New Prescription'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  final prescriptions = snapshot.data!;
                  print(
                    'Found ${prescriptions.length} prescriptions.',
                  ); // Debug print
                  return RefreshIndicator(
                    onRefresh: _fetchPrescriptions,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: prescriptions.length,
                      itemBuilder: (context, index) {
                        final prescription = prescriptions[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PrescriptionDetailViewScreen(
                                        prescription: prescription,
                                      ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: (prescription.imageUrl.isNotEmpty)
                                        ? Image.network(
                                            prescription.imageUrl,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => Container(
                                                  width: 80,
                                                  height: 80,
                                                  color: Colors.grey.shade200,
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                          )
                                        : Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.grey.shade200,
                                            child: Icon(
                                              Icons
                                                  .receipt_long, // Placeholder icon
                                              color: Colors.grey.shade400,
                                              size: 40,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Prescription #${index + 1}', // Use index number
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              _getStatusIcon(
                                                prescription.status,
                                              ),
                                              color: _getStatusColor(
                                                prescription.status,
                                              ),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Status: ${prescription.status}',
                                              style: TextStyle(
                                                color: _getStatusColor(
                                                  prescription.status,
                                                ),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Uploaded: ${_formatDate(prescription.uploadedAt)}',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: Colors.teal.shade400,
                      size: 80,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Login Required',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Please log in to view your prescription history and tracking.',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          ).then(
                            (_) => _checkAuthAndFetchPrescriptions(),
                          ); // Refresh on return
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Login Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OrderPrescriptionUploadScreen(),
            ),
          ).then((_) => _checkAuthAndFetchPrescriptions());
        },
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
