import 'dart:typed_data';

import 'package:plant_flower_shared/plant_flower_shared.dart' show ProductReview;

import '../models/profile_models.dart';
import 'profile_repository.dart';

/// Chạy demo khi chưa cấu hình backend.
class MockProfileRepository implements ProfileRepository {
  UserProfile _profile = const UserProfile(
    id: 'demo',
    email: 'demo@nhacohoa.vn',
    fullName: 'Nguyễn Minh Anh',
    phone: '0901234567',
  );

  @override
  Future<UserProfile> getProfile() async => _profile;

  @override
  Future<UserProfile> updateProfile({
    required String fullName,
    required String phone,
  }) async => _profile = UserProfile(
    id: _profile.id,
    email: _profile.email,
    fullName: fullName,
    phone: phone,
    avatarUrl: _profile.avatarUrl,
  );

  @override
  Future<UserProfile> uploadAvatar(Uint8List bytes, String contentType) async =>
      _profile;

  @override
  Future<OrderPage> listOrders({int page = 1}) async =>
      const OrderPage(items: <OrderSummary>[], hasMore: false);

  @override
  Future<Map<String, int>> orderCounts(List<String> statuses) async =>
      <String, int>{for (final status in statuses) status: 0};

  @override
  Future<OrderDetail> getOrder(String id) =>
      Future.error(StateError('Không có đơn hàng demo.'));

  @override
  Future<void> cancelOrder(String id) async {}

  final _incidents = <IncidentReport>[];

  @override
  Future<IncidentReport> createIncident({
    required String category,
    required String title,
    required String description,
    String? orderId,
  }) async {
    final report = IncidentReport(
      id: 'demo-${_incidents.length}',
      code: 'SC-DEMO-${_incidents.length + 1}',
      category: category,
      title: title,
      description: description,
      status: 'OPEN',
      createdAt: DateTime.now(),
    );
    _incidents.insert(0, report);
    return report;
  }

  @override
  Future<List<IncidentReport>> listIncidents() async =>
      List.unmodifiable(_incidents);

  final _reviews = <ProductReview>[];

  @override
  Future<List<ProductReview>> listMyReviews(String orderId) async =>
      _reviews.where((r) => r.orderId == orderId).toList(growable: false);

  @override
  Future<ProductReview> createReview({
    required String orderId,
    required String productId,
    required int rating,
    String? comment,
    List<String> imageUrls = const [],
  }) async {
    final review = ProductReview(
      id: 'demo-review-${_reviews.length}',
      rating: rating,
      comment: comment,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
      orderId: orderId,
      productId: productId,
    );
    _reviews.add(review);
    return review;
  }

  @override
  Future<String> uploadReviewImage(Uint8List bytes, String contentType) async =>
      'https://picsum.photos/seed/${bytes.length}/300';
}
