import 'package:plant_flower_mobile/features/cart/data/cart_repository.dart';
import 'package:plant_flower_mobile/features/cart/models/cart_item.dart';
import 'package:plant_flower_mobile/features/checkout/utils/checkout_assets.dart';

class TestCartRepository implements CartRepository {
  TestCartRepository({CartSnapshot? initial})
    : snapshot = initial ?? demoCartSnapshot;

  CartSnapshot snapshot;

  @override
  Future<CartSnapshot> load() async => snapshot;

  @override
  Future<CartSnapshot> add({
    required String productId,
    required int quantity,
  }) async {
    final index = snapshot.items.indexWhere(
      (item) => item.productId == productId,
    );
    if (index == -1) {
      return snapshot = _withItems([
        ...snapshot.items,
        CartItem(
          id: 'test-item-$productId',
          productId: productId,
          name: 'Sản phẩm test',
          variant: 'Test',
          unitPrice: 490000,
          stock: 10,
          quantity: quantity,
        ),
      ]);
    }
    final items = [...snapshot.items];
    items[index] = items[index].copyWith(
      quantity: items[index].quantity + quantity,
    );
    return snapshot = _withItems(items);
  }

  @override
  Future<CartSnapshot> update({
    required String itemId,
    required int quantity,
  }) async {
    return snapshot = _withItems([
      for (final item in snapshot.items)
        item.id == itemId ? item.copyWith(quantity: quantity) : item,
    ]);
  }

  @override
  Future<CartSnapshot> remove({required String itemId}) async {
    return snapshot = _withItems([
      for (final item in snapshot.items)
        if (item.id != itemId) item,
    ]);
  }

  @override
  Future<CartSnapshot> clear() async => snapshot = _withItems(const []);

  CartSnapshot _withItems(List<CartItem> items) => CartSnapshot(
    id: snapshot.id,
    items: items,
    subtotal: items.fold(0, (total, item) => total + item.subtotal),
    totalQuantity: items.fold(0, (total, item) => total + item.quantity),
  );
}

const demoCartSnapshot = CartSnapshot(
  id: '40000000-0000-4000-8000-000000000001',
  items: [
    CartItem(
      id: '41000000-0000-4000-8000-000000000001',
      productId: '30000000-0000-4000-8000-000000000001',
      name: 'Bó Hoa Bạch Hồng Étoile & Greenery',
      variant: 'Hoa cắm tự nhiên · Size M',
      unitPrice: 490000,
      stock: 12,
      quantity: 1,
      imageAsset: CheckoutAssets.deliveryBouquet,
    ),
    CartItem(
      id: '41000000-0000-4000-8000-000000000002',
      productId: '30000000-0000-4000-8000-000000000002',
      name: 'Cây Bàng Singapore Mini Chậu Gốm',
      variant: 'Chậu gốm mộc · Để bàn',
      unitPrice: 350000,
      stock: 8,
      quantity: 2,
      imageAsset: CheckoutAssets.pickupNotice,
    ),
    CartItem(
      id: '41000000-0000-4000-8000-000000000003',
      productId: '30000000-0000-4000-8000-000000000008',
      name: 'Bình Thủy Tinh Khói Muted Vessel',
      variant: 'Thủy tinh thổi thủ công · Xám khói',
      unitPrice: 195000,
      stock: 25,
      quantity: 1,
      imageAsset: CheckoutAssets.deliveryVase,
    ),
  ],
  subtotal: 1385000,
  totalQuantity: 4,
);
