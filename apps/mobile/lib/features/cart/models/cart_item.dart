class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.variant,
    required this.unitPrice,
    required this.stock,
    required this.quantity,
    this.imageUrl,
    this.imageAsset,
  });

  final String id;
  final String productId;
  final String name;
  final String variant;
  final int unitPrice;
  final int stock;
  final int quantity;
  final String? imageUrl;
  final String? imageAsset;

  int get subtotal => unitPrice * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
    id: id,
    productId: productId,
    name: name,
    variant: variant,
    unitPrice: unitPrice,
    stock: stock,
    quantity: quantity ?? this.quantity,
    imageUrl: imageUrl,
    imageAsset: imageAsset,
  );

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      productId: json['productId'] as String,
      name: json['name'] as String,
      variant: json['variant'] as String,
      unitPrice: _parseInteger(json['unitPrice'], 'unitPrice'),
      stock: json['stock'] as int,
      quantity: json['quantity'] as int,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

class CartSnapshot {
  const CartSnapshot({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.totalQuantity,
  });

  final String? id;
  final List<CartItem> items;
  final int subtotal;
  final int totalQuantity;

  factory CartSnapshot.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) throw const FormatException('Cart items invalid');
    return CartSnapshot(
      id: json['id'] as String?,
      items: [
        for (final item in rawItems)
          CartItem.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      subtotal: _parseInteger(json['subtotal'], 'subtotal'),
      totalQuantity: json['totalQuantity'] as int,
    );
  }
}

int _parseInteger(Object? value, String field) {
  if (value is int) return value;
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('$field must be an integer');
}
