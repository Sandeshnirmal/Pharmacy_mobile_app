import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/prescription.dart';
import '../../services/api_service.dart';

class PrescriptionHistoryScreen extends StatefulWidget {
  const PrescriptionHistoryScreen({super.key});

  @override
  State<PrescriptionHistoryScreen> createState() => _PrescriptionHistoryScreenState();
}

class _PrescriptionHistoryScreenState extends State<PrescriptionHistoryScreen> {
  final ApiService _apiService = ApiService();
  List<Prescription> prescriptions = [];
  bool isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    try {
      setState(() => isLoading = true);
      final response = await _apiService.getPrescriptions();
      if (response['success']) {
        setState(() {
          prescriptions = (response['data'] as List)
              .map((json) => Prescription.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading prescriptions: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription History'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Prescriptions'),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Text('Pending Review'),
              ),
              const PopupMenuItem(
                value: 'approved',
                child: Text('Approved'),
              ),
              const PopupMenuItem(
                value: 'rejected',
                child: Text('Rejected'),
              ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _buildPrescriptionList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUploadDialog(),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPrescriptionList() {
    List<Prescription> filteredPrescriptions = prescriptions;
    
    if (_selectedFilter != 'all') {
      filteredPrescriptions = prescriptions.where((prescription) => 
        prescription.status.toLowerCase() == _selectedFilter.toLowerCase()
      ).toList();
    }

    if (filteredPrescriptions.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadPrescriptions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredPrescriptions.length,
        itemBuilder: (context, index) {
          final prescription = filteredPrescriptions[index];
          return _buildPrescriptionCard(prescription);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No prescriptions found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your first prescription to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showUploadDialog(),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Upload Prescription'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(Prescription prescription) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showPrescriptionDetails(prescription),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Prescription Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Prescription #${prescription.id}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(prescription.status),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Upload Date
              Text(
                'Uploaded on ${DateFormat('MMM dd, yyyy').format(prescription.uploadDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Medicines Count
              if (prescription.medicines.isNotEmpty) ...[
                Text(
                  '${prescription.medicines.length} medicine${prescription.medicines.length > 1 ? 's' : ''} detected',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  prescription.medicines.take(2).map((med) => med.name).join(', ') +
                  (prescription.medicines.length > 2 ? '...' : ''),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // AI Confidence
              if (prescription.aiConfidence != null) ...[
                Row(
                  children: [
                    const Text(
                      'AI Confidence: ',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      '${(prescription.aiConfidence! * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: prescription.aiConfidence! > 0.8 
                            ? Colors.green 
                            : prescription.aiConfidence! > 0.6 
                                ? Colors.orange 
                                : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (prescription.status.toLowerCase() == 'approved') ...[
                    TextButton(
                      onPressed: () => _createOrder(prescription),
                      child: const Text('Create Order'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton(
                    onPressed: () => _showPrescriptionDetails(prescription),
                    child: const Text('View Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    
    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'approved':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'rejected':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      case 'processing':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Prescription'),
        content: const Text('Choose how you want to upload your prescription:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadFromCamera();
            },
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadFromGallery();
            },
            child: const Text('Gallery'),
          ),
        ],
      ),
    );
  }

  void _uploadFromCamera() {
    // TODO: Implement camera upload
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Camera upload feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _uploadFromGallery() {
    // TODO: Implement gallery upload
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gallery upload feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showPrescriptionDetails(Prescription prescription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Prescription #${prescription.id}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${prescription.status}'),
              const SizedBox(height: 8),
              Text('Upload Date: ${DateFormat('MMM dd, yyyy HH:mm').format(prescription.uploadDate)}'),
              if (prescription.aiConfidence != null) ...[
                const SizedBox(height: 8),
                Text('AI Confidence: ${(prescription.aiConfidence! * 100).toInt()}%'),
              ],
              const SizedBox(height: 16),
              const Text('Detected Medicines:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...prescription.medicines.map((medicine) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• ${medicine.name} - ${medicine.dosage}'),
                ),
              ),
            ],
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

  void _createOrder(Prescription prescription) {
    // TODO: Implement create order from prescription
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order creation feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
