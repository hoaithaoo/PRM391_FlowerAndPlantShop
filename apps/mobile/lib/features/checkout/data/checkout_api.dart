import 'package:plant_flower_api_client/plant_flower_api_client.dart';

import '../models/checkout_flow_models.dart';
import 'checkout_failure.dart';
import 'checkout_remote_data_source.dart';

enum CheckoutPaymentStatus { pending, paid, failed, expired, review }

class CheckoutPaymentStatusResult {
  const CheckoutPaymentStatusResult({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.status,
    this.paymentCode,
    this.paidAt,
  });

  final String id;
  final String invoiceId;
  final num amount;
  final CheckoutPaymentStatus status;
  final String? paymentCode;
  final DateTime? paidAt;

  factory CheckoutPaymentStatusResult.fromJson(Map<String, dynamic> json) {
    final rawStatus = _requiredString(json, 'status').toUpperCase();
    final status = switch (rawStatus) {
      'PENDING' => CheckoutPaymentStatus.pending,
      'PAID' => CheckoutPaymentStatus.paid,
      'FAILED' => CheckoutPaymentStatus.failed,
      'EXPIRED' => CheckoutPaymentStatus.expired,
      'REVIEW' => CheckoutPaymentStatus.review,
      _ => throw const FormatException('Payment status invalid'),
    };
    return CheckoutPaymentStatusResult(
      id: _requiredString(json, 'id'),
      invoiceId: _requiredString(json, 'invoiceId'),
      amount: _requiredNumber(json, 'amount'),
      status: status,
      paymentCode: _optionalString(json['paymentCode']),
      paidAt: DateTime.tryParse(json['paidAt']?.toString() ?? ''),
    );
  }
}

class CheckoutUserProfile {
  const CheckoutUserProfile({this.fullName, this.phone});

  final String? fullName;
  final String? phone;
}

class ShippingEstimate {
  const ShippingEstimate({
    required this.shippingFee,
    required this.estimatedDeliveryMinutes,
  });

  final int shippingFee;
  final int estimatedDeliveryMinutes;
}

/// Adapter nhỏ dùng chung [ApiClient] cho các endpoint phụ trợ của checkout.
/// Luồng submit chính vẫn đi qua CheckoutRemoteDataSource/CheckoutRepositoryImpl.
class CheckoutApi implements CheckoutApiTransport {
  const CheckoutApi(
    this._client, {
    required CheckoutAccessTokenProvider accessTokenProvider,
  }) : _accessTokenProvider = accessTokenProvider;

  final ApiClient _client;
  final CheckoutAccessTokenProvider _accessTokenProvider;

  @override
  Future<CheckoutApiResponse> post({
    required String path,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _client.post(path, headers: headers, body: body);
      return CheckoutApiResponse(
        statusCode: response.statusCode,
        body: {'data': response.data},
      );
    } on ApiException catch (error) {
      if (error.isNetworkError) rethrow;
      return CheckoutApiResponse(
        statusCode: error.statusCode,
        body: {
          'error': {'code': error.code, 'message': error.message},
        },
      );
    }
  }

  Future<CheckoutUserProfile> getProfile() async {
    final response = await _authenticated(
      (headers) => _client.get('api/v1/profile', headers: headers),
    );
    final data = _requiredMap(response.data);
    return CheckoutUserProfile(
      fullName: _optionalString(data['fullName']),
      phone: _optionalString(data['phone']),
    );
  }

