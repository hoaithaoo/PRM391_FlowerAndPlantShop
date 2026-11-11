import 'dart:convert';
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
  String? _activeFingerprint;
  bool _isDisposed = false;

  CheckoutState get state => _state;

  Future<CheckoutResult?> submit(CheckoutRequest request) async {
    if (_state.isSubmitting) {
      return null;
    }

    // Giữ nguyên khóa khi gửi lại cùng dữ liệu để không tạo đơn trùng; đổi dữ
    // liệu thì đổi khóa vì server từ chối khóa cũ cho yêu cầu khác.
    final fingerprint = jsonEncode(request.toJson());
    if (fingerprint != _activeFingerprint) {
      _activeFingerprint = fingerprint;
      _activeIdempotencyKey = _idempotencyKeyFactory();
    }
    final idempotencyKey = _activeIdempotencyKey!;
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
    _activeFingerprint = null;
  }

  void resetError() {
    if (_state.status == CheckoutStatus.error ||
        _state.status == CheckoutStatus.authenticationRequired) {
      _setState(const CheckoutState());
    }
  }

  CheckoutState _stateForFailure(CheckoutFailure failure) {
    return switch (failure.code) {
      CheckoutErrorCode.voucherNotFound => CheckoutState(
        status: CheckoutStatus.error,
        errorCode: failure.code,
        errorMessage: 'Mã voucher không tồn tại.',
      ),
      CheckoutErrorCode.voucherExpired => CheckoutState(
        status: CheckoutStatus.error,
        errorCode: failure.code,
        errorMessage: 'Voucher đã hết hạn.',
      ),
      CheckoutErrorCode.voucherUsageExceeded => CheckoutState(
        status: CheckoutStatus.error,
        errorCode: failure.code,
        errorMessage: 'Voucher đã hết lượt sử dụng.',
      ),
      CheckoutErrorCode.voucherMinOrderNotMet => CheckoutState(
        status: CheckoutStatus.error,
        errorCode: failure.code,
        errorMessage: 'Đơn hàng chưa đạt giá trị tối thiểu của voucher.',
      ),
      CheckoutErrorCode.voucherNotApplicable => CheckoutState(
        status: CheckoutStatus.error,
        errorCode: failure.code,
        errorMessage:
            'Không thể thanh toán SePay cho đơn 0đ. Vui lòng chọn COD.',
      ),
      CheckoutErrorCode.productOutOfStock => CheckoutState(
        status: CheckoutStatus.error,
        errorCode: failure.code,
        errorMessage:
            'Một hoặc nhiều sản phẩm đã hết hàng hoặc không đủ số lượng.',
      ),
      CheckoutErrorCode.checkoutConflict => CheckoutState(
        status: CheckoutStatus.error,
        errorCode: failure.code,
        errorMessage: 'Đơn hàng đang được xử lý. Vui lòng thử lại.',
      ),
      CheckoutErrorCode.cartEmpty => CheckoutState(
        status: CheckoutStatus.error,
        errorCode: failure.code,
        errorMessage: 'Giỏ hàng của bạn đang trống.',
      ),
      CheckoutErrorCode.cartItemNotFound => CheckoutState(
        status: CheckoutStatus.error,
        errorCode: failure.code,
        errorMessage:
            'Một số sản phẩm đã chọn không còn trong giỏ. Vui lòng quay lại giỏ hàng.',
      ),
      CheckoutErrorCode.storeNotFound => CheckoutState(
        status: CheckoutStatus.error,
        errorCode: failure.code,
        errorMessage: 'Hiện không có cửa hàng phục vụ khu vực này.',
      ),
      CheckoutErrorCode.pickupTimeInvalid => CheckoutState(
        status: CheckoutStatus.error,
        errorCode: failure.code,
        errorMessage: 'Thời gian nhận hoa không hợp lệ. Vui lòng chọn lại.',
      ),
      CheckoutErrorCode.forbidden => CheckoutState(
        status: CheckoutStatus.error,
        errorCode: failure.code,
        errorMessage: 'Tài khoản này không được phép đặt hàng.',
      ),
      CheckoutErrorCode.network => CheckoutState(
        status: CheckoutStatus.error,
        errorCode: failure.code,
        errorMessage: 'Không kết nối được máy chủ. Vui lòng thử lại.',
      ),
      CheckoutErrorCode.validationError => CheckoutState(
        status: CheckoutStatus.error,
        errorCode: failure.code,
        errorMessage:
            'Thông tin thanh toán chưa hợp lệ. Vui lòng kiểm tra lại.',
      ),
      CheckoutErrorCode.authTokenInvalid ||
      CheckoutErrorCode.authTokenMissing => CheckoutState(
        status: CheckoutStatus.authenticationRequired,
        errorCode: failure.code,
        errorMessage: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      ),
      _ when failure.statusCode == 403 => CheckoutState(
        status: CheckoutStatus.error,
        errorCode: failure.code,
        errorMessage:
            'Tài khoản của bạn không có quyền thực hiện thao tác này.',
      ),
      _ when failure.statusCode == 409 => CheckoutState(
        status: CheckoutStatus.error,
        errorCode: failure.code,
        errorMessage:
            'Dữ liệu đơn hàng đã thay đổi. Vui lòng kiểm tra lại giỏ hàng.',
      ),
      _ when failure.statusCode == 422 => CheckoutState(
        status: CheckoutStatus.error,
        errorCode: failure.code,
        errorMessage: 'Thông tin đặt hàng chưa hợp lệ. Vui lòng kiểm tra lại.',
      ),
      _ => CheckoutState(
        status: CheckoutStatus.error,
        errorCode: failure.code,
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
