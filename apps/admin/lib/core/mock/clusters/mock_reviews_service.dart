import 'package:plant_flower_shared/plant_flower_shared.dart';
import '../../services/contracts/admin_reviews_service.dart';

class MockReviewsService implements AdminReviewsService {
  final List<ProductReview> _items = [
    ProductReview(
      id: 'rev_001',
      rating: 5,
      comment: 'Hoa tươi, gói đẹp, giao đúng giờ.',
      imageUrls: const ['https://picsum.photos/seed/rev1/300'],
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      authorName: 'Nguyễn Phương Hà',
      authorEmail: 'phuongha@gmail.com',
      productName: 'Bó hồng đỏ Ecuador',
      orderNumber: 'NCH-2026-001',
    ),
    ProductReview(
      id: 'rev_002',
      rating: 2,
      comment: 'Cây hơi héo lá khi nhận.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      authorName: 'Trần Minh Khoa',
      authorEmail: 'khoa@gmail.com',
      productName: 'Sen đá mix chậu sứ',
      orderNumber: 'NCH-2026-002',
      isHidden: true,
    ),
  ];

  @override
  Future<AdminReviewList> getReviews({
    int? rating,
    bool? hidden,
    String? search,
    int page = 1,
  }) async {
    final query = search?.toLowerCase() ?? '';
    final items = _items
        .where((e) => rating == null || e.rating == rating)
        .where((e) => hidden == null || e.isHidden == hidden)
        .where((e) =>
            query.isEmpty ||
            (e.comment ?? '').toLowerCase().contains(query) ||
            (e.productName ?? '').toLowerCase().contains(query))
        .toList();
    final visible = items.where((e) => !e.isHidden).toList();
    return AdminReviewList(
      items: items,
      total: items.length,
      averageRating: visible.isEmpty
          ? 0
          : visible.map((e) => e.rating).reduce((a, b) => a + b) /
              visible.length,
      visibleReviews: visible.length,
    );
  }

  @override
  Future<ProductReview> setReviewHidden(String id, bool isHidden) async {
    final index = _items.indexWhere((e) => e.id == id);
    final old = _items[index];
    final updated = ProductReview(
      id: old.id,
      rating: old.rating,
      comment: old.comment,
      imageUrls: old.imageUrls,
      createdAt: old.createdAt,
      authorName: old.authorName,
      authorEmail: old.authorEmail,
      productName: old.productName,
      orderNumber: old.orderNumber,
      isHidden: isHidden,
    );
    _items[index] = updated;
    return updated;
  }
}
