import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/cart/data/cart_failure.dart';
import 'package:plant_flower_mobile/features/cart/data/cart_repository.dart';
import 'package:plant_flower_mobile/features/cart/models/cart_item.dart';
import 'package:plant_flower_mobile/features/cart/state/cart_controller.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

const _category = Category(
  id: '10000000-0000-4000-8000-000000000001',
  name: 'Hoa tươi',
  slug: 'hoa-tuoi',
);

const _product = ProductDetail(
  id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  sku: 'FL-101',
  name: 'Bó Tulip',
  description: 'Tulip tươi',
  price: 490000,
  stock: 8,
  taxRate: 0,
  category: _category,
  imageUrls: [],
);

CartSnapshot _snapshot(int quantity) => CartSnapshot(
  id: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
  items: quantity == 0
      ? const []
      : [
          CartItem(
            id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
            productId: _product.id,
            name: _product.name,
            variant: _category.name,
            unitPrice: _product.price,
            stock: _product.stock,
            quantity: quantity,
          ),
        ],
  subtotal: _product.price * quantity,
  totalQuantity: quantity,
);

class FakeCartRepository implements CartRepository {
  CartSnapshot snapshot = _snapshot(1);
  CartFailure? failure;
  Completer<CartSnapshot>? pendingLoad;
  Completer<CartSnapshot>? pendingUpdate;
  final calls = <String>[];

  @override
  Future<CartSnapshot> load() async {
    calls.add('load');
    if (failure case final error?) throw error;
    if (pendingLoad case final pending?) return pending.future;
    return snapshot;
  }

  @override
  Future<CartSnapshot> add({
    required String productId,
    required int quantity,
  }) async {
    calls.add('add:$productId:$quantity');
    if (failure case final error?) throw error;
    return snapshot = _snapshot(snapshot.totalQuantity + quantity);
  }

  @override
  Future<CartSnapshot> update({required String itemId, required int quantity}) {
    calls.add('update:$itemId:$quantity');
    if (failure case final error?) return Future.error(error);
    if (pendingUpdate case final pending?) return pending.future;
    return Future.value(snapshot = _snapshot(quantity));
  }

  @override
  Future<CartSnapshot> remove({required String itemId}) async {
    calls.add('remove:$itemId');
    if (failure case final error?) throw error;
    return snapshot = _snapshot(0);
  }

  @override
  Future<CartSnapshot> clear() async {
    calls.add('clear');
    if (failure case final error?) throw error;
    return snapshot = _snapshot(0);
  }
}

void main() {
  test('initialize lấy snapshot giỏ hàng từ repository', () async {
    final repository = FakeCartRepository()..snapshot = _snapshot(2);
    final controller = CartController(repository: repository);
    addTearDown(controller.dispose);

    await controller.initialize();

    expect(controller.status, CartStatus.ready);
    expect(controller.totalQuantity, 2);
    expect(controller.subtotal, 980000);
    expect(repository.calls, ['load']);
  });

  test('addProduct chỉ gửi id/số lượng và nhận snapshot mới từ API', () async {
    final repository = FakeCartRepository();
    final controller = CartController(repository: repository);
    addTearDown(controller.dispose);
    await controller.initialize();

    final added = await controller.addProduct(_product, quantity: 2);

    expect(added, isTrue);
    expect(controller.totalQuantity, 3);
    expect(repository.calls.last, 'add:${_product.id}:2');
  });

  test('lỗi mutation giữ snapshot cũ và cung cấp lỗi để retry', () async {
    final repository = FakeCartRepository();
    final controller = CartController(repository: repository);
    addTearDown(controller.dispose);
    await controller.initialize();
    repository.failure = const CartFailure(
      code: CartErrorCode.network,
      message: 'Mất kết nối',
    );

    final updated = await controller.updateQuantity(
      'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
      2,
    );

    expect(updated, isFalse);
    expect(controller.totalQuantity, 1);
    expect(controller.errorMessage, 'Mất kết nối');
  });

  test('không chạy mutation thứ hai khi response trước chưa về', () async {
    final repository = FakeCartRepository()..pendingUpdate = Completer();
    final controller = CartController(repository: repository);
    addTearDown(controller.dispose);
    await controller.initialize();

    final first = controller.updateQuantity(
      'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
      2,
    );
    final second = await controller.updateQuantity(
      'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
      3,
    );
    repository.pendingUpdate!.complete(_snapshot(2));

    expect(second, isFalse);
    expect(await first, isTrue);
    expect(
      repository.calls.where((call) => call.startsWith('update')),
      hasLength(1),
    );
    expect(controller.totalQuantity, 2);
  });

  test('stale load response does not overwrite a newer mutation', () async {
    final repository = FakeCartRepository()..pendingLoad = Completer();
    final controller = CartController(repository: repository);
    addTearDown(controller.dispose);

    final loading = controller.initialize();
    await Future<void>.delayed(Duration.zero);
    final added = await controller.addProduct(_product, quantity: 2);
    repository.pendingLoad!.complete(_snapshot(1));
    await loading;

    expect(added, isTrue);
    expect(controller.totalQuantity, 3);
    expect(controller.status, CartStatus.ready);
  });

  group('chọn món để thanh toán', () {
    CartItem item(String id, int price, int quantity) => CartItem(
      id: id,
      productId: 'p-$id',
      name: 'Món $id',
      variant: '',
      unitPrice: price,
      stock: 10,
      quantity: quantity,
    );

    CartSnapshot twoItems() => CartSnapshot(
      id: 'cart',
      items: [item('a', 100000, 2), item('b', 50000, 1)],
      subtotal: 250000,
      totalQuantity: 3,
    );

    test(
      'mặc định chọn cả giỏ, bỏ chọn thì tạm tính chỉ tính món còn chọn',
      () async {
        final repository = FakeCartRepository()..snapshot = twoItems();
        final controller = CartController(repository: repository);
        addTearDown(controller.dispose);
        await controller.initialize();

        expect(controller.isAllSelected, isTrue);
        expect(controller.selectedSubtotal, 250000);

        controller.toggleSelected('a');
        expect(controller.isSelected('a'), isFalse);
        expect(controller.isAllSelected, isFalse);
        expect(controller.selectedItems.map((e) => e.id), ['b']);
        expect(controller.selectedSubtotal, 50000);
        expect(controller.subtotal, 250000);

        controller.setAllSelected(false);
        expect(controller.hasSelection, isFalse);
        expect(controller.selectedSubtotal, 0);

        controller.setAllSelected(true);
        expect(controller.isAllSelected, isTrue);
      },
    );

    test(
      'món mới thêm vào được chọn sẵn, món đã xoá bị bỏ khỏi lựa chọn',
      () async {
        final repository = FakeCartRepository()..snapshot = twoItems();
        final controller = CartController(repository: repository);
        addTearDown(controller.dispose);
        await controller.initialize();
        controller.toggleSelected('a');

        repository.snapshot = CartSnapshot(
          id: 'cart',
          items: [item('b', 50000, 1), item('c', 20000, 1)],
          subtotal: 70000,
          totalQuantity: 2,
        );
        await controller.initialize();

        expect(controller.isAllSelected, isTrue);
        expect(controller.selectedItems.map((e) => e.id), ['b', 'c']);
      },
    );

    test('reset xoá lựa chọn cũ', () async {
      final repository = FakeCartRepository()..snapshot = twoItems();
      final controller = CartController(repository: repository);
      addTearDown(controller.dispose);
      await controller.initialize();
      controller.toggleSelected('a');

      controller.reset();
      await controller.initialize();

      expect(controller.isAllSelected, isTrue);
    });
  });
}
