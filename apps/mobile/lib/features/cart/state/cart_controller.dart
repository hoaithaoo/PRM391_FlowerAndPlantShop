import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

import '../data/cart_failure.dart';
import '../data/cart_repository.dart';
import '../models/cart_item.dart';

const cartMaxPerProduct = 10;

enum CartStatus { initial, loading, ready, error }

class CartController extends ChangeNotifier {
  CartController({required CartRepository repository})
    : _repository = repository;

  final CartRepository _repository;
  List<CartItem> _items = const [];
  CartStatus _status = CartStatus.initial;
  String? _errorMessage;
  bool _mutating = false;
  int _operationGeneration = 0;
  int _subtotal = 0;
  int _totalQuantity = 0;

  /// Lưu món bị bỏ chọn (không lưu món được chọn) để món mới thêm vào
  /// giỏ mặc định được chọn.
  Set<String> _deselected = const {};

  UnmodifiableListView<CartItem> get items => UnmodifiableListView(_items);
  CartStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading =>
      _status == CartStatus.initial || _status == CartStatus.loading;
  bool get isMutating => _mutating;
  bool get isEmpty => _items.isEmpty;
  int get totalQuantity => _totalQuantity;
  int get subtotal => _subtotal;

  bool isSelected(String itemId) => !_deselected.contains(itemId);
  List<CartItem> get selectedItems =>
      _items.where((item) => isSelected(item.id)).toList(growable: false);
  bool get hasSelection => _items.any((item) => isSelected(item.id));
  bool get isAllSelected => _deselected.isEmpty;
  int get selectedSubtotal =>
      selectedItems.fold(0, (sum, item) => sum + item.subtotal);
  int get selectedQuantity =>
      selectedItems.fold(0, (sum, item) => sum + item.quantity);

  void toggleSelected(String itemId) {
    if (!_items.any((item) => item.id == itemId)) return;
    _deselected = _deselected.contains(itemId)
        ? ({..._deselected}..remove(itemId))
        : {..._deselected, itemId};
    notifyListeners();
  }

  void setAllSelected(bool selected) {
    _deselected = selected ? const {} : {for (final item in _items) item.id};
    notifyListeners();
  }

  Future<void> initialize() async {
    final generation = ++_operationGeneration;
    _status = CartStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final snapshot = await _repository.load();
      if (generation != _operationGeneration) return;
      _apply(snapshot);
      _status = CartStatus.ready;
    } on CartFailure catch (error) {
      if (generation != _operationGeneration) return;
      _status = CartStatus.error;
      _errorMessage = error.message;
    } catch (_) {
      if (generation != _operationGeneration) return;
      _status = CartStatus.error;
      _errorMessage = 'Không thể tải giỏ hàng. Vui lòng thử lại.';
    }
    notifyListeners();
  }

  /// Xoá giỏ đang giữ khi đăng xuất, tránh lộ sang tài khoản kế tiếp.
  void reset() {
    _operationGeneration++;
    _items = const [];
    _subtotal = 0;
    _totalQuantity = 0;
    _deselected = const {};
    _status = CartStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> addProduct(ProductDetail product, {int quantity = 1}) {
    if (!product.inStock || quantity < 1) return Future.value(false);
    return _mutate(
      () => _repository.add(productId: product.id, quantity: quantity),
    );
  }

  /// Dùng khi chỉ có mã sản phẩm (trợ lý AI); server kiểm tra tồn kho.
  Future<bool> addProductById(String productId, {int quantity = 1}) {
    if (quantity < 1) return Future.value(false);
    return _mutate(
      () => _repository.add(productId: productId, quantity: quantity),
    );
  }

  Future<bool> updateQuantity(String itemId, int quantity) {
    if (quantity < 1) return Future.value(false);
    return _mutate(
      () => _repository.update(itemId: itemId, quantity: quantity),
    );
  }

  Future<bool> remove(String itemId) =>
      _mutate(() => _repository.remove(itemId: itemId));

  Future<bool> clear() => _mutate(_repository.clear);

  void dismissError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _mutate(Future<CartSnapshot> Function() operation) async {
    if (_mutating) return false;
    final generation = ++_operationGeneration;
    _mutating = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final snapshot = await operation();
      if (generation != _operationGeneration) return false;
      _apply(snapshot);
      _status = CartStatus.ready;
      return true;
    } on CartFailure catch (error) {
      if (generation != _operationGeneration) return false;
      _errorMessage = error.message;
      return false;
    } catch (_) {
      if (generation != _operationGeneration) return false;
      _errorMessage = 'Không thể cập nhật giỏ hàng. Vui lòng thử lại.';
      return false;
    } finally {
      _mutating = false;
      notifyListeners();
    }
  }

  void _apply(CartSnapshot snapshot) {
    _items = List<CartItem>.unmodifiable(snapshot.items);
    _subtotal = snapshot.subtotal;
    _totalQuantity = snapshot.totalQuantity;
    final ids = {for (final item in _items) item.id};
    _deselected = _deselected.where(ids.contains).toSet();
    _errorMessage = null;
  }
}
