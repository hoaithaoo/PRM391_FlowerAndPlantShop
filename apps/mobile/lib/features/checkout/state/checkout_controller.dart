import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/checkout_failure.dart';
import '../data/checkout_repository.dart';
import '../models/checkout_request.dart';
import '../models/checkout_result.dart';
import 'checkout_state.dart';

typedef IdempotencyKeyFactory = String Function();

class CheckoutController extends ChangeNotifier {
  CheckoutController({
    required CheckoutRepository repository,
    IdempotencyKeyFactory? idempotencyKeyFactory,
  }) : _repository = repository,
       _idempotencyKeyFactory = idempotencyKeyFactory ?? _defaultKeyFactory;

  final CheckoutRepository _repository;
  final IdempotencyKeyFactory _idempotencyKeyFactory;

  CheckoutState _state = const CheckoutState();
  String? _activeIdempotencyKey;
  bool _isDisposed = false;

  CheckoutState get state => _state;

  Future<CheckoutResult?> submit(CheckoutRequest request) async {
    if (_state.isSubmitting) {
      return null;
    }

    // Giữ nguyên khóa trong suốt một lần gửi để ngăn tạo đơn trùng lặp
    final idempotencyKey = _activeIdempotencyKey ??= _idempotencyKeyFactory();
    _setState(const CheckoutState(status: CheckoutStatus.submitting));

    try {
      final result = await _repository.checkout(
        request,
        idempotencyKey: idempotencyKey,
      );
      _setState(CheckoutState(status: CheckoutStatus.success, result: result));
      return result;
    } on CheckoutFailure catch (failure) {
      _setState(_stateForFailure(failure));
      return null;
    } catch (_) {
      _setState(
        const CheckoutState(
          status: CheckoutStatus.error,
          errorMessage: 'Không thể xử lý đơn hàng lúc này. Vui lòng thử lại.',
        ),
      );
      return null;
    } finally {
      _activeIdempotencyKey = null;
    }
  }

  void resetError() {
    if (_state.status == CheckoutStatus.error ||
        _state.status == CheckoutStatus.authenticationRequired) {
      _setState(const CheckoutState());
    }
  }

  CheckoutState _stateForFailure(CheckoutFailure failure) {
    return switch (failure.code) {
      CheckoutErrorCode.productOutOfStock => const CheckoutState(
        status: CheckoutStatus.error,
        errorMessage:
            'Một hoặc nhiều sản phẩm đã hết hàng hoặc không đủ số lượng.',
      ),
      CheckoutErrorCode.checkoutConflict => const CheckoutState(
        status: CheckoutStatus.error,
        errorMessage: 'Đơn hàng đang được xử lý. Vui lòng thử lại.',
      ),
      CheckoutErrorCode.cartEmpty => const CheckoutState(
        status: CheckoutStatus.error,
        errorMessage: 'Giỏ hàng của bạn đang trống.',
      ),
      CheckoutErrorCode.validationError => const CheckoutState(
        status: CheckoutStatus.error,
        errorMessage:
            'Thông tin thanh toán chưa hợp lệ. Vui lòng kiểm tra lại.',
      ),
      CheckoutErrorCode.authTokenInvalid ||
      CheckoutErrorCode.authTokenMissing => const CheckoutState(
        status: CheckoutStatus.authenticationRequired,
        errorMessage: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      ),
      _ => const CheckoutState(
        status: CheckoutStatus.error,
        errorMessage: 'Không thể xử lý đơn hàng lúc này. Vui lòng thử lại.',
      ),
    };
  }

  void _setState(CheckoutState nextState) {
    if (_isDisposed) {
      return;
    }
    _state = nextState;
    notifyListeners();
  }

  static String _defaultKeyFactory() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomPart = Random.secure().nextInt(0x7fffffff).toRadixString(16);
    return 'checkout-$timestamp-$randomPart';
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
