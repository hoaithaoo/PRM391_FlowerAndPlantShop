import 'package:plant_flower_api_client/plant_flower_api_client.dart';

import 'checkout_remote_data_source.dart';

class ApiClientCheckoutTransport implements CheckoutApiTransport {
  const ApiClientCheckoutTransport(this._client);

  final ApiClient _client;

  @override
  Future<CheckoutApiResponse> get({
    required String path,
    required Map<String, String> headers,
    Map<String, String>? query,
  }) => _request(() => _client.get(path, headers: headers, query: query));

  @override
  Future<CheckoutApiResponse> post({
    required String path,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) => _request(() => _client.post(path, headers: headers, body: body));

  @override
  Future<CheckoutApiResponse> put({
    required String path,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) => _request(() => _client.put(path, headers: headers, body: body));

  @override
  Future<CheckoutApiResponse> patch({
    required String path,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) => _request(() => _client.patch(path, headers: headers, body: body));

  Future<CheckoutApiResponse> _request(
    Future<ApiResponse> Function() send,
  ) async {
    try {
      final response = await send();
      return CheckoutApiResponse(
        statusCode: response.statusCode,
        body: <String, dynamic>{'data': response.data},
      );
    } on ApiException catch (error) {
      if (error.isNetworkError) rethrow;
      return CheckoutApiResponse(
        statusCode: error.statusCode,
        body: <String, dynamic>{
          'error': <String, dynamic>{'code': error.code},
        },
      );
    }
  }
}
