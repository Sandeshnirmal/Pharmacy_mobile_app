import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../models/order.dart'; // Import your existing Order model
import '../../models/user_model.dart'; // Import your user model

// --- Data Models for the Invoice Template ---
// Note: These are kept separate to match the template's structure.
class _Vendor {
  final String name;
  final String address;
  _Vendor({required this.name, required this.address});
}

class _InvoiceOrderItem {
  final String name;
  final String? description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  _InvoiceOrderItem({
    required this.name,
    this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });
}

class _PaymentDetails {
  final String paymentMethod;
  final String transactionId;
  _PaymentDetails({required this.paymentMethod, required this.transactionId});
}

class _FinancialDetails {
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalPrice;
  final double amountPaid;
  final double balanceDue;
  _FinancialDetails({
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalPrice,
    required this.amountPaid,
    required this.balanceDue,
  });
}

class _Invoice {
  final _Vendor vendor;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime paymentDate;
  final List<_InvoiceOrderItem> items;
  final _PaymentDetails? paymentDetails;
  final String? termsAndConditions;
  final _FinancialDetails financial;
  _Invoice({
    required this.vendor,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.paymentDate,
    required this.items,
    this.paymentDetails,
    this.termsAndConditions,
    required this.financial,
  });
}

// --- Invoice Screen Widget ---

class InvoiceViewScreen extends StatelessWidget {
  final Order order;
  final UserModel user;

  const InvoiceViewScreen({super.key, required this.order, required this.user});

