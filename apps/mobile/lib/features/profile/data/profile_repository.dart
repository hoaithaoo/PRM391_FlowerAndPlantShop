import 'dart:typed_data';

import 'package:plant_flower_api_client/plant_flower_api_client.dart';

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

  Future<OrderDetail> getOrder(String id);

  Future<void> cancelOrder(String id);
}

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(
    this._client, {
    required ProfileAccessTokenProvider accessTokenProvider,
    required AvatarUploader avatarUploader,
  }) : _accessTokenProvider = accessTokenProvider,
       _avatarUploader = avatarUploader;

  static const _profilePath = 'api/v1/profile';
  static const _ordersPath = 'api/v1/orders';

  final ApiClient _client;
  final ProfileAccessTokenProvider _accessTokenProvider;
  final AvatarUploader _avatarUploader;

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
}

/// Câu báo lỗi cho người dùng từ lỗi của [ProfileRepository].
String profileErrorMessage(Object error) => error is ApiException
    ? error.message
    : 'Đã có lỗi xảy ra. Vui lòng thử lại.';
