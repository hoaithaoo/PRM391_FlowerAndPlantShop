import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/core/location/location_service.dart';
import 'package:plant_flower_mobile/features/checkout/data/mock_checkout_repository.dart';
import 'package:plant_flower_mobile/features/checkout/models/checkout_flow_models.dart';
import 'package:plant_flower_mobile/features/map/screens/store_map_screen.dart';

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

class _StoreRepository extends MockCheckoutRepository {
  _StoreRepository();

  final requests = <(double?, double?)>[];

  @override
  Future<List<PickupBranch>> listStores({
    double? latitude,
    double? longitude,
  }) async {
    requests.add((latitude, longitude));
    return const <PickupBranch>[_store];
  }
}

class _MapLocationService extends LocationService {
  const _MapLocationService({this.failure});

  final LocationFailure? failure;

  @override
  bool get supportsSettings => false;

  @override
  Future<LocationCoordinates> getCurrentCoordinates() async {
    if (failure case final value?) throw LocationException(value);
    return const LocationCoordinates(
      latitude: 10.77,
      longitude: 106.68,
      accuracy: 15,
    );
  }
}

void main() {
  testWidgets('mở Map, tải marker và chọn cửa hàng', (tester) async {
    final repository = _StoreRepository();
    await tester.pumpWidget(
      MaterialApp(home: StoreMapScreen(repository: repository)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Vị trí cửa hàng'), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Nhà Có Hoa Quận 1'), findsOneWidget);
    expect(repository.requests, <(double?, double?)>[(null, null)]);

    await tester.tap(find.text('Nhà Có Hoa Quận 1'));
    await tester.pump();
    expect(find.text('0901234567'), findsOneWidget);
  });

  testWidgets('Chỉ đường dùng tọa độ thật của cửa hàng', (tester) async {
    Uri? openedUrl;
    await tester.pumpWidget(
      MaterialApp(
        home: StoreMapScreen(
          repository: _StoreRepository(),
          urlLauncher: (url) async {
            openedUrl = url;
            return true;
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Nhà Có Hoa Quận 1'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('store-map-directions')));
    await tester.pump();

    expect(openedUrl?.host, 'www.google.com');
    expect(openedUrl?.path, '/maps/dir/');
    expect(openedUrl?.queryParameters['api'], '1');
    expect(
      openedUrl?.queryParameters['destination'],
      '${_store.latitude},${_store.longitude}',
    );
  });

  testWidgets('GPS chỉ chạy khi bấm và tải lại stores bằng tọa độ thật', (
    tester,
  ) async {
    final repository = _StoreRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: StoreMapScreen(
          repository: repository,
          locationService: const _MapLocationService(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(repository.requests, <(double?, double?)>[(null, null)]);
    await tester.tap(find.byKey(const Key('store-map-my-location')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(repository.requests.last, (10.77, 106.68));
  });

  testWidgets('từ chối GPS vẫn giữ danh sách cửa hàng', (tester) async {
    final repository = _StoreRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: StoreMapScreen(
          repository: repository,
          locationService: const _MapLocationService(
            failure: LocationFailure.denied,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('store-map-my-location')));
    await tester.pump();

    expect(find.text('Bạn chưa cấp quyền truy cập vị trí.'), findsWidgets);
    expect(find.text('Nhà Có Hoa Quận 1'), findsOneWidget);
  });

  testWidgets('không overflow trên màn 360x800 khi hiện lỗi vị trí', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: StoreMapScreen(
          repository: _StoreRepository(),
          locationService: const _MapLocationService(
            failure: LocationFailure.serviceDisabled,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('store-map-my-location')));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
