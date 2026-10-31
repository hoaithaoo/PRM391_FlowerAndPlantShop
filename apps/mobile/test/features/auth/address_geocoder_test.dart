import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';

void main() {
  const address =
      '44/16/44, Phạm Văn Chiêu, phường 8, quận Gò Vấp, Thành phố Hồ Chí Minh';

  NominatimAddressGeocoder geocoderWith(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    return NominatimAddressGeocoder(
      client: MockClient(handler),
      timeout: const Duration(milliseconds: 200),
      retryDelay: Duration.zero,
    );
  }

  group('NominatimAddressGeocoder.geocode', () {
    test('trả toạ độ từ kết quả đầu tiên và gửi đúng query', () async {
      final requests = <http.Request>[];
      final geocoder = geocoderWith((request) async {
        requests.add(request);
        return http.Response(
          '[{"lat": "10.8421", "lon": "106.6463"}]',
          200,
        );
      });

      final point = await geocoder.geocode('  $address  ');

      expect(point, isNotNull);
      expect(point!.latitude, 10.8421);
      expect(point.longitude, 106.6463);
      expect(requests, hasLength(1));
      final uri = requests.single.url;
      expect(uri.host, 'nominatim.openstreetmap.org');
      expect(uri.queryParameters['q'], address);
      expect(uri.queryParameters['countrycodes'], 'vn');
      expect(uri.queryParameters['limit'], '1');
      expect(requests.single.headers['User-Agent'], isNotEmpty);
    });

    test('không thấy địa chỉ đầy đủ thì thử lại không có số nhà', () async {
      final queries = <String?>[];
      final geocoder = geocoderWith((request) async {
        queries.add(request.url.queryParameters['q']);
        if (queries.length == 1) return http.Response('[]', 200);
        return http.Response('[{"lat": "10.84", "lon": "106.64"}]', 200);
      });

      final point = await geocoder.geocode(address);

      expect(point?.latitude, 10.84);
      expect(queries, [
        address,
        'Phạm Văn Chiêu, phường 8, quận Gò Vấp, Thành phố Hồ Chí Minh',
      ]);
    });

    test('cả hai lần đều không thấy thì trả null', () async {
      var calls = 0;
      final geocoder = geocoderWith((_) async {
        calls++;
        return http.Response('[]', 200);
      });

      expect(await geocoder.geocode(address), isNull);
      expect(calls, 2);
    });

    test('địa chỉ ngắn không có phần để bỏ thì chỉ gọi một lần', () async {
      var calls = 0;
      final geocoder = geocoderWith((_) async {
        calls++;
        return http.Response('[]', 200);
      });

      expect(await geocoder.geocode('Gò Vấp, Hồ Chí Minh'), isNull);
      expect(calls, 1);
    });

    test('địa chỉ rỗng thì không gọi mạng', () async {
      var calls = 0;
      final geocoder = geocoderWith((_) async {
        calls++;
        return http.Response('[]', 200);
      });

      expect(await geocoder.geocode('   '), isNull);
      expect(calls, 0);
    });

    test('lỗi HTTP, JSON hỏng, toạ độ sai hay timeout đều trả null', () async {
      final responses = <Future<http.Response> Function()>[
        () async => http.Response('server error', 500),
        () async => http.Response('not json', 200),
        () async => http.Response('{"lat": "1"}', 200),
        () async => http.Response('[{"lat": "abc", "lon": "106"}]', 200),
        () async => http.Response('[{"lat": "95", "lon": "106"}]', 200),
        () async => throw http.ClientException('mất mạng'),
        () => Completer<http.Response>().future,
      ];
      for (final respond in responses) {
        final geocoder = geocoderWith((_) => respond());
        expect(await geocoder.geocode('Gò Vấp, Hồ Chí Minh'), isNull);
      }
    });
  });

  group('NominatimAddressGeocoder.withoutHouseNumber', () {
    test('bỏ đoạn đầu khi còn ít nhất 2 đoạn', () {
      expect(
        NominatimAddressGeocoder.withoutHouseNumber('12, Lê Lợi, Quận 1'),
        'Lê Lợi, Quận 1',
      );
    });

    test('trả null khi quá ngắn', () {
      expect(NominatimAddressGeocoder.withoutHouseNumber('Lê Lợi'), isNull);
      expect(
        NominatimAddressGeocoder.withoutHouseNumber('Lê Lợi, Quận 1'),
        isNull,
      );
    });
  });

  group('SupabaseAuthRepository.signUpMetadata', () {
    const request = RegisterRequest(
      fullName: '  Lê Nam ',
      phone: ' +84387684135 ',
      email: 'nam@example.com',
      address: ' 44/16/44, Phạm Văn Chiêu ',
      password: 'secret123',
    );

    test('gửi kèm lat/lng khi geocode được', () {
      final data = SupabaseAuthRepository.signUpMetadata(
        request,
        const GeoPoint(10.8421, 106.6463),
      );

      expect(data, {
        'full_name': 'Lê Nam',
        'phone': '+84387684135',
        'address': '44/16/44, Phạm Văn Chiêu',
        'latitude': 10.8421,
        'longitude': 106.6463,
      });
    });

    test('lat/lng là null khi không geocode được', () {
      final data = SupabaseAuthRepository.signUpMetadata(request, null);

      expect(data['latitude'], isNull);
      expect(data['longitude'], isNull);
      expect(data.containsKey('latitude'), isTrue);
    });
  });
}
