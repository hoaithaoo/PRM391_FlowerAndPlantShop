import 'dart:typed_data';

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
  Future<OrderDetail> getOrder(String id) =>
      Future.error(StateError('Không có đơn hàng demo.'));

  @override
  Future<void> cancelOrder(String id) async {}
}
