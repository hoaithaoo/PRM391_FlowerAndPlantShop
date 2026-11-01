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
  Future<ApiResponse> get(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
  }) {
    return _send('GET', path, query: query, headers: headers);
  }

  Future<ApiResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) => _send('POST', path, headers: headers, body: body);

  Future<ApiResponse> patch(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) => _send('PATCH', path, headers: headers, body: body);

  Future<ApiResponse> delete(String path, {Map<String, String>? headers}) =>
      _send('DELETE', path, headers: headers);

  Future<ApiResponse> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = _baseUri.resolve(path).replace(queryParameters: query);
    final http.Response response;
    try {
      final request = http.Request(method, uri)
        ..headers.addAll({'Accept': 'application/json', ...?headers});
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      response = await (() async {
        final streamed = await _http.send(request);
        return http.Response.fromStream(streamed);
      })().timeout(timeout);
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
