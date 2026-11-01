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
    this.refreshAccessToken,
    this.onSessionExpired,
  }) : _baseUri = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'),
       _http = httpClient ?? http.Client();

  final Uri _baseUri;
  final http.Client _http;
  final Duration timeout;

  /// Lấy token mới khi server trả 401. Trả `null` nếu phiên không cứu được;
  /// ném lỗi nếu chưa biết (ví dụ mất mạng) để không đăng xuất nhầm.
  final Future<String?> Function()? refreshAccessToken;

  /// Gọi khi token mới cũng bị từ chối hoặc không lấy được token mới.
  final void Function()? onSessionExpired;

  /// Nhiều request cùng gặp 401 chỉ refresh một lần.
  Future<String?>? _refreshing;

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

  Future<ApiResponse> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) => _send('PUT', path, headers: headers, body: body);

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
    var response = await _execute(method, uri, headers, body);

    // 401 do middleware chặn trước handler nên gửi lại POST là an toàn.
    final refresh = refreshAccessToken;
    if (response.statusCode == 401 &&
        refresh != null &&
        (headers?.containsKey('Authorization') ?? false)) {
      final String? token;
      try {
        token = await (_refreshing ??= refresh().whenComplete(
          () => _refreshing = null,
        ));
      } catch (_) {
        return _decode(response);
      }
      if (token != null) {
        response = await _execute(method, uri, {
          ...?headers,
          'Authorization': 'Bearer $token',
        }, body);
      }
      if (response.statusCode == 401) onSessionExpired?.call();
    }
    return _decode(response);
  }

  Future<http.Response> _execute(
    String method,
    Uri uri,
    Map<String, String>? headers,
    Object? body,
  ) async {
    try {
      final request = http.Request(method, uri)
        ..headers.addAll({'Accept': 'application/json', ...?headers});
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      return await (() async {
        final streamed = await _http.send(request);
        return http.Response.fromStream(streamed);
      })().timeout(timeout);
    } on TimeoutException {
      throw const ApiException.network('Máy chủ phản hồi quá lâu.');
    } on http.ClientException {
      // IOClient bọc SocketException thành ClientException
      throw const ApiException.network();
    }
  }

  ApiResponse _decode(http.Response response) {
    // 204 No Content không có envelope, ví dụ DELETE /cart/items/:id
    if (response.statusCode == 204) {
      return const ApiResponse(data: null, meta: {});
    }

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
