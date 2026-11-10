import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _RecordingAuth extends GoTrueClient {
  _RecordingAuth() : super(autoRefreshToken: false);

  UserAttributes? recorded;

  Map<String, dynamic> get metadata => recorded!.data as Map<String, dynamic>;

  @override
  Future<UserResponse> updateUser(UserAttributes attributes,
      {String? emailRedirectTo}) async {
    recorded = attributes;
    return UserResponse.fromJson({});
  }
}

class _DifferentGeocoder implements AddressGeocoder {
  int calls = 0;

  @override
  Future<GeoPoint?> geocode(String address) async {
    calls++;
    return const GeoPoint(11, 107);
  }
}

void main() {
  late _RecordingAuth auth;
  late _DifferentGeocoder geocoder;
  late SupabaseAuthRepository repository;

  setUp(() {
    auth = _RecordingAuth();
    geocoder = _DifferentGeocoder();
    repository = SupabaseAuthRepository(auth, geocoder: geocoder);
  });
  tearDown(() => auth.dispose());

  test('gửi tọa độ ghim đã xác nhận, không tra lại địa chỉ làm lệch ghim',
      () async {
    await repository.completeProfile(const CompleteProfileRequest(
      fullName: 'Lê Hoa',
      phone: '0912345678',
      address: 'Tầng 3, 123 Đường Hoa',
      latitude: 10.77888,
      longitude: 106.69999,
    ));
    expect(geocoder.calls, 0);
    expect(auth.metadata['latitude'], 10.77888);
    expect(auth.metadata['longitude'], 106.69999);
    expect(auth.metadata['address'], 'Tầng 3, 123 Đường Hoa');
  });

  test('nhập tay vẫn dùng luồng tìm tọa độ từ địa chỉ', () async {
    await repository.completeProfile(const CompleteProfileRequest(
      fullName: 'Lê Hoa',
      phone: '0912345678',
      address: '123 Đường Hoa',
    ));
    expect(geocoder.calls, 1);
    expect(auth.metadata['latitude'], 11);
    expect(auth.metadata['longitude'], 107);
  });

  test('không gửi tọa độ ghim không hợp lệ hoặc thiếu một thành phần',
      () async {
    for (final coordinates in [
      (double.nan, 106.0),
      (91.0, 106.0),
      (10.0, null)
    ]) {
      await repository.completeProfile(CompleteProfileRequest(
        fullName: 'Lê Hoa',
        phone: '0912345678',
        address: '123 Đường Hoa',
        latitude: coordinates.$1,
        longitude: coordinates.$2,
      ));
      expect(auth.metadata['latitude'], 11);
      expect(auth.metadata['longitude'], 107);
    }
    expect(geocoder.calls, 3);
  });
}
