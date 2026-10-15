import 'package:flutter/widgets.dart';

import '../data/auth_failure.dart';
import '../data/auth_repository.dart';
import '../utils/auth_validators.dart';
import 'login_state.dart';

/// Điều khiển form đăng nhập: validate, gọi repository, giữ trạng thái loading.
class LoginController extends ChangeNotifier {
  LoginController({required AuthRepository repository})
    : _repository = repository;

  final AuthRepository _repository;

  final identifierController = TextEditingController();
  final passwordController = TextEditingController();

  LoginState _state = const LoginState();
  bool _isDisposed = false;

  // Chỉ hiện lỗi sau lần submit đầu, sau đó cập nhật realtime khi gõ
  bool _identifierTouched = false;
  bool _passwordTouched = false;

  LoginState get state => _state;

  void onIdentifierChanged(String _) {
    if (_identifierTouched) _revalidate();
  }

  void onPasswordChanged(String _) {
    if (_passwordTouched) _revalidate();
  }

  void togglePasswordVisibility() {
    _setState(_state.copyWith(obscurePassword: !_state.obscurePassword));
  }

  /// Đăng nhập bằng email + mật khẩu.
  Future<LoginResult> submit() async {
    if (_state.isBusy) return LoginResult.ignored;
    _identifierTouched = true;
    _passwordTouched = true;
    if (!_revalidate()) return LoginResult.invalid;

    _setState(_state.copyWith(isSubmitting: true));
    try {
      await _repository.signInWithPassword(
        email: identifierController.text.trim(),
        password: passwordController.text,
      );
      return LoginResult.success;
    } on AuthFailure catch (failure) {
      return LoginResult(LoginResultStatus.failure, failure.message);
    } catch (_) {
      return LoginResult.unknown;
    } finally {
      _setState(_state.copyWith(isSubmitting: false));
    }
  }

  /// Link "Đăng nhập OTP": chỉ kiểm tra email rồi gửi mã.
  Future<LoginResult> sendOtp() async {
    if (_state.isBusy) return LoginResult.ignored;
    _identifierTouched = true;
    if (!_revalidate()) return LoginResult.invalid;

    _setState(_state.copyWith(isSendingOtp: true));
    try {
      await _repository.sendLoginOtp(email: identifierController.text.trim());
      return LoginResult.success;
    } on AuthFailure catch (failure) {
      return LoginResult(LoginResultStatus.failure, failure.message);
    } catch (_) {
      return LoginResult.unknown;
    } finally {
      _setState(_state.copyWith(isSendingOtp: false));
    }
  }

  /// Mở trình duyệt Google; phiên đăng nhập đến qua `signedInChanges`.
  Future<LoginResult> signInWithGoogle() async {
    if (_state.isBusy) return LoginResult.ignored;
    _setState(_state.copyWith(isGoogleLoading: true));
    try {
      await _repository.signInWithGoogle();
      return LoginResult.success;
    } on AuthFailure catch (failure) {
      // Người dùng tự đóng trình duyệt thì không cần báo lỗi
      if (failure.code == AuthFailureCode.cancelled) return LoginResult.ignored;
      return LoginResult(LoginResultStatus.failure, failure.message);
    } catch (_) {
      return LoginResult.unknown;
    } finally {
      _setState(_state.copyWith(isGoogleLoading: false));
    }
  }

  /// Tính lại lỗi cho các ô đã được "chạm"; trả về true nếu không có lỗi.
  bool _revalidate() {
    final identifierError = _identifierTouched
        ? AuthValidators.loginIdentifier(identifierController.text)
        : null;
    final passwordError = _passwordTouched
        ? AuthValidators.loginPassword(passwordController.text)
        : null;
    _setState(
      _state.copyWith(
        identifierError: identifierError,
        passwordError: passwordError,
      ),
    );
    return identifierError == null && passwordError == null;
  }

  void _setState(LoginState next) {
    if (_isDisposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
