class CheckoutSummaryItem {
  const CheckoutSummaryItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.imageUrl,
  });

  final String productId;
  final String name;
  final int quantity;
  final num unitPrice;
  final num subtotal;
  final String? imageUrl;
}

class CheckoutSummary {
  const CheckoutSummary({
    this.items = const <CheckoutSummaryItem>[],
    required this.subtotal,
    required this.tax,
    required this.shippingFee,
    required this.grandTotal,
  });

  final List<CheckoutSummaryItem> items;
  final num subtotal;
  final num tax;
  final num shippingFee;
  final num grandTotal;

  int get totalQuantity {
    return items.fold<int>(0, (total, item) => total + item.quantity);
  }
}