  String _displayFormatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMM, yyyy').format(date);
  }

  void _handlePrint(BuildContext context) {
    // In a real app, use a package like 'printing' to generate and print a PDF.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Printing feature would be implemented here."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Data Mapping: Convert your Order object to the Invoice template's data models ---

    final List<_InvoiceOrderItem> _invoiceItems = order.items.map((item) {
      final int quantity = item.quantity ?? 0;
      final double totalPrice = item.totalPrice ?? 0.0;
      double unitPrice = (quantity > 0) ? totalPrice / quantity : 0.0;
      return _InvoiceOrderItem(
        name: item.productName ?? 'Unknown Product',
        description: null,
        quantity: quantity,
        unitPrice: unitPrice,
        totalPrice: totalPrice,
      );
    }).toList();

    final double subtotal = _invoiceItems.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
    final isPaid = order.paymentStatus?.toLowerCase() == 'paid';

    final _financial = _FinancialDetails(
      subtotal: subtotal,
      taxAmount: 0.0,
      discountAmount: 0.0,
      totalPrice: order.totalAmount,
      amountPaid: isPaid ? order.totalAmount : 0.0,
      balanceDue: isPaid ? 0.0 : order.totalAmount,
    );

    final _invoice = _Invoice(
      vendor: _Vendor(
        name: "Infixmart",
        address: "123 Health St, Wellness City, 12345",
      ),
      invoiceNumber: "INV-${order.id}",
      invoiceDate: order.orderDate, // Use orderDate
      paymentDate: order.orderDate, // Use orderDate
      items: _invoiceItems,
      paymentDetails: _PaymentDetails(
        paymentMethod: order.paymentMethod ?? "N/A",
        transactionId: "N/A",
      ),
      termsAndConditions:
          "Payment is due within 30 days. Late payments are subject to a fee.",
      financial: _financial,
    );

    // --- UI Build ---
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice Preview')),
      backgroundColor: Colors.grey[100],
      body: Column(
        // Changed to Column to use Expanded
        children: [
          Expanded(
            // Make the main content scrollable and take available space
            child: SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24.0,
                    horizontal: 16.0,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      // Removed the inner Column here
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: _buildInvoiceContent(
                            _invoice,
                            user,
                            order,
                            isPaid,
                            context,
                          ),
                        ),
                        if (isPaid) _buildPaidStamp(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildActionBar(context), // This will now be at the bottom
        ],
      ),
    );
  }

  Widget _buildInvoiceContent(
    _Invoice invoice,
    UserModel user,
    Order orderData,
    bool isPaid,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(invoice, context),
        const SizedBox(height: 32),
        _buildBillToAndDates(invoice, user, orderData, context),
        const SizedBox(height: 40),
        _buildItemsTable(invoice),
        const SizedBox(height: 32),
        _buildSummaryAndTotals(invoice, isPaid, context),
        const SizedBox(height: 48),
        _buildFooter(),
      ],
    );
  }

  Widget _buildPaidStamp() {
    return Positioned(
      top: 24,
      right: 24,
      child: Transform.rotate(
        angle: 12 * (math.pi / 180),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green.shade500, width: 4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "PAID",
            style: TextStyle(
              color: Colors.green.shade500,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(_Invoice invoice, BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget vendorInfo = Row(
      children: [
        const Icon(Icons.local_pharmacy, color: Colors.teal, size: 48),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              invoice.vendor.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            Text(
              invoice.vendor.address,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ],
    );

    Widget invoiceTitle = Column(
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        const Text(
          "INVOICE",
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Color(0xFF374151),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Invoice # ",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
            Text(
              invoice.invoiceNumber,
              style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
            ),
          ],
        ),
      ],
    );

    return Column(
      children: [
        isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  vendorInfo,
                  const SizedBox(height: 24),
                  invoiceTitle,
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [vendorInfo, invoiceTitle],
              ),
        const SizedBox(height: 32),
        const Divider(),
      ],
    );
  }

  Widget _buildBillToAndDates(
    _Invoice invoice,
    UserModel user,
    Order orderData,
    BuildContext context,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget billToSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Bill To:",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "${user.firstName} ${user.lastName}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        Text(
          _formatDeliveryAddress(orderData.deliveryAddress) ??
              (user.addresses?.isNotEmpty == true
                  ? user.addresses!.first.fullAddress
                  : 'N/A'),
          style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
        ),
        Text(
          user.email,
          style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
        ),
        Text(
          user.phoneNumber ?? "N/A",
          style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
        ),
      ],
    );

    Widget datesSection = Column(
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        _buildDateRow(
          "Invoice Date:",
          _displayFormatDate(invoice.invoiceDate),
          isMobile: isMobile,
        ),
        const SizedBox(height: 4),
        _buildDateRow(
          "Payment Date:",
          _displayFormatDate(invoice.paymentDate),
          isMobile: isMobile,
        ),
      ],
    );

    return isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [billToSection, const SizedBox(height: 24), datesSection],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: billToSection),
              const SizedBox(width: 32),
              Expanded(child: datesSection),
            ],
          );
  }

  Widget _buildDateRow(String title, String value, {required bool isMobile}) {
    return Row(
      mainAxisAlignment: isMobile
          ? MainAxisAlignment.start
          : MainAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(width: 12),
        Text(value, style: const TextStyle(color: Color(0xFF1F2937))),
      ],
    );
  }

  Widget _buildItemsTable(_Invoice invoice) {
    return Column(
      children: [
        Container(
          color: Colors.grey[100],
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Expanded(
                flex: 4,
                child: Text(
                  "Description",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
              const Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    "Qty",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Price",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Total",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ...invoice.items
            .map(
              (item) => Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          if (item.description != null)
                            Text(
                              item.description!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Center(child: Text(item.quantity.toString())),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text("₹${item.unitPrice.toStringAsFixed(2)}"),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "₹${item.totalPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildSummaryAndTotals(
    _Invoice invoice,
    bool isPaid,
    BuildContext context,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget detailsSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (invoice.paymentDetails != null) ...[
          const Text(
            "Payment Summary:",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Payment Method: ${invoice.paymentDetails!.paymentMethod}",
            style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
          ),
          Text(
            "Transaction ID: ${invoice.paymentDetails!.transactionId}",
            style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
          ),
        ],
        if (invoice.termsAndConditions != null) ...[
          const SizedBox(height: 24),
          const Text(
            "Terms & Conditions:",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            invoice.termsAndConditions!,
            style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
          ),
        ],
      ],
    );

    Widget totalsSection = Column(
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Column(
            children: [
              _buildTotalRow(
                "Subtotal:",
                "₹${invoice.financial.subtotal.toStringAsFixed(2)}",
              ),
              _buildTotalRow(
                "Tax:",
                "₹${invoice.financial.taxAmount.toStringAsFixed(2)}",
              ),
              _buildTotalRow(
                "Discount:",
                "- ₹${invoice.financial.discountAmount.toStringAsFixed(2)}",
                valueColor: Colors.red,
              ),
              const Divider(height: 16),
              _buildTotalRow(
                "Total Amount:",
                "₹${invoice.financial.totalPrice.toStringAsFixed(2)}",
                isBold: true,
                fontSize: 18,
              ),
              if (isPaid) ...[
                _buildTotalRow(
                  "Amount Paid:",
                  "- ₹${invoice.financial.amountPaid.toStringAsFixed(2)}",
                  valueColor: Colors.green.shade700,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildTotalRow(
                    "Balance Due:",
                    "₹${invoice.financial.balanceDue.toStringAsFixed(2)}",
                    isBold: true,
                    fontSize: 18,
                    valueColor: Colors.green.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              detailsSection,
              const SizedBox(height: 32),
              totalsSection,
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: detailsSection),
              Expanded(flex: 1, child: totalsSection),
            ],
          );
  }

  Widget _buildTotalRow(
    String title,
    String value, {
    bool isBold = false,
    double fontSize = 14,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: fontSize,
              color: const Color(0xFF4B5563),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: fontSize,
              color: valueColor ?? const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Thank you for your business.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    "This is a computer-generated invoice.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 160, // Reduced width for mobile
              child: Column(
                children: [
                  Container(
                    height: 48,
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Authorised Signature",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? _formatDeliveryAddress(Map<String, dynamic>? address) {
    if (address == null || address.isEmpty) return null;
    final addressLine1 = address['address_line1'] ?? '';
    final addressLine2 = address['address_line2'] ?? '';
    final city = address['city'] ?? '';
    final state = address['state'] ?? '';
    final pincode = address['pincode'] ?? '';
    final country = address['country'] ?? '';

    final parts = [
      addressLine1,
      if (addressLine2.isNotEmpty) addressLine2,
      city,
      state,
      pincode,
      country,
    ];
    return parts.where((s) => s.isNotEmpty).join(', ');
  }

  Widget _buildActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12.0),
          bottomRight: Radius.circular(12.0),
        ),
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () => _handlePrint(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text(
              "Print Invoice",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
