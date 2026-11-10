import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plant_flower_mobile/core/location/location_service.dart';
import 'package:plant_flower_mobile/features/checkout/data/vietnam_administrative_service.dart';
import 'package:plant_flower_mobile/features/checkout/models/checkout_flow_models.dart';
import 'package:plant_flower_mobile/features/checkout/screens/edit_address_screen.dart';

const _address = CheckoutAddress(
  id: 'address-1',
  label: 'Nhà riêng',
  recipientName: 'Minh Anh',
  phone: '0901234567',
  addressLine: '15 Nguyễn Thiện Thuật',
  ward: 'Phường 2',
  district: 'Quận 3',
  city: 'TP. Hồ Chí Minh',
);

class _FakeLocationService extends LocationService {
  const _FakeLocationService({this.coordinates, this.failure});

  final LocationCoordinates? coordinates;
  final LocationFailure? failure;

  @override
  bool get supportsSettings => false;

  @override
  Future<LocationCoordinates> getCurrentCoordinates() async {
    if (failure case final value?) throw LocationException(value);
    return coordinates!;
  }
}

http.Response _jsonResponse(String body) {
  return http.Response(
    body,
    200,
    headers: const <String, String>{
      'content-type': 'application/json; charset=utf-8',
    },
  );
}

VietnamAdministrativeService _fakeAdministrativeService() {
  return VietnamAdministrativeService(
    client: MockClient((request) async {
      if (request.url.path.endsWith('/p/')) {
        return _jsonResponse(
          '[{"code":79,"name":"Thành phố Hồ Chí Minh"},'
          '{"code":1,"name":"Thành phố Hà Nội"}]',
        );
      }
      if (request.url.path.endsWith('/p/79')) {
        return _jsonResponse(
          '{"code":79,"districts":['
          '{"code":760,"name":"Quận 1"},'
          '{"code":770,"name":"Quận 3"},'
          '{"code":777,"name":"Quận Bình Tân"}]}',
        );
      }
      if (request.url.path.endsWith('/d/770')) {
        return _jsonResponse(
          '{"code":770,"wards":['
          '{"code":27142,"name":"Phường 2"},'
          '{"code":27139,"name":"Phường Võ Thị Sáu"}]}',
        );
      }
      if (request.url.path.endsWith('/d/777')) {
        return _jsonResponse(
          '{"code":777,"wards":['
          '{"code":27436,"name":"Phường Bình Hưng Hòa"}]}',
        );
      }
      return _jsonResponse('{"wards":[]}');
    }),
  );
}

Future<void> _openEditor(
  WidgetTester tester, {
  required LocationService service,
  required ValueChanged<CheckoutAddress> onSaved,
  VietnamAdministrativeService? administrativeService,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<CheckoutAddress>(
                MaterialPageRoute<CheckoutAddress>(
                  builder: (_) => EditAddressScreen(
                    address: _address,
                    locationService: service,
                    administrativeService:
                        administrativeService ?? _fakeAdministrativeService(),
                  ),
                ),
              );
              if (result != null) onSaved(result);
            },
            child: const Text('Mở chỉnh sửa'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Mở chỉnh sửa'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tải đầy đủ quận/huyện và phường/xã từ API', (tester) async {
    await _openEditor(
      tester,
      service: const _FakeLocationService(
        coordinates: LocationCoordinates(
          latitude: 10.7756,
          longitude: 106.7004,
          accuracy: 12,
        ),
      ),
      onSaved: (_) {},
    );

    final dropdowns = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(dropdowns.at(1));
    await tester.pumpAndSettle();
    await tester.tap(dropdowns.at(1));
    await tester.pumpAndSettle();
    expect(find.text('Quận Bình Tân'), findsOneWidget);

    await tester.tap(find.text('Quận Bình Tân'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(dropdowns.at(2));
    await tester.pumpAndSettle();
    await tester.tap(dropdowns.at(2));
    await tester.pumpAndSettle();
    expect(find.text('Phường Bình Hưng Hòa'), findsOneWidget);
  });

  testWidgets('Dùng vị trí hiện tại lưu GPS nhưng giữ nguyên địa chỉ chữ', (
    tester,
  ) async {
    CheckoutAddress? saved;
    await _openEditor(
      tester,
      service: const _FakeLocationService(
        coordinates: LocationCoordinates(
          latitude: 10.7756,
          longitude: 106.7004,
          accuracy: 12,
        ),
      ),
      onSaved: (value) => saved = value,
    );

    await tester.tap(find.text('Dùng vị trí hiện tại'));
    await tester.pump();

    expect(find.text('Đã ghi nhận vị trí hiện tại của bạn.'), findsOneWidget);
    expect(find.text('Cập nhật'), findsOneWidget);

    await tester.ensureVisible(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();

    expect(saved?.latitude, 10.7756);
    expect(saved?.longitude, 106.7004);
    expect(saved?.fullAddress, _address.fullAddress);
  });

  testWidgets('từ chối quyền hiển thị lỗi và không đóng form', (tester) async {
    CheckoutAddress? saved;
    await _openEditor(
      tester,
      service: const _FakeLocationService(failure: LocationFailure.denied),
      onSaved: (value) => saved = value,
    );

    await tester.tap(find.text('Dùng vị trí hiện tại'));
    await tester.pump();

    expect(find.text('Bạn chưa cấp quyền truy cập vị trí.'), findsOneWidget);
    expect(find.byType(EditAddressScreen), findsOneWidget);
    expect(saved, isNull);
  });
}
