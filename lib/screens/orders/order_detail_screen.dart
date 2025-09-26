// Order Detail Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';
import 'dart:io'; // For File operations
import 'package:path_provider/path_provider.dart'; // For getting local directory
import 'package:open_filex/open_filex.dart'; // For opening files
import '../../models/order_model.dart';
import 'order_tracking_screen.dart';
import '../../services/api_service.dart'; // Import ApiService

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    final orderProvider = context.read<OrderProvider>();
    final order = await orderProvider.getOrderById(widget.orderId);
    
    setState(() {
      _order = order;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_order != null ? 'Order #${_order!.id}' : 'Order Details'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          if (_order != null) ...[
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Download Invoice',
              onPressed: () => _downloadInvoice(_order!.id),
            ),
            IconButton(
              icon: const Icon(Icons.local_shipping),
              tooltip: 'Track Order',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderTrackingScreen(
                      order: OrderModel(
                        id: _order!.id,
                        orderNumber: _order!.id.toString(),
                        orderDate: _order!.createdAt,
                        status: _order!.status,
                        statusDisplayName: _order!.status,
                        totalAmount: _order!.totalAmount,
                        totalItems: _order!.items.length,
                        paymentStatus: _order!.paymentStatus ?? 'Unknown',
                        paymentMethod: _order!.paymentMethod ?? 'Unknown',
                        items: [],
                        shippingAddress: null,
                      ),
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                Fluttertoast.showToast(
                  msg: "Share feature coming soon!",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                );
              },
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            )
          : _order == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Order not found',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Status Card
                      _buildOrderStatusCard(),
                      
                      const SizedBox(height: 16),
                      
                      // Order Items
                      _buildOrderItemsCard(),
                      
                      const SizedBox(height: 16),
                      
                      // Delivery Information
                      if (_order!.shippingAddress != null)
                        _buildDeliveryInfoCard(),
                      
                      const SizedBox(height: 16),
                      
                      // Payment Information
                      _buildPaymentInfoCard(),
                      
                      const SizedBox(height: 16),
                      
                      // Order Summary
                      _buildOrderSummaryCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOrderStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_order!.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _order!.statusDisplayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildInfoRow('Order Date', _formatDate(_order!.createdAt)),
            if (_order!.estimatedDelivery != null)
              _buildInfoRow('Estimated Delivery', _formatDate(_order!.estimatedDelivery!)),
            if (_order!.trackingNumber != null)
              _buildInfoRow('Tracking Number', _order!.trackingNumber!),
            if (_order!.notes?.contains('prescription') == true)
              _buildInfoRow('Prescription Order', 'Yes'),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Items (${_order!.totalItems})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            ...(_order!.items.map((item) => _buildOrderItem(item)).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: item.productImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.productImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.medical_services,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.medical_services,
                    color: Colors.grey,
                  ),
          ),
          
          const SizedBox(width: 12),
          
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  'Qty: ${item.quantity}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Qty: ${item.quantity}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₹${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delivery Address',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _order!.shippingAddress!.fullAddress,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildInfoRow('Payment Method', _order!.paymentMethod ?? 'Not specified'),
            if (_order!.paymentStatus != null)
              _buildInfoRow('Payment Status', _order!.paymentStatus!),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),

            // Order summary calculations
            ..._buildOrderSummaryRows(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOrderSummaryRows() {
    // Calculate subtotal, shipping, etc.
    double subtotal = _order!.items.fold(0.0, (sum, item) => sum + item.totalPrice);
    double shipping = subtotal >= 500 ? 0.0 : 50.0;
    double discount = subtotal >= 1000 ? subtotal * 0.1 : 0.0;

    return [
      _buildSummaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
      _buildSummaryRow('Shipping', shipping == 0 ? 'Free' : '₹${shipping.toStringAsFixed(2)}'),
      if (discount > 0)
        _buildSummaryRow('Discount', '-₹${discount.toStringAsFixed(2)}'),

      const Divider(thickness: 2),

      _buildSummaryRow(
        'Total Amount',
        '₹${_order!.totalAmount.toStringAsFixed(2)}',
        isTotal: true,
      ),
    ];
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.teal : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _downloadInvoice(int orderId) async {
    Fluttertoast.showToast(
      msg: "Downloading invoice...",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );

    try {
      final apiService = ApiService();
      final response = await apiService.downloadInvoicePdf(orderId);

      if (response.isSuccess && response.data != null) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/invoice_$orderId.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.data!);

        Fluttertoast.showToast(
          msg: "Invoice downloaded to $filePath",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );

        // Open the downloaded file
        final result = await OpenFilex.open(filePath);
        if (result.type != ResultType.done) {
          Fluttertoast.showToast(
            msg: "Could not open file: ${result.message}",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: "Failed to download invoice: ${response.error}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error downloading invoice: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }
}
