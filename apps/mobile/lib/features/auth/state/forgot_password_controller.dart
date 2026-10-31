import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/auth_failure.dart';
import '../data/auth_repository.dart';
import 'forgot_password_state.dart';

enum ForgotPasswordOutcome {
  busy,
  invalid,
  linkSent,
  resendSuccess,
  failed,
}

class ForgotPasswordResult {
  const ForgotPasswordResult(this.outcome, {this.message});

  final ForgotPasswordOutcome outcome;
  final String? message;
}

/// Điều khiển màn hình Quên mật khẩu, gửi link xác nhận qua email và đếm ngược rate limit.
class ForgotPasswordController extends ChangeNotifier {
  ForgotPasswordController({
    required AuthRepository repository,
    this.initialCooldown = const Duration(seconds: 60),
    this.subsequentCooldown = const Duration(seconds: 30),
  }) : _repository = repository {
    emailController.addListener(_syncText);
  }

  final AuthRepository _repository;
  final Duration initialCooldown;
  final Duration subsequentCooldown;

  final emailController = TextEditingController();

  ForgotPasswordState _state = const ForgotPasswordState();
  Timer? _timer;
  bool _isDisposed = false;

  ForgotPasswordState get state => _state;

  void _syncText() {
    _setState(
      _state.copyWith(
        email: emailController.text,
      ),
    );
  }

  /// Cho phép chỉnh sửa lại email đã nhập.
  void changeEmail() {
    _timer?.cancel();
    _setState(
      _state.copyWith(
        emailSent: false,
        remainingCooldown: Duration.zero,
        showErrors: false,
        clearError: true,
      ),
    );
  }

  /// Gửi link đặt lại mật khẩu về email.
  Future<ForgotPasswordResult> sendResetLink() async {
    if (_state.isBusy) {
      return const ForgotPasswordResult(ForgotPasswordOutcome.busy);
    }

    _setState(_state.copyWith(showErrors: true, clearError: true));
    if (_state.hasErrors) {
      return const ForgotPasswordResult(ForgotPasswordOutcome.invalid);
    }

    _setState(_state.copyWith(isSubmitting: true));
    try {
      final email = _state.email.trim();
      await _repository.sendPasswordResetEmail(email: email);

      _setState(
        _state.copyWith(
          emailSent: true,
          resendCount: 1,
          showErrors: false,
          isSubmitting: false,
        ),
      );
      _startCooldown(initialCooldown);
      return const ForgotPasswordResult(ForgotPasswordOutcome.linkSent);
    } on AuthFailure catch (e) {
      _setState(
        _state.copyWith(isSubmitting: false, generalError: e.message),
      );
      return ForgotPasswordResult(
        ForgotPasswordOutcome.failed,
        message: e.message,
      );
    } catch (_) {
      const msg = 'Đã có lỗi xảy ra. Vui lòng thử lại sau.';
      _setState(_state.copyWith(isSubmitting: false, generalError: msg));
      return const ForgotPasswordResult(
        ForgotPasswordOutcome.failed,
        message: msg,
      );
    }
  }

  /// Gửi lại link: Lần đầu đếm ngược 60s, từ lần 2 trở đi đếm ngược 30s.
  Future<ForgotPasswordResult> resendResetLink() async {
    if (!_state.canResend) {
      return const ForgotPasswordResult(ForgotPasswordOutcome.busy);
    }

    _setState(_state.copyWith(isResending: true, clearError: true));
    try {
      final email = _state.email.trim();
      await _repository.sendPasswordResetEmail(email: email);

      final nextCount = _state.resendCount + 1;
      _setState(
        _state.copyWith(
          isResending: false,
          resendCount: nextCount,
        ),
      );
      _startCooldown(subsequentCooldown);
      return const ForgotPasswordResult(ForgotPasswordOutcome.resendSuccess);
    } on AuthFailure catch (e) {
      _setState(
        _state.copyWith(isResending: false, generalError: e.message),
      );
      return ForgotPasswordResult(
        ForgotPasswordOutcome.failed,
        message: e.message,
      );
    } catch (_) {
      const msg = 'Đã có lỗi xảy ra. Vui lòng thử lại sau.';
      _setState(_state.copyWith(isResending: false, generalError: msg));
      return const ForgotPasswordResult(
        ForgotPasswordOutcome.failed,
        message: msg,
      );
    }
  }

  void _startCooldown(Duration duration) {
    _timer?.cancel();
    _setState(_state.copyWith(remainingCooldown: duration));

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _state.remainingCooldown - const Duration(seconds: 1);
      if (remaining <= Duration.zero) {
        timer.cancel();
        _setState(_state.copyWith(remainingCooldown: Duration.zero));
      } else {
        _setState(_state.copyWith(remainingCooldown: remaining));
      }
    });
  }

  void _setState(ForgotPasswordState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    emailController.dispose();
    super.dispose();
  }
}
