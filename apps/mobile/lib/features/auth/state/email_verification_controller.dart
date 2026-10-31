import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/auth_failure.dart';
import '../data/auth_repository.dart';
import 'email_verification_state.dart';

/// Điều khiển màn "Kiểm tra email": đếm ngược và gửi lại email xác nhận.
class EmailVerificationController extends ChangeNotifier {
  EmailVerificationController({
    required AuthRepository repository,
    required this.email,
    this.resendCooldown = const Duration(seconds: 60),
  }) : _repository = repository {
    _startCooldown();
  }

  final AuthRepository _repository;
  final String email;

  /// Thời gian chờ giữa hai lần gửi email (test có thể rút ngắn).
  final Duration resendCooldown;

  EmailVerificationState _state = const EmailVerificationState();
  Timer? _timer;
  bool _isDisposed = false;

  EmailVerificationState get state => _state;

  /// Gửi lại email xác nhận rồi đếm ngược lại từ đầu.
  Future<ResendResult> resend() async {
    if (!_state.canResend) return ResendResult.ignored;

    _setState(_state.copyWith(isResending: true));
    try {
      await _repository.resendSignupEmail(email: email);
      _startCooldown();
      return ResendResult.success;
    } on AuthFailure catch (failure) {
      return ResendResult(ResendStatus.failure, failure.message);
    } catch (_) {
      return ResendResult(ResendStatus.failure, AuthFailure.unknown.message);
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

  void _setState(EmailVerificationState next) {
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
