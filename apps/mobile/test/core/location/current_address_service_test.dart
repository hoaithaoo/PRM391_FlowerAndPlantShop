import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:plant_flower_mobile/core/location/current_address_service.dart';
import 'package:plant_flower_mobile/core/location/location_service.dart';

class _TestLocation extends LocationService {
  const _TestLocation({this.failure});

  final LocationFailure? failure;

  @override
  Future<LocationCoordinates> getCurrentCoordinates() async {
    if (failure case final value?) throw LocationException(value);
    return const LocationCoordinates(
        latitude: 10.77, longitude: 106.69, accuracy: 20);
  }
}

void main() {
  test('đổi toạ độ thành địa chỉ có tiếng Việt, loại phần địa chỉ lặp',
      () async {
    final service = CurrentAddressService(
      locationService: const _TestLocation(),
      lookup: (latitude, longitude) async {
        expect(latitude, 10.77);
        expect(longitude, 106.69);
        return const [
          Placemark(
            street: '123 Lê Lợi',
            subLocality: 'Phường Bến Thành',
            locality: 'Thành phố Hồ Chí Minh',
            administrativeArea: 'Thành phố Hồ Chí Minh',
            country: 'Việt Nam',
          )
        ];
      },
    );
    expect(await service.getCurrentAddress(),
        '123 Lê Lợi, Phường Bến Thành, Thành phố Hồ Chí Minh, Việt Nam');
  });

  test('quyền bị từ chối thì không gọi dịch vụ đổi địa chỉ', () async {
    var lookupCalls = 0;
    final service = CurrentAddressService(
      locationService: const _TestLocation(failure: LocationFailure.denied),
      lookup: (_, _) async {
        lookupCalls++;
        return [];
      },
    );
    await expectLater(
        service.getCurrentAddress(), throwsA(isA<LocationException>()));
    expect(lookupCalls, 0);
  });

  test(
      'không có địa chỉ hoặc dữ liệu địa chỉ rỗng thì báo lỗi, không dùng toạ độ thay địa chỉ',
      () async {
    for (final result in [
      <Placemark>[],
      const [Placemark()],
      const [Placemark(administrativeArea: 'Hồ Chí Minh', country: 'Việt Nam')],
    ]) {
      final service = CurrentAddressService(
        locationService: const _TestLocation(),
        lookup: (_, _) async => result,
      );
      await expectLater(
          service.getCurrentAddress(), throwsA(isA<AddressLookupException>()));
    }
  });

  test('dịch vụ đổi địa chỉ quá thời gian thì cho phép người dùng nhập tay',
      () async {
    final service = CurrentAddressService(
      locationService: const _TestLocation(),
      lookup: (_, _) => Completer<List<Placemark>>().future,
      lookupTimeout: const Duration(milliseconds: 5),
    );
    await expectLater(
        service.getCurrentAddress(), throwsA(isA<AddressLookupException>()));
  });

  test('dùng số nhà và tên đường nếu nền tảng không trả trường street', () {
    expect(
        CurrentAddressService.formatAddress(const Placemark(
          subThoroughfare: '12',
          thoroughfare: 'Đường Hoa',
          locality: 'Đà Lạt',
        )),
        '12 Đường Hoa, Đà Lạt');
  });
}