  Future<List<CheckoutAddress>> listAddresses() async {
    final response = await _authenticated(
      (headers) => _client.get('api/v1/user-addresses', headers: headers),
    );
    final data = _requiredMap(response.data);
    final items = data['items'];
    if (items is! List) throw const FormatException('Address list invalid');
    return [
      for (final item in items)
        _addressFromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  Future<CheckoutAddress> createAddress(CheckoutAddress address) async {
    final response = await _authenticated(
      (headers) => _client.post(
        'api/v1/user-addresses',
        headers: headers,
        body: _addressBody(address),
      ),
    );
    return _addressFromJson(_requiredMap(response.data));
  }

  Future<CheckoutAddress> updateAddress(CheckoutAddress address) async {
    final response = await _authenticated(
      (headers) => _client.put(
        'api/v1/user-addresses/${Uri.encodeComponent(address.id)}',
        headers: headers,
        body: _addressBody(address),
      ),
    );
    return _addressFromJson(_requiredMap(response.data));
  }

  Future<void> deleteAddress(String id) async {
    await _authenticated(
      (headers) => _client.delete(
        'api/v1/user-addresses/${Uri.encodeComponent(id)}',
        headers: headers,
      ),
    );
  }

  Future<ShippingEstimate> estimateShipping({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _client.get(
        'api/v1/stores/shipping-estimate',
        query: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        },
      );
      final data = _requiredMap(response.data);
      return ShippingEstimate(
        shippingFee: _requiredNumber(data, 'shippingFee').toInt(),
        estimatedDeliveryMinutes: _requiredNumber(
          data,
          'estimatedDeliveryMinutes',
        ).toInt(),
      );
    } on ApiException catch (error) {
      throw _failureFromApi(error);
    } on FormatException {
      throw const CheckoutFailure(code: CheckoutErrorCode.malformedResponse);
    }
  }

  Future<CheckoutPaymentStatusResult> getPaymentStatus(String paymentId) async {
    final response = await _authenticated(
      (headers) => _client.get(
        'api/v1/payments/${Uri.encodeComponent(paymentId)}/status',
        headers: headers,
      ),
    );
    try {
      return CheckoutPaymentStatusResult.fromJson(_requiredMap(response.data));
    } on FormatException {
      throw const CheckoutFailure(code: CheckoutErrorCode.malformedResponse);
    }
  }

  Future<ApiResponse> _authenticated(
    Future<ApiResponse> Function(Map<String, String> headers) send,
  ) async {
    final token = await _accessTokenProvider();
    if (token == null || token.trim().isEmpty) {
      throw const CheckoutFailure(
        code: CheckoutErrorCode.authTokenMissing,
        statusCode: 401,
        message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      );
    }
    try {
      return await send({'Authorization': 'Bearer ${token.trim()}'});
    } on ApiException catch (error) {
      throw _failureFromApi(error);
    } on FormatException {
      throw const CheckoutFailure(code: CheckoutErrorCode.malformedResponse);
    }
  }

  CheckoutFailure _failureFromApi(ApiException error) {
    if (error.isNetworkError) {
      return CheckoutFailure.network(message: error.message);
    }
    return CheckoutFailure(
      code: error.code,
      statusCode: error.statusCode,
      message: error.message,
    );
  }

  Map<String, dynamic> _addressBody(CheckoutAddress address) => {
    'recipientName': address.recipientName,
    'recipientPhone': address.phone,
    'addressLine': address.fullAddress,
    'label': address.label,
    'deliveryNote': address.driverNote,
    'isDefault': address.isDefault,
    if (address.latitude != null) 'latitude': address.latitude,
    if (address.longitude != null) 'longitude': address.longitude,
  };

  CheckoutAddress _addressFromJson(Map<String, dynamic> json) {
    final fullAddress = _requiredString(json, 'addressLine');
    return CheckoutAddress(
      id: _requiredString(json, 'id'),
      label: _optionalString(json['label']) ?? 'Nhà riêng',
      recipientName: _requiredString(json, 'recipientName'),
      phone: _requiredString(json, 'recipientPhone'),
      addressLine: fullAddress,
      ward: '',
      district: '',
      city: '',
      driverNote: _optionalString(json['deliveryNote']) ?? '',
      isDefault: json['isDefault'] == true,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

Map<String, dynamic> _requiredMap(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const FormatException('Response data invalid');
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('$key invalid');
}

String? _optionalString(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

num _requiredNumber(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value;
  final parsed = num.tryParse(value?.toString() ?? '');
  if (parsed != null) return parsed;
  throw FormatException('$key invalid');
}
