import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_api_client/plant_flower_api_client.dart';
import 'package:plant_flower_mobile/features/auth/data/address_geocoder.dart';
import 'package:plant_flower_mobile/features/auth/data/auth_failure.dart';
import 'package:plant_flower_mobile/features/auth/models/auth_models.dart';
import 'package:plant_flower_mobile/features/checkout/data/checkout_repository.dart';
import 'package:plant_flower_mobile/features/checkout/models/checkout_flow_models.dart';
import 'package:plant_flower_mobile/features/profile/data/profile_backend_sync.dart';
import 'package:plant_flower_mobile/features/profile/data/profile_repository.dart';
import 'package:plant_flower_mobile/features/profile/models/profile_models.dart';

class _Profiles implements ProfileRepository {
  final updates = <(String, String)>[];
  Object? error;

  @override
  Future<UserProfile> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    if (error != null) throw error!;
    updates.add((fullName, phone));
    return UserProfile(id: 'u1', fullName: fullName, phone: phone);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Addresses implements CheckoutRepository {
  final saved = <CheckoutAddress>[];

  @override
  Future<List<CheckoutAddress>> listAddresses() async => List.of(saved);

  @override
  Future<CheckoutAddress> saveAddress(CheckoutAddress address) async {
    saved.add(address);
    return address;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const request = CompleteProfileRequest(
    fullName: '  Phạm Hoàng Định ',
    phone: '0912 345 678',
    address: 'Tầng 3, 123 Đường Hoa, TP. Hồ Chí Minh',
  );

  test('ghi hồ sơ và thêm địa chỉ mặc định kèm toạ độ', () async {
    final profiles = _Profiles();
    final addresses = _Addresses();
    final sync = ProfileBackendSyncer(
      profileRepository: profiles,
      checkoutRepository: addresses,
    );

    await sync(request, const GeoPoint(10.77, 106.7));

    expect(profiles.updates, [('Phạm Hoàng Định', '0912345678')]);
    final address = addresses.saved.single;
    expect(address.isNew, isTrue);
    expect(address.recipientName, 'Phạm Hoàng Định');
    expect(address.fullAddress, 'Tầng 3, 123 Đường Hoa, TP. Hồ Chí Minh');
    expect(address.isDefault, isTrue);
    expect(address.latitude, 10.77);
    expect(address.longitude, 106.7);
  });

  test('bấm lưu lại không tạo địa chỉ trùng', () async {
    final addresses = _Addresses();
    final sync = ProfileBackendSyncer(
      profileRepository: _Profiles(),
      checkoutRepository: addresses,
    );

    await sync(request, null);
    await sync(request, null);

    expect(addresses.saved, hasLength(1));
  });

  test('lỗi API thành AuthFailure có câu báo của server', () async {
    final profiles = _Profiles()
      ..error = const ApiException(
        statusCode: 400,
        code: 'VALIDATION_ERROR',
        message: 'Số điện thoại không đúng định dạng Việt Nam.',
      );
    final addresses = _Addresses();
    final sync = ProfileBackendSyncer(
      profileRepository: profiles,
      checkoutRepository: addresses,
    );

    await expectLater(
      sync(request, null),
      throwsA(
        isA<AuthFailure>().having(
          (f) => f.message,
          'message',
          contains('Số điện thoại không đúng định dạng'),
        ),
      ),
    );
    expect(addresses.saved, isEmpty);
  });
}
