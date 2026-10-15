import 'package:flutter/foundation.dart';

import '../data/auth_failure.dart';
import '../data/auth_repository.dart';
import 'login_state.dart';

/// Điều khiển nút Google của màn "Đăng nhập để tiếp tục".
class LoginGateController extends ChangeNotifier {
  LoginGateController({required AuthRepository repository})
    : _repository = repository;

  final AuthRepository _repository;

  bool _isGoogleLoading = false;
  bool _isDisposed = false;

  bool get isGoogleLoading => _isGoogleLoading;

  Future<LoginResult> signInWithGoogle() async {
    if (_isGoogleLoading) return LoginResult.ignored;
    _setLoading(true);
    try {
      await _repository.signInWithGoogle();
      return LoginResult.success;
    } on AuthFailure catch (failure) {
      if (failure.code == AuthFailureCode.cancelled) return LoginResult.ignored;
      return LoginResult(LoginResultStatus.failure, failure.message);
    } catch (_) {
      return LoginResult.unknown;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (_isDisposed) return;
    _isGoogleLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
