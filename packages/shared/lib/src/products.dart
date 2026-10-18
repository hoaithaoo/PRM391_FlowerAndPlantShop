/// Model sản phẩm dùng chung, khớp với contract `docs/spec.md` mục 7.3–7.5.
library;

/// Danh mục sản phẩm (GET /api/v1/categories).
class Category {
  const Category({required this.id, required this.name, this.slug});

  final String id;
  final String name;
  final String? slug;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Category && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// Cách sắp xếp danh sách sản phẩm mà backend chấp nhận.
enum ProductSort {
  newest('newest'),
  priceAsc('price_asc'),
  priceDesc('price_desc');

  const ProductSort(this.apiValue);

  /// Giá trị gửi lên query `sort`.
  final String apiValue;
}

/// Một dòng trong danh sách sản phẩm (GET /api/v1/products).
class ProductSummary {
  const ProductSummary({
    required this.id,
    required this.sku,
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
    this.imageUrl,
  });

  final String id;
  final String sku;
  final String name;

  /// Giá VND, số nguyên.
  final int price;
  final int stock;
  final String? imageUrl;
  final Category category;

  bool get inStock => stock > 0;

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    return ProductSummary(
      id: json['id'] as String,
      sku: json['sku'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).round(),
      stock: (json['stock'] as num).toInt(),
      imageUrl: json['imageUrl'] as String?,
      category: Category.fromJson(json['category'] as Map<String, dynamic>),
    );
  }
}

/// Chi tiết một sản phẩm (GET /api/v1/products/:id).
class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.sku,
    required this.name,
    required this.price,
    required this.stock,
    required this.taxRate,
    required this.category,
    this.description,
    this.imageUrls = const [],
    this.isActive = true,
  });

  final String id;
  final String sku;
  final String name;
  final String? description;

  /// Giá VND, số nguyên.
  final int price;
  final int stock;

  /// Thuế suất (%) do server quyết định khi checkout.
  final double taxRate;
  final List<String> imageUrls;
  final Category category;
  final bool isActive;

  bool get inStock => stock > 0;

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: json['id'] as String,
      sku: json['sku'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).round(),
      stock: (json['stock'] as num).toInt(),
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0,
      imageUrls: [
        for (final url in (json['imageUrls'] as List<dynamic>? ?? const []))
          url as String,
      ],
      category: Category.fromJson(json['category'] as Map<String, dynamic>),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

/// Một trang kết quả theo offset paging (`page`/`limit`).
class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.page,
    required this.total,
    required this.totalPages,
  });

  final List<T> items;
  final int page;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

/// Bộ lọc của màn danh sách sản phẩm.
class ProductQuery {
  const ProductQuery({
    this.search,
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.sort = ProductSort.newest,
  });

  final String? search;
  final String? categoryId;
  final int? minPrice;
  final int? maxPrice;
  final ProductSort sort;

  bool get hasPriceFilter => minPrice != null || maxPrice != null;

  ProductQuery copyWith({
    Object? search = _unset,
    Object? categoryId = _unset,
    Object? minPrice = _unset,
    Object? maxPrice = _unset,
    ProductSort? sort,
  }) {
    return ProductQuery(
      search: identical(search, _unset) ? this.search : search as String?,
      categoryId: identical(categoryId, _unset)
          ? this.categoryId
          : categoryId as String?,
      minPrice: identical(minPrice, _unset) ? this.minPrice : minPrice as int?,
      maxPrice: identical(maxPrice, _unset) ? this.maxPrice : maxPrice as int?,
      sort: sort ?? this.sort,
    );
  }

  /// Query string gửi lên backend; bỏ các giá trị rỗng vì backend trả 400
  /// với `search=` hoặc `categoryId=` rỗng.
  Map<String, String> toQueryParameters({required int page, required int limit}) {
    final trimmedSearch = search?.trim();
    return {
      'page': '$page',
      'limit': '$limit',
      'sort': sort.apiValue,
      if (trimmedSearch != null && trimmedSearch.isNotEmpty)
        'search': trimmedSearch,
      if (categoryId != null && categoryId!.isNotEmpty) 'categoryId': categoryId!,
      if (minPrice != null) 'minPrice': '$minPrice',
      if (maxPrice != null) 'maxPrice': '$maxPrice',
    };
  }

  @override
  bool operator ==(Object other) =>
      other is ProductQuery &&
      other.search == search &&
      other.categoryId == categoryId &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(search, categoryId, minPrice, maxPrice, sort);
}

const Object _unset = Object();
