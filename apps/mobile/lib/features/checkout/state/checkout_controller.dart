import 'dart:math';
import 'dart:convert';

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
  String? _activeRequestFingerprint;
  bool _isDisposed = false;

  CheckoutState get state => _state;

  Future<CheckoutResult?> submit(CheckoutRequest request) async {
    if (_state.isSubmitting) {
      return null;
    }

    final fingerprint = jsonEncode(request.toJson());
    if (_activeRequestFingerprint != fingerprint) {
      _activeRequestFingerprint = fingerprint;
      _activeIdempotencyKey = _idempotencyKeyFactory();
    }
    // Giữ nguyên khóa khi retry một request có kết quả chưa chắc chắn.
    final idempotencyKey = _activeIdempotencyKey ??= _idempotencyKeyFactory();
    _setState(const CheckoutState(status: CheckoutStatus.submitting));

    try {
      final result = await _repository.checkout(
        request,
        idempotencyKey: idempotencyKey,
      );
      _setState(CheckoutState(status: CheckoutStatus.success, result: result));
      _clearAttempt();
      return result;
    } on CheckoutFailure catch (failure) {
      _setState(_stateForFailure(failure));
      if (!_hasUncertainOutcome(failure)) _clearAttempt();
      return null;
    } catch (_) {
      _setState(
        const CheckoutState(
          status: CheckoutStatus.error,
          errorMessage: 'Không thể xử lý đơn hàng lúc này. Vui lòng thử lại.',
        ),
      );
      return null;
    }
  }

  bool _hasUncertainOutcome(CheckoutFailure failure) {
    return failure.code == CheckoutErrorCode.network ||
        failure.code == CheckoutErrorCode.malformedResponse ||
        (failure.statusCode != null && failure.statusCode! >= 500);
  }

  void _clearAttempt() {
    _activeIdempotencyKey = null;
    _activeRequestFingerprint = null;
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
      _ when failure.statusCode == 403 => const CheckoutState(
        status: CheckoutStatus.error,
        errorMessage:
            'Tài khoản của bạn không có quyền thực hiện thao tác này.',
      ),
      _ when failure.statusCode == 409 => const CheckoutState(
        status: CheckoutStatus.error,
        errorMessage:
            'Dữ liệu đơn hàng đã thay đổi. Vui lòng kiểm tra lại giỏ hàng.',
      ),
      _ when failure.statusCode == 422 => const CheckoutState(
        status: CheckoutStatus.error,
        errorMessage:
            'Thông tin đặt hàng chưa hợp lệ. Vui lòng kiểm tra lại.',
      ),
      _ => CheckoutState(
        status: CheckoutStatus.error,
        errorMessage:
            failure.message ??
            'Không thể xử lý đơn hàng lúc này. Vui lòng thử lại.',
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
