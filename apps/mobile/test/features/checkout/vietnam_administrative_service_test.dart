import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plant_flower_mobile/features/checkout/data/vietnam_administrative_service.dart';

void main() {
  test('tải và parse danh sách tỉnh/thành phố', () async {
    final service = VietnamAdministrativeService(
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/p/');
        return http.Response(
          jsonEncode(<Map<String, Object>>[
            <String, Object>{'code': 79, 'name': 'Thành phố Hồ Chí Minh'},
            <String, Object>{'code': 1, 'name': 'Thành phố Hà Nội'},
          ]),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }),
    );

    final provinces = await service.listProvinces();

    expect(provinces, hasLength(2));
    expect(provinces.first.code, 79);
    expect(provinces.first.name, 'Thành phố Hồ Chí Minh');
  });

  test('tải quận/huyện và phường/xã đúng endpoint theo mã', () async {
    final requests = <Uri>[];
    final service = VietnamAdministrativeService(
      client: MockClient((request) async {
        requests.add(request.url);
        if (request.url.path.endsWith('/p/79')) {
          return http.Response(
            jsonEncode(<String, Object>{
              'code': 79,
              'name': 'Thành phố Hồ Chí Minh',
              'districts': <Map<String, Object>>[
                <String, Object>{'code': 760, 'name': 'Quận 1'},
                <String, Object>{'code': 777, 'name': 'Quận Bình Tân'},
              ],
            }),
            200,
            headers: <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
          );
        }
        return http.Response(
          jsonEncode(<String, Object>{
            'code': 777,
            'name': 'Quận Bình Tân',
            'wards': <Map<String, Object>>[
              <String, Object>{'code': 27436, 'name': 'Phường Bình Hưng Hòa'},
            ],
          }),
          200,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        );
      }),
    );

    final districts = await service.listDistricts(79);
    final wards = await service.listWards(777);

    expect(districts.map((item) => item.name), contains('Quận Bình Tân'));
    expect(wards.single.name, 'Phường Bình Hưng Hòa');
    expect(requests[0].queryParameters['depth'], '2');
    expect(requests[1].queryParameters['depth'], '2');
  });

  test('lỗi HTTP không chuyển sang dữ liệu mẫu', () async {
    final service = VietnamAdministrativeService(
      client: MockClient((_) async => http.Response('Unavailable', 503)),
    );

    await expectLater(
      service.listProvinces(),
      throwsA(isA<AdministrativeLocationException>()),
    );
  });
}
