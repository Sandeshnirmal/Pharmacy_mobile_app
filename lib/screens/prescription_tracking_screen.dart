import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy/ProductDetailsScreen.dart';
import 'package:provider/provider.dart';
import 'package:pharmacy/models/prescription_detail_model.dart';
import 'package:pharmacy/services/prescription_service.dart';
import 'package:pharmacy/services/auth_service.dart'; // Import AuthService
import 'package:pharmacy/providers/cart_provider.dart';
// Import ProductModel
import 'package:pharmacy/LoginScreen.dart'; // Import LoginScreen

class PrescriptionTrackingScreen extends StatefulWidget {
  final String? prescriptionId; // Added optional prescriptionId

  const PrescriptionTrackingScreen({super.key, this.prescriptionId});

  @override
  State<PrescriptionTrackingScreen> createState() =>
      _PrescriptionTrackingScreenState();
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
                            // Navigate to upload prescription screen
                            // Placeholder for now, actual navigation will be added later
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Navigate to Prescription Upload Screen',
                                ),
                              ),
                            );
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
    );
  }
}

// Helper functions for status icons and colors (moved to top-level)
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

class PrescriptionDetailViewScreen extends StatelessWidget {
  final PrescriptionDetailModel prescription;

  const PrescriptionDetailViewScreen({super.key, required this.prescription});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Prescription #${prescription.id}'),
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
                        height: 250,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 250,
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey.shade400,
                            size: 80,
                          ),
                        ),
                      )
                    : Container(
                        height: 250,
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.receipt_long, // Placeholder icon
                          color: Colors.grey.shade400,
                          size: 80,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoCard(
              title: 'Status',
              value: prescription.status,
              icon: _getStatusIcon(prescription.status),
              color: _getStatusColor(prescription.status),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Uploaded On',
              value: DateFormat(
                'dd MMM yyyy, hh:mm a',
              ).format(prescription.uploadedAt),
              icon: Icons.calendar_today,
              color: Colors.blueGrey,
            ),
            if (prescription.prescriptionNumber != null &&
                prescription.prescriptionNumber!.isNotEmpty)
              _buildInfoCard(
                title: 'Prescription Number',
                value: prescription.prescriptionNumber!,
                icon: Icons.confirmation_number,
                color: Colors.indigo,
              ),
            if (prescription.prescriptionDate != null)
              _buildInfoCard(
                title: 'Prescription Date',
                value: DateFormat(
                  'dd MMM yyyy',
                ).format(prescription.prescriptionDate!),
                icon: Icons.date_range,
                color: Colors.deepOrange,
              ),
            if (prescription.processingStatus != null &&
                prescription.processingStatus!.isNotEmpty)
              _buildInfoCard(
                title: 'Processing Status',
                value: prescription.processingStatus!,
                icon: Icons.data_usage,
                color: Colors.purple,
              ),
            if (prescription.aiConfidenceScore != null)
              _buildInfoCard(
                title: 'AI Confidence Score',
                value:
                    '${(prescription.aiConfidenceScore! * 100).toStringAsFixed(1)}%',
                icon: Icons.psychology,
                color: Colors.green,
              ),
            if (prescription.totalMedicines != null)
              _buildInfoCard(
                title: 'Total Medicines',
                value: prescription.totalMedicines.toString(),
                icon: Icons.format_list_numbered,
                color: Colors.brown,
              ),
            if (prescription.verifiedMedicines != null)
              _buildInfoCard(
                title: 'Verified Medicines',
                value: prescription.verifiedMedicines.toString(),
                icon: Icons.check_circle,
                color: Colors.teal,
              ),
            const SizedBox(height: 24),
            const Text(
              'User Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Divider(height: 20, thickness: 1),
            if (prescription.userName != null &&
                prescription.userName!.isNotEmpty)
              _buildInfoCard(
                title: 'User Name',
                value: prescription.userName!,
                icon: Icons.person,
                color: Colors.blueGrey,
              ),
            if (prescription.userEmail != null &&
                prescription.userEmail!.isNotEmpty)
              _buildInfoCard(
                title: 'User Email',
                value: prescription.userEmail!,
                icon: Icons.email,
                color: Colors.blueGrey,
              ),
            if (prescription.userPhone != null &&
                prescription.userPhone!.isNotEmpty)
              _buildInfoCard(
                title: 'User Phone',
                value: prescription.userPhone!,
                icon: Icons.phone,
                color: Colors.blueGrey,
              ),
            const SizedBox(height: 24),
            const Text(
              'Patient & Doctor Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Divider(height: 20, thickness: 1),
            if (prescription.patientName != null &&
                prescription.patientName!.isNotEmpty)
              _buildInfoCard(
                title: 'Patient Name',
                value: prescription.patientName!,
                icon: Icons.person_outline,
                color: Colors.deepPurple,
              ),
            if (prescription.patientAge != null)
              _buildInfoCard(
                title: 'Patient Age',
                value: prescription.patientAge.toString(),
                icon: Icons.cake,
                color: Colors.deepPurple,
              ),
            if (prescription.patientGender != null &&
                prescription.patientGender!.isNotEmpty)
              _buildInfoCard(
                title: 'Patient Gender',
                value: prescription.patientGender!,
                icon: Icons.transgender,
                color: Colors.deepPurple,
              ),
            if (prescription.doctorName != null &&
                prescription.doctorName!.isNotEmpty)
              _buildInfoCard(
                title: 'Doctor Name',
                value: prescription.doctorName!,
                icon: Icons.local_hospital,
                color: Colors.indigo,
              ),
            if (prescription.doctorLicense != null &&
                prescription.doctorLicense!.isNotEmpty)
              _buildInfoCard(
                title: 'Doctor License',
                value: prescription.doctorLicense!,
                icon: Icons.badge,
                color: Colors.indigo,
              ),
            if (prescription.hospitalClinic != null &&
                prescription.hospitalClinic!.isNotEmpty)
              _buildInfoCard(
                title: 'Hospital/Clinic',
                value: prescription.hospitalClinic!,
                icon: Icons.apartment,
                color: Colors.indigo,
              ),
            // Display extracted medicine details if available
            if (prescription.extractedMedicineName != null &&
                prescription.extractedMedicineName!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Extracted Prescription Details (Legacy)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Divider(height: 20, thickness: 1),
              _buildInfoCard(
                title: 'Medicine Name',
                value: prescription.extractedMedicineName!,
                icon: Icons.medical_information,
                color: Colors.deepPurple,
              ),
              if (prescription.extractedDosage != null &&
                  prescription.extractedDosage!.isNotEmpty)
                _buildInfoCard(
                  title: 'Dosage',
                  value: prescription.extractedDosage!,
                  icon: Icons.straighten,
                  color: Colors.indigo,
                ),
              if (prescription.extractedForm != null &&
                  prescription.extractedForm!.isNotEmpty)
                _buildInfoCard(
                  title: 'Form',
                  value: prescription.extractedForm!,
                  icon: Icons.category,
                  color: Colors.blue,
                ),
              if (prescription.extractedFrequency != null &&
                  prescription.extractedFrequency!.isNotEmpty)
                _buildInfoCard(
                  title: 'Frequency',
                  value: prescription.extractedFrequency!,
                  icon: Icons.access_time,
                  color: Colors.lightBlue,
                ),
            ],
            const SizedBox(height: 24),
            Text(
              'Prescription Medicines (${prescription.prescriptionMedicines?.length ?? 0})',
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
                    'No detailed medicines found for this prescription.',
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
                    child: ExpansionTile(
                      title: Text(
                        medicineDetail.extractedMedicineName ??
                            'Unknown Medicine',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Status: ${medicineDetail.verificationStatusDisplay ?? 'N/A'}',
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (medicineDetail.recognizedTextRaw != null &&
                                  medicineDetail.recognizedTextRaw!.isNotEmpty)
                                _buildDetailRow(
                                  'Raw Text:',
                                  medicineDetail.recognizedTextRaw!,
                                ),
                              if (medicineDetail.extractedMedicineName !=
                                      null &&
                                  medicineDetail
                                      .extractedMedicineName!
                                      .isNotEmpty)
                                _buildDetailRow(
                                  'Extracted Name:',
                                  medicineDetail.extractedMedicineName!,
                                ),
                              if (medicineDetail.extractedDosage != null &&
                                  medicineDetail.extractedDosage!.isNotEmpty)
                                _buildDetailRow(
                                  'Extracted Dosage:',
                                  medicineDetail.extractedDosage!,
                                ),
                              if (medicineDetail.extractedFrequency != null &&
                                  medicineDetail.extractedFrequency!.isNotEmpty)
                                _buildDetailRow(
                                  'Extracted Frequency:',
                                  medicineDetail.extractedFrequency!,
                                ),
                              if (medicineDetail.extractedForm != null &&
                                  medicineDetail.extractedForm!.isNotEmpty)
                                _buildDetailRow(
                                  'Extracted Form:',
                                  medicineDetail.extractedForm!,
                                ),
                              if (medicineDetail.extractedDuration != null &&
                                  medicineDetail.extractedDuration!.isNotEmpty)
                                _buildDetailRow(
                                  'Extracted Duration:',
                                  medicineDetail.extractedDuration!,
                                ),
                              if (medicineDetail.extractedInstructions !=
                                      null &&
                                  medicineDetail
                                      .extractedInstructions!
                                      .isNotEmpty)
                                _buildDetailRow(
                                  'Extracted Instructions:',
                                  medicineDetail.extractedInstructions!,
                                ),
                              if (medicineDetail.aiConfidenceScore != null)
                                _buildDetailRow(
                                  'AI Confidence:',
                                  '${(medicineDetail.aiConfidenceScore! * 100).toStringAsFixed(1)}%',
                                ),
                              if (medicineDetail.verifiedMedicineName != null &&
                                  medicineDetail
                                      .verifiedMedicineName!
                                      .isNotEmpty)
                                _buildDetailRow(
                                  'Verified Name:',
                                  medicineDetail.verifiedMedicineName!,
                                ),
                              if (medicineDetail.verifiedDosage != null &&
                                  medicineDetail.verifiedDosage!.isNotEmpty)
                                _buildDetailRow(
                                  'Verified Dosage:',
                                  medicineDetail.verifiedDosage!,
                                ),
                              if (medicineDetail.verifiedFrequency != null &&
                                  medicineDetail.verifiedFrequency!.isNotEmpty)
                                _buildDetailRow(
                                  'Verified Frequency:',
                                  medicineDetail.verifiedFrequency!,
                                ),
                              if (medicineDetail.verifiedDuration != null &&
                                  medicineDetail.verifiedDuration!.isNotEmpty)
                                _buildDetailRow(
                                  'Verified Duration:',
                                  medicineDetail.verifiedDuration!,
                                ),
                              if (medicineDetail.verifiedQuantity != null)
                                _buildDetailRow(
                                  'Verified Quantity:',
                                  medicineDetail.verifiedQuantity.toString(),
                                ),
                              if (medicineDetail.verifiedInstructions != null &&
                                  medicineDetail
                                      .verifiedInstructions!
                                      .isNotEmpty)
                                _buildDetailRow(
                                  'Verified Instructions:',
                                  medicineDetail.verifiedInstructions!,
                                ),
                              if (medicineDetail.quantityPrescribed != null)
                                _buildDetailRow(
                                  'Quantity Prescribed:',
                                  medicineDetail.quantityPrescribed.toString(),
                                ),
                              if (medicineDetail.quantityDispensed != null)
                                _buildDetailRow(
                                  'Quantity Dispensed:',
                                  medicineDetail.quantityDispensed.toString(),
                                ),
                              if (medicineDetail.unitPrice != null)
                                _buildDetailRow(
                                  'Unit Price:',
                                  '₹${medicineDetail.unitPrice!.toStringAsFixed(2)}',
                                ),
                              if (medicineDetail.totalPrice != null)
                                _buildDetailRow(
                                  'Total Price:',
                                  '₹${medicineDetail.totalPrice!.toStringAsFixed(2)}',
                                ),
                              if (medicineDetail.isPrescriptionRequired != null)
                                _buildDetailRow(
                                  'Prescription Required:',
                                  medicineDetail.isPrescriptionRequired!
                                      ? 'Yes'
                                      : 'No',
                                ),
                              if (medicineDetail.customerApproved != null)
                                _buildDetailRow(
                                  'Customer Approved:',
                                  medicineDetail.customerApproved!
                                      ? 'Yes'
                                      : 'No',
                                ),
                              if (medicineDetail.pharmacistComment != null &&
                                  medicineDetail.pharmacistComment!.isNotEmpty)
                                _buildDetailRow(
                                  'Pharmacist Comment:',
                                  medicineDetail.pharmacistComment!,
                                ),
                              if (medicineDetail.clarificationNotes != null &&
                                  medicineDetail.clarificationNotes!.isNotEmpty)
                                _buildDetailRow(
                                  'Clarification Notes:',
                                  medicineDetail.clarificationNotes!,
                                ),
                              const SizedBox(height: 10),
                              if (medicineDetail.mappedProduct != null) ...[
                                const Text(
                                  'Mapped Product:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      medicineDetail.mappedProduct!.imageUrl ??
                                          'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400',
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                width: 40,
                                                height: 40,
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
                                  ),
                                  subtitle: Text(
                                    '₹${medicineDetail.mappedProduct!.price.toStringAsFixed(2)}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.add_shopping_cart,
                                      color: Colors.teal,
                                    ),
                                    onPressed: () {
                                      cartProvider.addItem(
                                        medicineDetail.mappedProduct!,
                                        1,
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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
                                        builder: (context) =>
                                            ProductDetailsScreen(
                                              product: medicineDetail
                                                  .mappedProduct!
                                                  .toJson(),
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                              if (medicineDetail.suggestedProducts != null &&
                                  medicineDetail
                                      .suggestedProducts!
                                      .isNotEmpty) ...[
                                const SizedBox(height: 10),
                                const Text(
                                  'Other Suggestions:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ...medicineDetail.suggestedProducts!.map(
                                  (product) => ListTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        product.imageUrl ??
                                            'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400',
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  color: Colors.grey.shade200,
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                      ),
                                    ),
                                    title: Text(product.name),
                                    subtitle: Text(
                                      '₹${product.price.toStringAsFixed(2)}',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.add_shopping_cart,
                                        color: Colors.teal,
                                      ),
                                      onPressed: () {
                                        cartProvider.addItem(product, 1);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${product.name} added to cart!',
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
                                          builder: (context) =>
                                              ProductDetailsScreen(
                                                product: product.toJson(),
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
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
                    'No aggregated medicines suggested yet or prescription is still processing.',
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
                        '${medicine.manufacturer ?? 'N/A'} - ₹${medicine.price.toStringAsFixed(2) ?? '0.00'}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.add_shopping_cart,
                          color: Colors.teal,
                        ),
                        onPressed: () {
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
                              product: medicine.toJson(),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
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
