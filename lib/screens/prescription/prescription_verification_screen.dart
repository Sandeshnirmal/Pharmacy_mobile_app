// Prescription Verification Screen - After Payment Confirmation
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/api_response.dart';
import '../../utils/api_logger.dart';
import '../orders/order_confirmation_screen.dart';

class PrescriptionVerificationScreen extends StatefulWidget {
  final int orderId;
  final String orderNumber;
  final int prescriptionId;
  final double totalAmount;

  const PrescriptionVerificationScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.prescriptionId,
    required this.totalAmount,
  });

  @override
  State<PrescriptionVerificationScreen> createState() => _PrescriptionVerificationScreenState();
}

class _PrescriptionVerificationScreenState extends State<PrescriptionVerificationScreen> {
  final ApiService _apiService = ApiService();
  
  String _verificationStatus = 'pending';
  String? _verificationNotes;
  bool _isLoading = true;
  String? _error;
  String? _prescriptionImageUrl;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
    _startStatusPolling();
  }

  Future<void> _loadVerificationStatus() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get prescription verification status
      final response = await _apiService.getPrescriptionVerificationStatus(widget.prescriptionId);
      
      if (response.isSuccess && response.data != null) {
        setState(() {
          _verificationStatus = response.data!['status'] ?? 'pending';
          _verificationNotes = response.data!['verification_notes'];
          _prescriptionImageUrl = response.data!['image_url'];
        });

        // If verified, automatically confirm the order
        if (_verificationStatus == 'verified') {
          await _confirmOrder();
        }
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load verification status';
        });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load verification status: $e';
        _isLoading = false;
      });
      ApiLogger.logError('Verification status error: $e');
    }
  }

  void _startStatusPolling() {
    // Poll status every 15 seconds if still pending
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && (_verificationStatus == 'pending' || _verificationStatus == 'under_review')) {
        _loadVerificationStatus();
        _startStatusPolling();
      }
    });
  }

  Future<void> _confirmOrder() async {
    try {
      // Confirm the order after prescription verification
      final response = await _apiService.confirmPrescriptionOrder(widget.orderId);
      
      if (response.isSuccess) {
        // Navigate to order confirmation
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OrderConfirmationScreen(
                orderId: widget.orderId,
                orderNumber: widget.orderNumber,
                totalAmount: widget.totalAmount,
              ),
            ),
          );
        }
      } else {
        setState(() {
          _error = response.error ?? 'Failed to confirm order';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Order confirmation failed: $e';
      });
      ApiLogger.logError('Order confirmation error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Verification'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Prevent going back
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.teal),
            SizedBox(height: 16),
            Text('Loading verification status...'),
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
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadVerificationStatus,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPaymentConfirmation(),
          const SizedBox(height: 24),
          _buildVerificationStatus(),
          const SizedBox(height: 24),
          if (_prescriptionImageUrl != null) _buildPrescriptionImage(),
          const SizedBox(height: 24),
          _buildOrderDetails(),
          const SizedBox(height: 24),
          _buildNextSteps(),
        ],
      ),
    );
  }

  Widget _buildPaymentConfirmation() {
    return Card(
      elevation: 4,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Confirmed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order #${widget.orderNumber} • ₹${widget.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
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

  Widget _buildVerificationStatus() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDescription;

    switch (_verificationStatus) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Verification Pending';
        statusDescription = 'Your prescription is in queue for verification by our pharmacist';
        break;
      case 'under_review':
        statusColor = Colors.blue;
        statusIcon = Icons.visibility;
        statusText = 'Under Review';
        statusDescription = 'Our pharmacist is reviewing your prescription';
        break;
      case 'verified':
        statusColor = Colors.green;
        statusIcon = Icons.verified;
        statusText = 'Verified Successfully';
        statusDescription = 'Prescription verified! Your order is being processed';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Verification Failed';
        statusDescription = 'Prescription could not be verified. Please contact support';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Unknown Status';
        statusDescription = 'Status unknown';
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusDescription,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_verificationStatus == 'pending' || _verificationStatus == 'under_review')
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            if (_verificationNotes != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verification Notes:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _verificationNotes!,
                      style: const TextStyle(fontSize: 14),
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

  Widget _buildPrescriptionImage() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Uploaded Prescription',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _prescriptionImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Image not available', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Order Number', widget.orderNumber),
            _buildDetailRow('Order ID', '#${widget.orderId}'),
            _buildDetailRow('Total Amount', '₹${widget.totalAmount.toStringAsFixed(2)}'),
            _buildDetailRow('Order Type', 'Prescription Order'),
            _buildDetailRow('Payment Status', 'Confirmed'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextSteps() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.teal, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'What happens next?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStepItem(
              1,
              'Prescription Verification',
              _verificationStatus == 'verified' ? 'Completed' : 'In Progress',
              _verificationStatus == 'verified',
            ),
            _buildStepItem(
              2,
              'Order Processing',
              _verificationStatus == 'verified' ? 'In Progress' : 'Waiting',
              false,
            ),
            _buildStepItem(
              3,
              'Medicine Preparation',
              'Waiting',
              false,
            ),
            _buildStepItem(
              4,
              'Delivery',
              'Waiting',
              false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(int step, String title, String status, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      step.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: isCompleted ? Colors.green : Colors.grey[600],
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
