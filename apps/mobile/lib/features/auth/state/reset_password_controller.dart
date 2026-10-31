import 'package:flutter/widgets.dart';

import '../data/auth_failure.dart';
import '../data/auth_repository.dart';
import 'reset_password_state.dart';

enum ResetPasswordOutcome {
  busy,
  invalid,
  success,
  failed,
}

class ResetPasswordResult {
  const ResetPasswordResult(this.outcome, {this.message});

  final ResetPasswordOutcome outcome;
  final String? message;
}

/// Điều khiển màn hình Đổi mật khẩu mới sau khi vào app từ Recovery Link.
class ResetPasswordController extends ChangeNotifier {
  ResetPasswordController({
    required AuthRepository repository,
  }) : _repository = repository {
    newPasswordController.addListener(_syncText);
    confirmPasswordController.addListener(_syncText);
  }

  final AuthRepository _repository;

  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  ResetPasswordState _state = const ResetPasswordState();
  bool _isDisposed = false;

  ResetPasswordState get state => _state;

  void _syncText() {
    _setState(
      _state.copyWith(
        newPassword: newPasswordController.text,
        confirmPassword: confirmPasswordController.text,
      ),
    );
  }

  void toggleObscureNewPassword() {
    _setState(_state.copyWith(obscureNewPassword: !_state.obscureNewPassword));
  }

  void toggleObscureConfirmPassword() {
    _setState(
      _state.copyWith(
        obscureConfirmPassword: !_state.obscureConfirmPassword,
      ),
    );
  }

  Future<ResetPasswordResult> submit() async {
    if (_state.isSubmitting) {
      return const ResetPasswordResult(ResetPasswordOutcome.busy);
    }

    _setState(_state.copyWith(showErrors: true, clearError: true));
    if (_state.hasErrors) {
      return const ResetPasswordResult(ResetPasswordOutcome.invalid);
    }

    _setState(_state.copyWith(isSubmitting: true));
    try {
      await _repository.updatePassword(
        newPassword: _state.newPassword,
      );
      _setState(_state.copyWith(isSubmitting: false));
      return const ResetPasswordResult(ResetPasswordOutcome.success);
    } on AuthFailure catch (e) {
      _setState(
        _state.copyWith(isSubmitting: false, generalError: e.message),
      );
      return ResetPasswordResult(
        ResetPasswordOutcome.failed,
        message: e.message,
      );
    } catch (_) {
      const msg = 'Đã có lỗi xảy ra. Vui lòng thử lại sau.';
      _setState(_state.copyWith(isSubmitting: false, generalError: msg));
      return const ResetPasswordResult(
        ResetPasswordOutcome.failed,
        message: msg,
      );
    }
  }

  Future<void> cancel() async {
    await _repository.cancelPasswordRecovery();
  }

  void _setState(ResetPasswordState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}

