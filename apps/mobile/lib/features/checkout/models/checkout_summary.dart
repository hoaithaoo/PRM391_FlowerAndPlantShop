class CheckoutSummaryItem {
  const CheckoutSummaryItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.imageUrl,
    this.imageAsset,
    this.variant,
  });

  final String productId;
  final String name;
  final int quantity;
  final num unitPrice;
  final num subtotal;
  final String? imageUrl;
  final String? imageAsset;
  final String? variant;
}

class CheckoutSummary {
  const CheckoutSummary({
    this.items = const <CheckoutSummaryItem>[],
    required this.subtotal,
    required this.tax,
    required this.shippingFee,
    required this.grandTotal,
    this.discount = 0,
    this.shippingDiscount = 0,
  });

  final List<CheckoutSummaryItem> items;
  final num subtotal;
  final num tax;
  final num shippingFee;
  final num grandTotal;
  final num discount;
  final num shippingDiscount;

  CheckoutSummary copyWith({
    List<CheckoutSummaryItem>? items,
    num? subtotal,
    num? tax,
    num? shippingFee,
    num? grandTotal,
    num? discount,
  }) {
    return CheckoutSummary(
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      shippingFee: shippingFee ?? this.shippingFee,
      grandTotal: grandTotal ?? this.grandTotal,
      discount: discount ?? this.discount,
    );
  }

  int get totalQuantity {
    return items.fold<int>(0, (total, item) => total + item.quantity);
  }
}
