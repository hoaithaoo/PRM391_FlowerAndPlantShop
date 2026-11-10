import '../models/cart_item.dart';

abstract interface class CartRepository {
  Future<CartSnapshot> load();

  Future<CartSnapshot> add({required String productId, required int quantity});

  Future<CartSnapshot> update({required String itemId, required int quantity});

  Future<CartSnapshot> remove({required String itemId});

  Future<CartSnapshot> clear();
}
