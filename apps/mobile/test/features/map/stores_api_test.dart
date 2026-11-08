import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/checkout/data/checkout_failure.dart';
import 'package:plant_flower_mobile/features/checkout/data/checkout_remote_data_source.dart';
import 'package:plant_flower_mobile/features/checkout/data/checkout_repository_impl.dart';

class _FakeTransport implements CheckoutApiTransport {
  CheckoutApiResponse response = const CheckoutApiResponse(
    statusCode: 200,
    body: <String, dynamic>{
      'data': <String, dynamic>{'items': <Object>[]},
    },
  );
  Object? error;
  String? path;
  Map<String, String>? query;

  @override
  Future<CheckoutApiResponse> get({
    required String path,
    required Map<String, String> headers,
    Map<String, String>? query,
  }) async {
    this.path = path;
    this.query = query;
    if (error case final value?) throw value;
    return response;
  }

  @override
  Future<CheckoutApiResponse> patch({
    required String path,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) => throw UnimplementedError();

  @override
  Future<CheckoutApiResponse> post({
    required String path,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) => throw UnimplementedError();

  @override
  Future<CheckoutApiResponse> put({
    required String path,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) => throw UnimplementedError();
}

CheckoutRepositoryImpl _repository(_FakeTransport transport) {
  return CheckoutRepositoryImpl(
    CheckoutRemoteDataSource(
      transport: transport,
      accessTokenProvider: () async => 'token-test',
    ),
  );
}

void main() {
  test('GET stores không gửi query khi chưa có GPS', () async {
    final transport = _FakeTransport();

    await _repository(transport).listStores();

    expect(transport.path, '/api/v1/stores');
    expect(transport.query, isNull);
  });

  test('GET stores gửi latitude và longitude cùng nhau', () async {
    final transport = _FakeTransport();

    await _repository(
      transport,
    ).listStores(latitude: 10.77, longitude: 106.68);

    expect(transport.query, <String, String>{
      'latitude': '10.77',
      'longitude': '106.68',
    });
  });

  test('parse response thật và các field nullable an toàn', () async {
    final transport = _FakeTransport()
      ..response = const CheckoutApiResponse(
        statusCode: 200,
        body: <String, dynamic>{
          'data': <String, dynamic>{
            'items': <Object>[
              <String, dynamic>{
                'id': 'store-1',
                'name': 'Nhà Có Hoa Quận 1',
                'address': '10 Nguyễn Huệ',
                'latitude': 10.7756,
                'longitude': 106.7004,
                'phone': '0901234567',
                'openingHours': '08:00 - 21:00',
                'distanceKm': 2.4,
                'shippingFee': 30000,
                'estimatedDeliveryMinutes': 35,
              },
              <String, dynamic>{
                'id': 'store-2',
                'name': 'Nhà Có Hoa Thủ Đức',
                'address': '12 Võ Văn Ngân',
                'latitude': null,
                'longitude': null,
                'phone': null,
                'openingHours': null,
                'distanceKm': null,
              },
            ],
          },
        },
      );

    final stores = await _repository(transport).listStores();

    expect(stores, hasLength(2));
    expect(stores.first.hasValidCoordinates, isTrue);
    expect(stores.first.distanceKm, 2.4);
    expect(stores.last.hasValidCoordinates, isFalse);
    expect(stores.last.phone, isNull);
    expect(stores.last.distanceKm, isNull);
  });

  test('response thiếu items được đổi thành malformed response', () async {
    final transport = _FakeTransport()
      ..response = const CheckoutApiResponse(
        statusCode: 200,
        body: <String, dynamic>{'data': <String, dynamic>{}},
      );

    await expectLater(
      _repository(transport).listStores(),
      throwsA(
        isA<CheckoutFailure>().having(
          (error) => error.code,
          'code',
          CheckoutErrorCode.malformedResponse,
        ),
      ),
    );
  });

  test('timeout mạng được đổi thành CheckoutFailure', () async {
    final transport = _FakeTransport()
      ..error = TimeoutException('timeout');

    await expectLater(
      _repository(transport).listStores(),
      throwsA(
        isA<CheckoutFailure>().having(
          (error) => error.code,
          'code',
          CheckoutErrorCode.network,
        ),
      ),
    );
  });
}
