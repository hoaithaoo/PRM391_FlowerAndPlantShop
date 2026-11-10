import '../models/checkout_request.dart';
import 'checkout_failure.dart';

typedef CheckoutAccessTokenProvider = Future<String?> Function();

abstract interface class CheckoutApiTransport {
  Future<CheckoutApiResponse> get({
    required String path,
    required Map<String, String> headers,
    Map<String, String>? query,
  });

  Future<CheckoutApiResponse> post({
    required String path,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  });

  Future<CheckoutApiResponse> put({
    required String path,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  });

  Future<CheckoutApiResponse> patch({
    required String path,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  });
}

class CheckoutApiResponse {
  const CheckoutApiResponse({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, dynamic> body;
}

class CheckoutRemoteDataSource {
  const CheckoutRemoteDataSource({
    required CheckoutApiTransport transport,
    required CheckoutAccessTokenProvider accessTokenProvider,
  }) : _transport = transport,
       _accessTokenProvider = accessTokenProvider;

  static const endpoint = '/api/v1/checkout';
  static const addressesEndpoint = '/api/v1/addresses';
  static const shippingEstimateEndpoint = '/api/v1/stores/shipping-estimate';
  static const storesEndpoint = '/api/v1/stores';
  static const vouchersEndpoint = '/api/v1/vouchers';

  final CheckoutApiTransport _transport;
  final CheckoutAccessTokenProvider _accessTokenProvider;

  Future<Map<String, dynamic>> checkout(
    CheckoutRequest request, {
    required String idempotencyKey,
  }) {
    return _send(
      (headers) => _transport.post(
        path: endpoint,
        headers: <String, String>{
          ...headers,
          'Idempotency-Key': idempotencyKey,
        },
        body: request.toJson(),
      ),
    );
  }

  Future<Map<String, dynamic>> listAddresses() {
    return _send(
      (headers) => _transport.get(path: addressesEndpoint, headers: headers),
    );
  }

  Future<Map<String, dynamic>> createAddress(Map<String, dynamic> body) {
    return _send(
      (headers) => _transport.post(
        path: addressesEndpoint,
        headers: headers,
        body: body,
      ),
    );
  }

  Future<Map<String, dynamic>> updateAddress(
    String id,
    Map<String, dynamic> body,
  ) {
    return _send(
      (headers) => _transport.put(
        path: '$addressesEndpoint/${Uri.encodeComponent(id)}',
        headers: headers,
        body: body,
      ),
    );
  }

  Future<Map<String, dynamic>> estimateShipping({
    required double latitude,
    required double longitude,
  }) {
    return _send(
      (headers) => _transport.get(
        path: shippingEstimateEndpoint,
        headers: headers,
        query: <String, String>{
          'latitude': '$latitude',
          'longitude': '$longitude',
        },
      ),
    );
  }

  Future<Map<String, dynamic>> listStores({
    double? latitude,
    double? longitude,
  }) {
    return _send(
      (headers) => _transport.get(
        path: storesEndpoint,
        headers: headers,
        query: latitude == null || longitude == null
            ? null
            : <String, String>{
                'latitude': '$latitude',
                'longitude': '$longitude',
              },
      ),
    );
  }

  Future<Map<String, dynamic>> getPaymentStatus(String paymentId) {
    return _send(
      (headers) => _transport.get(
        path: '/api/v1/payments/${Uri.encodeComponent(paymentId)}/status',
        headers: headers,
      ),
    );
  }

  Future<void> cancelOrder(String orderId, {String? reason}) async {
    await _send(
      (headers) => _transport.patch(
        path: '/api/v1/orders/${Uri.encodeComponent(orderId)}/cancel',
        headers: headers,
        body: <String, dynamic>{'reason': ?reason},
      ),
    );
  }

  Future<Map<String, dynamic>> availableVouchers({
    num? subtotal,
    num? shippingFee,
  }) {
    return _send(
      (headers) => _transport.get(
        path: '$vouchersEndpoint/available',
        headers: headers,
        query: <String, String>{
          if (subtotal != null) 'subtotal': '${subtotal.round()}',
          if (shippingFee != null) 'shippingFee': '${shippingFee.round()}',
        },
      ),
    );
  }

  Future<Map<String, dynamic>> validateVoucher(
    String code, {
    num? subtotal,
    num? shippingFee,
  }) {
    return _send(
      (headers) => _transport.post(
        path: '$vouchersEndpoint/validate',
        headers: headers,
        body: <String, dynamic>{
          'code': code,
          if (subtotal != null) 'subtotal': subtotal.round(),
          if (shippingFee != null) 'shippingFee': shippingFee.round(),
        },
      ),
    );
  }

  /// Gắn token, đổi lỗi thành [CheckoutFailure] và trả phần `data`.
  /// Thiếu `data` thì trả map rỗng, nơi cần dữ liệu tự báo malformed.
  Future<Map<String, dynamic>> _send(
    Future<CheckoutApiResponse> Function(Map<String, String> headers) request,
  ) async {
    final accessToken = await _accessTokenProvider();
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw const CheckoutFailure(code: CheckoutErrorCode.authTokenInvalid);
    }

    try {
      final response = await request(<String, String>{
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      });

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CheckoutFailure(
          code: _readErrorCode(response.body),
          statusCode: response.statusCode,
          message: _readErrorMessage(response.body),
        );
      }

      final data = response.body['data'];
      return data is Map
          ? Map<String, dynamic>.from(data)
          : const <String, dynamic>{};
    } on CheckoutFailure {
      rethrow;
    } catch (error) {
      throw CheckoutFailure.network(message: error.toString());
    }
  }

  String _readErrorCode(Map<String, dynamic> body) {
    final error = body['error'];
    if (error is Map) {
      final code = error['code'];
      if (code is String && code.isNotEmpty) {
        return code;
      }
    }
    return CheckoutErrorCode.network;
  }

  String? _readErrorMessage(Map<String, dynamic> body) {
    final error = body['error'];
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    return null;
  }
}
