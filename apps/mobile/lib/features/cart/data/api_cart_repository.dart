import 'package:plant_flower_api_client/plant_flower_api_client.dart';

import '../models/cart_item.dart';
import 'cart_failure.dart';
import 'cart_repository.dart';

typedef CartAccessTokenProvider = Future<String?> Function();

/// POST/PUT chỉ trả dòng vừa đổi, DELETE trả 204, và backend không có endpoint
/// xoá cả giỏ, nên sau mỗi thao tác đều GET lại snapshot đầy đủ từ server.
class ApiCartRepository implements CartRepository {
  ApiCartRepository(
    this._client, {
    required CartAccessTokenProvider accessTokenProvider,
  }) : _accessTokenProvider = accessTokenProvider;

  static const _cartPath = 'api/v1/cart';
  static const _itemsPath = 'api/v1/cart/items';

  final ApiClient _client;
  final CartAccessTokenProvider _accessTokenProvider;

  @override
  Future<CartSnapshot> load() => _request(_fetch);

  @override
  Future<CartSnapshot> add({
    required String productId,
    required int quantity,
  }) => _request((headers) async {
    await _client.post(
      _itemsPath,
      headers: headers,
      body: {'productId': productId, 'quantity': quantity},
    );
    return _fetch(headers);
  });

  @override
  Future<CartSnapshot> update({
    required String itemId,
    required int quantity,
  }) => _request((headers) async {
    await _client.put(
      _itemPath(itemId),
      headers: headers,
      body: {'quantity': quantity},
    );
    return _fetch(headers);
  });

  @override
  Future<CartSnapshot> remove({required String itemId}) =>
      _request((headers) async {
        await _client.delete(_itemPath(itemId), headers: headers);
        return _fetch(headers);
      });

  @override
  Future<CartSnapshot> clear() => _request((headers) async {
    final cart = await _fetch(headers);
    for (final item in cart.items) {
      await _client.delete(_itemPath(item.id), headers: headers);
    }
    return _fetch(headers);
  });

  String _itemPath(String itemId) =>
      '$_itemsPath/${Uri.encodeComponent(itemId)}';

  Future<CartSnapshot> _fetch(Map<String, String> headers) async {
    final response = await _client.get(_cartPath, headers: headers);
    final data = response.data;
    if (data is! Map) throw const FormatException('Cart data invalid');
    return CartSnapshot.fromJson(Map<String, dynamic>.from(data));
  }

  Future<CartSnapshot> _request(
    Future<CartSnapshot> Function(Map<String, String> headers) send,
  ) async {
    final token = await _accessTokenProvider();
    if (token == null || token.trim().isEmpty) {
      throw const CartFailure(
        code: CartErrorCode.authenticationRequired,
        message: 'Vui lòng đăng nhập để sử dụng giỏ hàng.',
        statusCode: 401,
      );
    }
    try {
      return await send({'Authorization': 'Bearer ${token.trim()}'});
    } on ApiException catch (error) {
      throw CartFailure(
        code: _mapError(error),
        message: error.message,
        statusCode: error.statusCode,
        backendCode: error.code,
      );
    } on FormatException {
      throw const CartFailure(
        code: CartErrorCode.malformedResponse,
        message: 'Dữ liệu giỏ hàng từ máy chủ không hợp lệ.',
      );
    } on TypeError {
      throw const CartFailure(
        code: CartErrorCode.malformedResponse,
        message: 'Dữ liệu giỏ hàng từ máy chủ không hợp lệ.',
      );
    }
  }

  CartErrorCode _mapError(ApiException error) {
    if (error.isNetworkError) return CartErrorCode.network;
    if (error.statusCode == 401 || error.statusCode == 403) {
      return CartErrorCode.authenticationRequired;
    }
    return switch (error.code) {
      'PRODUCT_NOT_FOUND' ||
      'CART_ITEM_NOT_FOUND' => CartErrorCode.productNotFound,
      'PRODUCT_OUT_OF_STOCK' => CartErrorCode.productOutOfStock,
      'VALIDATION_ERROR' => CartErrorCode.validation,
      _ when error.statusCode >= 500 => CartErrorCode.server,
      _ => CartErrorCode.rejected,
    };
  }
}
