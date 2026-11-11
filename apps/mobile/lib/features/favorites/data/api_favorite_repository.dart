import 'package:plant_flower_api_client/plant_flower_api_client.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

import 'favorite_repository.dart';

typedef FavoriteAccessTokenProvider = Future<String?> Function();

class ApiFavoriteRepository implements FavoriteRepository {
  ApiFavoriteRepository(
    this._client, {
    required FavoriteAccessTokenProvider accessTokenProvider,
  }) : _accessTokenProvider = accessTokenProvider;

  static const _path = 'api/v1/favorites';
  final ApiClient _client;
  final FavoriteAccessTokenProvider _accessTokenProvider;

  @override
  Future<Set<String>> listIds() => _request((headers) async {
    final response = await _client.get('$_path/ids', headers: headers);
    final data = response.data;
    if (data is! Map || data['productIds'] is! List) {
      throw const FormatException('Dữ liệu yêu thích không hợp lệ');
    }
    return (data['productIds'] as List).cast<String>().toSet();
  });

  @override
  Future<List<ProductSummary>> list() => _request((headers) async {
    final response = await _client.get(_path, headers: headers);
    final data = response.data;
    if (data is! Map || data['items'] is! List) {
      throw const FormatException('Dữ liệu yêu thích không hợp lệ');
    }
    return [
      for (final item in data['items'] as List)
        ProductSummary.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  });

  @override
  Future<void> add(String productId) => _request((headers) async {
    await _client.put(_itemPath(productId), headers: headers);
  });

  @override
  Future<void> remove(String productId) => _request((headers) async {
    await _client.delete(_itemPath(productId), headers: headers);
  });

  String _itemPath(String id) => '$_path/${Uri.encodeComponent(id)}';

  Future<T> _request<T>(
    Future<T> Function(Map<String, String> headers) send,
  ) async {
    final token = await _accessTokenProvider();
    if (token == null || token.trim().isEmpty) {
      throw const FavoriteFailure(
        'Vui lòng đăng nhập để sử dụng yêu thích.',
        code: 'AUTH_TOKEN_MISSING',
        statusCode: 401,
      );
    }
    try {
      return await send({'Authorization': 'Bearer ${token.trim()}'});
    } on ApiException catch (error) {
      throw FavoriteFailure(
        error.message,
        code: error.code,
        statusCode: error.statusCode,
      );
    } on FormatException {
      throw const FavoriteFailure('Dữ liệu yêu thích từ máy chủ không hợp lệ.');
    } on TypeError {
      throw const FavoriteFailure('Dữ liệu yêu thích từ máy chủ không hợp lệ.');
    }
  }
}
