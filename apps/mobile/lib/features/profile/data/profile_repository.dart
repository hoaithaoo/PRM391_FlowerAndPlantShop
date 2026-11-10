import 'dart:typed_data';

import 'package:plant_flower_api_client/plant_flower_api_client.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart' show ProductReview;

import '../models/profile_models.dart';

typedef ProfileAccessTokenProvider = Future<String?> Function();

/// Tải ảnh lên kho lưu trữ, trả về URL công khai.
typedef AvatarUploader =
    Future<String> Function(Uint8List bytes, String contentType);

abstract interface class ProfileRepository {
  Future<UserProfile> getProfile();

  Future<UserProfile> updateProfile({
    required String fullName,
    required String phone,
  });

  Future<UserProfile> uploadAvatar(Uint8List bytes, String contentType);

  Future<OrderPage> listOrders({int page = 1});

  /// Số đơn theo từng trạng thái trong [statuses].
  Future<Map<String, int>> orderCounts(List<String> statuses);

  Future<OrderDetail> getOrder(String id);

  Future<void> cancelOrder(String id);

  Future<IncidentReport> createIncident({
    required String category,
    required String title,
    required String description,
    String? orderId,
  });

  Future<List<IncidentReport>> listIncidents();

  /// Đánh giá khách đã viết cho các sản phẩm trong đơn [orderId].
  Future<List<ProductReview>> listMyReviews(String orderId);

  Future<ProductReview> createReview({
    required String orderId,
    required String productId,
    required int rating,
    String? comment,
    List<String> imageUrls = const [],
  });

  /// Tải một ảnh đánh giá lên kho, trả về URL công khai.
  Future<String> uploadReviewImage(Uint8List bytes, String contentType);
}

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(
    this._client, {
    required ProfileAccessTokenProvider accessTokenProvider,
    required AvatarUploader avatarUploader,
    required AvatarUploader reviewImageUploader,
  }) : _accessTokenProvider = accessTokenProvider,
       _avatarUploader = avatarUploader,
       _reviewImageUploader = reviewImageUploader;

  static const _profilePath = 'api/v1/profile';
  static const _ordersPath = 'api/v1/orders';
  static const _incidentsPath = 'api/v1/incidents';
  static const _reviewsPath = 'api/v1/reviews';

  final ApiClient _client;
  final ProfileAccessTokenProvider _accessTokenProvider;
  final AvatarUploader _avatarUploader;
  final AvatarUploader _reviewImageUploader;

  Future<Map<String, String>> _headers() async {
    final token = await _accessTokenProvider();
    return <String, String>{'Authorization': 'Bearer ${token ?? ''}'};
  }

  @override
  Future<UserProfile> getProfile() async {
    final response = await _client.get(_profilePath, headers: await _headers());
    return UserProfile.fromJson(response.data! as Map<String, dynamic>);
  }

  Future<UserProfile> _update(Map<String, dynamic> body) async {
    await _client.put(_profilePath, headers: await _headers(), body: body);
    // PUT chỉ trả các field vừa đổi, GET lại để có đủ email.
    return getProfile();
  }

  @override
  Future<UserProfile> updateProfile({
    required String fullName,
    required String phone,
  }) => _update(<String, dynamic>{'fullName': fullName, 'phone': phone});

  @override
  Future<UserProfile> uploadAvatar(Uint8List bytes, String contentType) async {
    final url = await _avatarUploader(bytes, contentType);
    return _update(<String, dynamic>{'avatarUrl': url});
  }

  @override
  Future<OrderPage> listOrders({int page = 1}) async {
    final response = await _client.get(
      _ordersPath,
      headers: await _headers(),
      query: <String, String>{'page': '$page'},
    );
    final data = response.data! as Map<String, dynamic>;
    final totalPages = response.meta['totalPages'] as int? ?? page;
    return OrderPage(
      items: (data['items'] as List<dynamic>)
          .map((item) => OrderSummary.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      hasMore: page < totalPages,
    );
  }

  @override
  Future<Map<String, int>> orderCounts(List<String> statuses) async {
    final headers = await _headers();
    final totals = await Future.wait(
      statuses.map((status) async {
        final response = await _client.get(
          _ordersPath,
          headers: headers,
          query: <String, String>{'status': status, 'limit': '1'},
        );
        return response.meta['total'] as int? ?? 0;
      }),
    );
    return Map<String, int>.fromIterables(statuses, totals);
  }

  @override
  Future<OrderDetail> getOrder(String id) async {
    final response = await _client.get(
      '$_ordersPath/${Uri.encodeComponent(id)}',
      headers: await _headers(),
    );
    return OrderDetail.fromJson(response.data! as Map<String, dynamic>);
  }

  @override
  Future<void> cancelOrder(String id) async {
    await _client.patch(
      '$_ordersPath/${Uri.encodeComponent(id)}/cancel',
      headers: await _headers(),
      body: <String, dynamic>{'reason': 'Khách hủy trong ứng dụng'},
    );
  }

  @override
  Future<IncidentReport> createIncident({
    required String category,
    required String title,
    required String description,
    String? orderId,
  }) async {
    final response = await _client.post(
      _incidentsPath,
      headers: await _headers(),
      body: <String, dynamic>{
        'category': category,
        'title': title,
        'description': description,
        'orderId': ?orderId,
      },
    );
    return IncidentReport.fromJson(response.data! as Map<String, dynamic>);
  }

  @override
  Future<List<IncidentReport>> listIncidents() async {
    // Giới hạn: chỉ lấy 50 phiếu mới nhất, thêm phân trang khi khách có nhiều hơn.
    final response = await _client.get(
      _incidentsPath,
      headers: await _headers(),
      query: <String, String>{'limit': '50'},
    );
    final data = response.data! as Map<String, dynamic>;
    return (data['items'] as List<dynamic>)
        .map((item) => IncidentReport.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<List<ProductReview>> listMyReviews(String orderId) async {
    final response = await _client.get(
      '$_reviewsPath/mine',
      headers: await _headers(),
      query: <String, String>{'orderId': orderId},
    );
    final data = response.data! as Map<String, dynamic>;
    return (data['items'] as List<dynamic>)
        .map((item) => ProductReview.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<ProductReview> createReview({
    required String orderId,
    required String productId,
    required int rating,
    String? comment,
    List<String> imageUrls = const [],
  }) async {
    final response = await _client.post(
      _reviewsPath,
      headers: await _headers(),
      body: <String, dynamic>{
        'orderId': orderId,
        'productId': productId,
        'rating': rating,
        'comment': ?comment,
        'imageUrls': imageUrls,
      },
    );
    return ProductReview.fromJson(response.data! as Map<String, dynamic>);
  }

  @override
  Future<String> uploadReviewImage(Uint8List bytes, String contentType) =>
      _reviewImageUploader(bytes, contentType);
}

/// Câu báo lỗi cho người dùng từ lỗi của [ProfileRepository].
String profileErrorMessage(Object error) => error is ApiException
    ? error.message
    : 'Đã có lỗi xảy ra. Vui lòng thử lại.';
