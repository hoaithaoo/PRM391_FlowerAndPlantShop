class ProductModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final double price;
  final double? salePrice;
  final int stock;
  final String? categoryId;
  final String? categoryName;
  final String? imageUrl;
  final bool isActive;

  const ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    this.salePrice,
    required this.stock,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
    this.isActive = true,
  });

  bool get isLowStock => stock <= 5;
  double get displayPrice => salePrice != null && salePrice! > 0 ? salePrice! : price;

  ProductModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    double? price,
    double? salePrice,
    int? stock,
    String? categoryId,
    String? categoryName,
    String? imageUrl,
    bool? isActive,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      price: price ?? this.price,
      salePrice: salePrice ?? this.salePrice,
      stock: stock ?? this.stock,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      salePrice: (json['salePrice'] as num?)?.toDouble(),
      stock: json['stock'] as int? ?? 0,
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String? ?? json['category']?['name'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'description': description,
    'price': price,
    'salePrice': salePrice,
    'stock': stock,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'imageUrl': imageUrl,
    'isActive': isActive,
  };
}
