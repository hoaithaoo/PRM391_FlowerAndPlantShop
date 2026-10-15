import 'package:flutter/widgets.dart';

import '../data/auth_failure.dart';
import '../data/auth_repository.dart';
import '../models/auth_models.dart';
import 'register_state.dart';

/// Kết quả của một lần bấm "Đăng ký tài khoản".
enum RegisterOutcome {
  /// Đang gửi yêu cầu trước đó, bỏ qua lần bấm này.
  busy,

  /// Form còn lỗi, màn hình chuyển sang layout lỗi.
  invalid,
  needsEmailVerification,
  signedIn,
  failed,
}

class RegisterSubmitResult {
  const RegisterSubmitResult(this.outcome, {this.email, this.message});

  final RegisterOutcome outcome;

  /// Email đã đăng ký (khi cần xác thực OTP).
  final String? email;

  /// Câu báo lỗi từ server (khi [outcome] là failed).
  final String? message;
}

class RegisterController extends ChangeNotifier {
  RegisterController({required AuthRepository repository})
    : _repository = repository {
    for (final controller in _textControllers.values) {
      controller.addListener(_syncText);
    }
  }

  final AuthRepository _repository;
  final Map<RegisterField, TextEditingController> _textControllers = {
    for (final field in RegisterField.values) field: TextEditingController(),
  };

  RegisterState _state = const RegisterState();
  bool _isDisposed = false;

  RegisterState get state => _state;

  /// Controller dùng chung cho cả layout thường và layout lỗi để giữ nội dung.
  TextEditingController textOf(RegisterField field) => _textControllers[field]!;

  void toggleAgreement() {
    _setState(_state.copyWith(agreed: !_state.agreed));
  }

  void toggleObscurePassword() {
    _setState(_state.copyWith(obscurePassword: !_state.obscurePassword));
  }

  void toggleObscureConfirmPassword() {
    _setState(
      _state.copyWith(obscureConfirmPassword: !_state.obscureConfirmPassword),
    );
  }

  Future<RegisterSubmitResult> submit() async {
    if (_state.isBusy) {
      return const RegisterSubmitResult(RegisterOutcome.busy);
    }
    _setState(_state.copyWith(showErrors: true));
    if (_state.errors.hasAny) {
      return const RegisterSubmitResult(RegisterOutcome.invalid);
    }

    _setState(_state.copyWith(isSubmitting: true));
    try {
      final email = _state.email.trim();
      final result = await _repository.signUp(
        RegisterRequest(
          fullName: _state.fullName.trim(),
          phone: _state.phone.trim(),
          email: email,
          address: _state.address.trim(),
          password: _state.password,
        ),
      );
      return switch (result) {
        SignUpResult.needsEmailVerification => RegisterSubmitResult(
          RegisterOutcome.needsEmailVerification,
          email: email,
        ),
        SignUpResult.signedIn => const RegisterSubmitResult(
          RegisterOutcome.signedIn,
        ),
      };
    } on AuthFailure catch (e) {
      return RegisterSubmitResult(RegisterOutcome.failed, message: e.message);
    } catch (_) {
      // Lỗi không lường trước vẫn phải báo cho người dùng
      return RegisterSubmitResult(
        RegisterOutcome.failed,
        message: AuthFailure.unknown.message,
      );
    } finally {
      _setState(_state.copyWith(isSubmitting: false));
    }
  }

  /// Mở đăng nhập Google. Trả về câu báo lỗi nếu thất bại (null nếu thành công
  /// hoặc người dùng tự hủy); phiên đăng nhập đến qua `signedInChanges`.
  Future<String?> signInWithGoogle() async {
    if (_state.isBusy) return null;
    _setState(_state.copyWith(isGoogleLoading: true));
    try {
      await _repository.signInWithGoogle();
      return null;
    } on AuthFailure catch (e) {
      return e.code == AuthFailureCode.cancelled ? null : e.message;
    } catch (_) {
      return AuthFailure.unknown.message;
    } finally {
      _setState(_state.copyWith(isGoogleLoading: false));
    }
  }

  // Đồng bộ nội dung ô nhập vào state để lỗi cập nhật theo thời gian thực
  void _syncText() {
    String text(RegisterField field) => _textControllers[field]!.text;
    final fullName = text(RegisterField.fullName);
    final phone = text(RegisterField.phone);
    final email = text(RegisterField.email);
    final address = text(RegisterField.address);
    final password = text(RegisterField.password);
    final confirmPassword = text(RegisterField.confirmPassword);
    if (fullName == _state.fullName &&
        phone == _state.phone &&
        email == _state.email &&
        address == _state.address &&
        password == _state.password &&
        confirmPassword == _state.confirmPassword) {
      return;
    }
    _setState(
      _state.copyWith(
        fullName: fullName,
        phone: phone,
        email: email,
        address: address,
        password: password,
        confirmPassword: confirmPassword,
      ),
    );
  }

  void _setState(RegisterState next) {
    if (_isDisposed) return;
    // Hết lỗi thì quay về layout thường; lỗi chỉ hiện lại ở lần submit kế tiếp
    if (next.showErrors && !next.errors.hasAny) {
      next = next.copyWith(showErrors: false);
    }
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    for (final controller in _textControllers.values) {
      controller
        ..removeListener(_syncText)
        ..dispose();
    }
    super.dispose();
  }
}
