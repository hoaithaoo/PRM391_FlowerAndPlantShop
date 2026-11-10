import 'package:plant_flower_shared/plant_flower_shared.dart';

/// Kết quả danh sách đánh giá cho admin, kèm thống kê theo bộ lọc.
class AdminReviewList {
  const AdminReviewList({
    required this.items,
    required this.total,
    required this.averageRating,
    required this.visibleReviews,
    this.page = 1,
    this.totalPages = 1,
  });

  final List<ProductReview> items;
  final int total;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;

  /// Điểm trung bình của các đánh giá đang hiện (khớp bộ lọc).
  final double averageRating;
  final int visibleReviews;
}

abstract class AdminReviewsService {
  /// [hidden] null = tất cả, true = chỉ đánh giá bị ẩn, false = chỉ đang hiện.
  Future<AdminReviewList> getReviews({
    int? rating,
    bool? hidden,
    String? search,
    int page = 1,
  });

  Future<ProductReview> setReviewHidden(String id, bool isHidden);
}
