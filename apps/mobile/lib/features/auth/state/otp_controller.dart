import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/auth_failure.dart';
import '../data/auth_repository.dart';
import '../models/auth_models.dart';
import '../utils/auth_validators.dart';
import 'otp_state.dart';

/// Điều khiển màn OTP: nhập mã, xác nhận, đếm ngược và gửi lại mã.
class OtpController extends ChangeNotifier {
  OtpController({
    required AuthRepository repository,
    required this.email,
    required this.purpose,
    this.resendCooldown = const Duration(seconds: 60),
  }) : _repository = repository {
    _startCooldown();
  }

  final AuthRepository _repository;
  final String email;
  final OtpPurpose purpose;

  /// Thời gian chờ giữa hai lần gửi mã (test có thể rút ngắn).
  final Duration resendCooldown;

  OtpState _state = const OtpState();
  Timer? _timer;
  bool _isDisposed = false;

  OtpState get state => _state;

  /// Cập nhật mã đang nhập; chỉ giữ chữ số và tối đa 6 ký tự.
  void setCode(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final code = digits.length > AuthValidators.otpLength
        ? digits.substring(0, AuthValidators.otpLength)
        : digits;
    if (code == _state.code) return;
    _setState(_state.copyWith(code: code, hasError: false));
  }

  /// Xác nhận mã; sai mã thì xóa các ô và đánh dấu lỗi.
  Future<OtpResult> verify() async {
    if (_state.isVerifying) return OtpResult.ignored;
    final error = AuthValidators.otp(_state.code);
    if (error != null) return OtpResult(OtpResultStatus.invalid, error);

    _setState(_state.copyWith(isVerifying: true));
    try {
      await _repository.verifyOtp(
        email: email,
        token: _state.code,
        purpose: purpose,
      );
      return OtpResult.success;
    } on AuthFailure catch (failure) {
      _setState(_state.copyWith(code: '', hasError: true));
      return OtpResult(OtpResultStatus.failure, failure.message);
    } catch (_) {
      _setState(_state.copyWith(code: '', hasError: true));
      return OtpResult.unknown;
    } finally {
      _setState(_state.copyWith(isVerifying: false));
    }
  }

  /// Gửi lại mã rồi đếm ngược lại từ đầu.
  Future<OtpResult> resend() async {
    if (!_state.canResend) return OtpResult.ignored;

    _setState(_state.copyWith(isResending: true));
    try {
      await _repository.resendOtp(email: email, purpose: purpose);
      _startCooldown();
      return OtpResult.success;
    } on AuthFailure catch (failure) {
      return OtpResult(OtpResultStatus.failure, failure.message);
    } catch (_) {
      return OtpResult.unknown;
    } finally {
      _setState(_state.copyWith(isResending: false));
    }
  }

  void _startCooldown() {
    if (_isDisposed) return;
    _timer?.cancel();
    _setState(_state.copyWith(remaining: resendCooldown));
    if (resendCooldown <= Duration.zero) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = _state.remaining - const Duration(seconds: 1);
      if (next <= Duration.zero) {
        timer.cancel();
        _setState(_state.copyWith(remaining: Duration.zero));
      } else {
        _setState(_state.copyWith(remaining: next));
      }
    });
  }

  void _setState(OtpState next) {
    if (_isDisposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
