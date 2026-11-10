import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/core/location/location_service.dart';
import 'package:plant_flower_mobile/features/checkout/data/checkout_failure.dart';
import 'package:plant_flower_mobile/features/checkout/models/checkout_flow_models.dart';
import 'package:plant_flower_mobile/features/map/state/store_map_controller.dart';

const _store = PickupBranch(
  id: 'store-1',
  name: 'Nhà Có Hoa Quận 1',
  address: '10 Nguyễn Huệ, Quận 1',
  distance: '1,2 km',
  readyTime: 'Sẵn sàng',
  openingHours: '08:00 - 21:00',
  imageAsset: '',
  latitude: 10.7756,
  longitude: 106.7004,
  phone: '0901234567',
  distanceKm: 1.2,
);

const _coordinates = LocationCoordinates(
  latitude: 10.77,
  longitude: 106.68,
  accuracy: 12,
);

void main() {
  group('StoreMapController', () {
    test('hiển thị loading rồi danh sách cửa hàng', () async {
      final completer = Completer<List<PickupBranch>>();
      final controller = StoreMapController(
        storeLoader: ({latitude, longitude}) => completer.future,
        currentCoordinatesLoader: () async => _coordinates,
      );

      final loading = controller.initialize();
      expect(controller.status, StoreMapStatus.loading);

      completer.complete(const <PickupBranch>[_store]);
      await loading;

      expect(controller.status, StoreMapStatus.loaded);
      expect(controller.stores, const <PickupBranch>[_store]);
      controller.dispose();
    });

    test('lần tải đầu không gửi tọa độ giả', () async {
      double? sentLatitude;
      double? sentLongitude;
      final controller = StoreMapController(
        storeLoader: ({latitude, longitude}) async {
          sentLatitude = latitude;
          sentLongitude = longitude;
          return const <PickupBranch>[_store];
        },
        currentCoordinatesLoader: () async => _coordinates,
      );

      await controller.initialize();

      expect(sentLatitude, isNull);
      expect(sentLongitude, isNull);
      controller.dispose();
    });

    test('GPS thành công tải lại cửa hàng bằng cả hai tọa độ', () async {
      final requests = <(double?, double?)>[];
      final controller = StoreMapController(
        storeLoader: ({latitude, longitude}) async {
          requests.add((latitude, longitude));
          return const <PickupBranch>[_store];
        },
        currentCoordinatesLoader: () async => _coordinates,
      );

      await controller.initialize();
      final success = await controller.findCurrentLocation();

      expect(success, isTrue);
      expect(controller.userLocation, _coordinates);
      expect(requests, <(double?, double?)>[(null, null), (10.77, 106.68)]);
      controller.dispose();
    });

    for (final failure in <LocationFailure>[
      LocationFailure.serviceDisabled,
      LocationFailure.denied,
      LocationFailure.deniedForever,
      LocationFailure.timeout,
      LocationFailure.unavailable,
    ]) {
      test('giữ bản đồ dùng được khi lỗi vị trí $failure', () async {
        var storeCalls = 0;
        final controller = StoreMapController(
          storeLoader: ({latitude, longitude}) async {
            storeCalls++;
            return const <PickupBranch>[_store];
          },
          currentCoordinatesLoader: () async => throw LocationException(failure),
        );

        await controller.initialize();
        final success = await controller.findCurrentLocation();

        expect(success, isFalse);
        expect(controller.locationFailure, failure);
        expect(controller.stores, const <PickupBranch>[_store]);
        expect(storeCalls, 1);
        controller.dispose();
      });
    }

    test('từ chối tọa độ GPS không hợp lệ', () async {
      final controller = StoreMapController(
        storeLoader: ({latitude, longitude}) async =>
            const <PickupBranch>[_store],
        currentCoordinatesLoader: () async => const LocationCoordinates(
          latitude: 91,
          longitude: 106.68,
          accuracy: 10,
        ),
      );

      await controller.initialize();
      expect(await controller.findCurrentLocation(), isFalse);
      expect(
        controller.locationFailure,
        LocationFailure.invalidCoordinates,
      );
      controller.dispose();
    });

    test('xử lý danh sách rỗng và lỗi API', () async {
      var fail = false;
      final controller = StoreMapController(
        storeLoader: ({latitude, longitude}) async {
          if (fail) throw const CheckoutFailure.network();
          return const <PickupBranch>[];
        },
        currentCoordinatesLoader: () async => _coordinates,
      );

      await controller.initialize();
      expect(controller.status, StoreMapStatus.empty);

      fail = true;
      await controller.refresh();
      expect(controller.status, StoreMapStatus.error);
      expect(controller.storeError, isNotNull);
      controller.dispose();
    });

    test('loại marker trùng ID và chọn cửa hàng', () async {
      final duplicate = PickupBranch.fromJson(<String, dynamic>{
        'id': 'store-1',
        'name': 'Tên mới',
        'address': 'Địa chỉ mới',
        'latitude': '10.8',
        'longitude': '106.7',
      });
      final controller = StoreMapController(
        storeLoader: ({latitude, longitude}) async => <PickupBranch>[
          _store,
          duplicate,
        ],
        currentCoordinatesLoader: () async => _coordinates,
      );

      await controller.initialize();
      expect(controller.stores, hasLength(1));
      expect(controller.stores.single.name, 'Tên mới');

      controller.selectStore(controller.stores.single);
      expect(controller.selectedStore?.id, 'store-1');
      controller.dispose();
    });
  });

  group('PickupBranch map fields', () {
    test('đọc đủ dữ liệu thật từ Stores API', () {
      final store = PickupBranch.fromJson(<String, dynamic>{
        'id': 'store-2',
        'name': 'Nhà Có Hoa Thủ Đức',
        'address': '12 Võ Văn Ngân',
        'latitude': 10.8494,
        'longitude': 106.7537,
        'phone': '0281234567',
        'openingHours': '08:00 - 20:00',
        'distanceKm': 4.25,
        'shippingFee': 30000,
        'estimatedDeliveryMinutes': 45,
      });

      expect(store.hasValidCoordinates, isTrue);
      expect(store.phone, '0281234567');
      expect(store.distanceKm, 4.25);
      expect(store.shippingFee, 30000);
      expect(store.estimatedDeliveryMinutes, 45);
      expect(store.distance, '4,3 km');
    });

    test('không tạo marker cho tọa độ thiếu hoặc ngoài phạm vi', () {
      final missing = PickupBranch.fromJson(<String, dynamic>{
        'id': 'store-3',
        'name': 'Thiếu tọa độ',
        'address': 'TP. Hồ Chí Minh',
      });
      final invalid = PickupBranch.fromJson(<String, dynamic>{
        'id': 'store-4',
        'name': 'Sai tọa độ',
        'address': 'TP. Hồ Chí Minh',
        'latitude': 95,
        'longitude': 106,
      });

      expect(missing.hasValidCoordinates, isFalse);
      expect(missing.distanceKm, isNull);
      expect(invalid.hasValidCoordinates, isFalse);
    });
  });
}
