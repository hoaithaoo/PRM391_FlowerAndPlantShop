import 'package:plant_flower_api_client/plant_flower_api_client.dart';

import '../models/cart_item.dart';
import 'cart_failure.dart';
import 'cart_repository.dart';

typedef CartAccessTokenProvider = Future<String?> Function();

class ApiCartRepository implements CartRepository {
  ApiCartRepository(
    this._client, {
    required CartAccessTokenProvider accessTokenProvider,
  }) : _accessTokenProvider = accessTokenProvider;

  static const _itemsPath = 'api/v1/cart/items';

  final ApiClient _client;
  final CartAccessTokenProvider _accessTokenProvider;

  @override
  Future<CartSnapshot> load() =>
      _request((headers) => _client.get('api/v1/cart', headers: headers));

  @override
  Future<CartSnapshot> add({
    required String productId,
    required int quantity,
  }) async {
    await _mutation(
      (headers) => _client.post(
        _itemsPath,
        headers: headers,
        body: {'productId': productId, 'quantity': quantity},
      ),
    );
    return load();
  }

  @override
  Future<CartSnapshot> update({
    required String itemId,
    required int quantity,
  }) async {
    await _mutation(
      (headers) => _client.put(
        '$_itemsPath/${Uri.encodeComponent(itemId)}',
        headers: headers,
        body: {'quantity': quantity},
      ),
    );
    return load();
  }

  @override
  Future<CartSnapshot> remove({required String itemId}) async {
    await _mutation(
      (headers) => _client.delete(
        '$_itemsPath/${Uri.encodeComponent(itemId)}',
        headers: headers,
      ),
    );
    return load();
  }

  @override
  Future<CartSnapshot> clear() async {
    final snapshot = await load();
    for (final item in snapshot.items) {
      await _mutation(
        (headers) => _client.delete(
          '$_itemsPath/${Uri.encodeComponent(item.id)}',
          headers: headers,
        ),
      );
    }
    return load();
  }

  Future<void> _mutation(
    Future<ApiResponse> Function(Map<String, String> headers) send,
  ) async {
    await _request(send, parseSnapshot: false);
  }

  Future<CartSnapshot> _request(
    Future<ApiResponse> Function(Map<String, String> headers) send,
    {bool parseSnapshot = true}
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
      final response = await send({'Authorization': 'Bearer ${token.trim()}'});
      if (!parseSnapshot) {
        return const CartSnapshot(
          id: null,
          items: [],
          subtotal: 0,
          totalQuantity: 0,
        );
      }
      final data = response.data;
      if (data is! Map) throw const FormatException('Cart data invalid');
      return CartSnapshot.fromJson(Map<String, dynamic>.from(data));
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
