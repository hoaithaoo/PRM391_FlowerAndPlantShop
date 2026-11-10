/// Đánh giá sản phẩm. Cùng một model cho 3 nơi:
/// trang sản phẩm (có tên khách), "đánh giá của tôi" (có orderId/productId)
/// và admin (thêm isHidden, tên sản phẩm, mã đơn, email).
class ProductReview {
  const ProductReview({
    required this.id,
    required this.rating,
    required this.createdAt,
    this.comment,
    this.imageUrls = const [],
    this.authorName,
    this.authorAvatarUrl,
    this.orderId,
    this.productId,
    this.isHidden = false,
    this.productName,
    this.orderNumber,
    this.authorEmail,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final product = json['product'] as Map<String, dynamic>?;
    final order = json['order'] as Map<String, dynamic>?;
    return ProductReview(
      id: json['id'] as String,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      imageUrls: [
        for (final url in json['imageUrls'] as List<dynamic>? ?? const [])
          url as String,
      ],
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      authorName: user?['fullName'] as String?,
      authorAvatarUrl: user?['avatarUrl'] as String?,
      authorEmail: user?['email'] as String?,
      orderId: json['orderId'] as String?,
      productId: (json['productId'] ?? product?['id']) as String?,
      isHidden: json['isHidden'] as bool? ?? false,
      productName: product?['name'] as String?,
      orderNumber: order?['orderNumber'] as String?,
    );
  }

  final String id;
  final int rating;
  final String? comment;
  final List<String> imageUrls;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatarUrl;
  final String? authorEmail;
  final String? orderId;
  final String? productId;
  final bool isHidden;
  final String? productName;
  final String? orderNumber;
}

class ProductReviewPage {
  const ProductReviewPage({
    required this.items,
    required this.averageRating,
    required this.totalReviews,
  });

  factory ProductReviewPage.fromJson(Map<String, dynamic> data) {
    final summary = data['summary'] as Map<String, dynamic>? ?? const {};
    return ProductReviewPage(
      items: [
        for (final item in data['items'] as List<dynamic>? ?? const [])
          ProductReview.fromJson(item as Map<String, dynamic>),
      ],
      averageRating: (summary['averageRating'] as num?)?.toDouble() ?? 0,
      totalReviews: (summary['totalReviews'] as num?)?.toInt() ?? 0,
    );
  }

  static const empty =
      ProductReviewPage(items: [], averageRating: 0, totalReviews: 0);

  final List<ProductReview> items;
  final double averageRating;
  final int totalReviews;
}
