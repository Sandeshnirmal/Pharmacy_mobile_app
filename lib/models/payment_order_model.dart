class PaymentOrderModel {
  final double amount;
  final String currency;
  final Map<String, dynamic>? metadata;
  final String? orderId;

  PaymentOrderModel({
    required this.amount,
    this.currency = 'INR',
    this.metadata,
    this.orderId,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': (amount * 100).toInt(), // Convert to paise
      'currency': currency,
      'receipt': orderId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'notes': metadata ?? {},
    };
  }

  factory PaymentOrderModel.fromJson(Map<String, dynamic> json) {
    return PaymentOrderModel(
      amount:
          (json['amount'] as num).toDouble() /
          100, // Convert from paise to rupees
      currency: json['currency'] ?? 'INR',
      orderId: json['receipt'],
      metadata: json['notes'],
    );
  }
}
