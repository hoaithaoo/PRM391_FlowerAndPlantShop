import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// Response thành công đã bóc envelope `{ success, data, meta }`.
class ApiResponse {
  const ApiResponse({required this.data, required this.meta});

  final Object? data;
  final Map<String, dynamic> meta;
}

/// HTTP client tối giản cho REST API `/api/v1`.
class ApiClient {
  ApiClient({
    required String baseUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 15),
  }) : _baseUri = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'),
       _http = httpClient ?? http.Client();

  final Uri _baseUri;
  final http.Client _http;
  final Duration timeout;

  /// [path] tương đối với base URL, ví dụ `api/v1/products`.
  Future<ApiResponse> get(String path, {Map<String, String>? query}) async {
    final uri = _baseUri.resolve(path).replace(queryParameters: query);
    final http.Response response;
    try {
      response = await _http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(timeout);
    } on TimeoutException {
      throw const ApiException.network('Máy chủ phản hồi quá lâu.');
    } on http.ClientException {
      // IOClient bọc SocketException thành ClientException
      throw const ApiException.network();
    }
    return _decode(response);
  }

  ApiResponse _decode(http.Response response) {
    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) body = decoded;
    } on FormatException {
      body = null;
    }

    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (ok && body != null && body['success'] != false) {
      return ApiResponse(
        data: body['data'],
        meta: (body['meta'] as Map<String, dynamic>?) ?? const {},
      );
    }

    final error = body?['error'];
    if (error is Map<String, dynamic>) {
      throw ApiException(
        statusCode: response.statusCode,
        code: error['code'] as String? ?? 'UNKNOWN_ERROR',
        message:
            error['message'] as String? ??
            'Đã có lỗi xảy ra. Vui lòng thử lại sau.',
      );
    }
    throw ApiException(
      statusCode: response.statusCode,
      code: 'UNKNOWN_ERROR',
      message: 'Đã có lỗi xảy ra. Vui lòng thử lại sau.',
    );
  }

  void close() => _http.close();
}
