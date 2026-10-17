import '../models/checkout_request.dart';
import 'checkout_failure.dart';

typedef CheckoutAccessTokenProvider = Future<String?> Function();

abstract interface class CheckoutApiTransport {
  Future<CheckoutApiResponse> post({
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

  final CheckoutApiTransport _transport;
  final CheckoutAccessTokenProvider _accessTokenProvider;

  Future<Map<String, dynamic>> checkout(
    CheckoutRequest request, {
    required String idempotencyKey,
  }) async {
    // TODO: Lấy Supabase access token từ auth module sau khi foundation được merge
    final accessToken = await _accessTokenProvider();
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw const CheckoutFailure(code: CheckoutErrorCode.authTokenInvalid);
    }

    try {
      final response = await _transport.post(
        path: endpoint,
        headers: <String, String>{
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Idempotency-Key': idempotencyKey,
        },
        body: request.toJson(),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CheckoutFailure(
          code: _readErrorCode(response.body),
          statusCode: response.statusCode,
        );
      }

      final data = response.body['data'];
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      if (response.body['order'] is Map && response.body['invoice'] is Map) {
        return response.body;
      }

      throw const CheckoutFailure(code: CheckoutErrorCode.malformedResponse);
    } on CheckoutFailure {
      rethrow;
    } catch (_) {
      throw const CheckoutFailure.network();
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
}
