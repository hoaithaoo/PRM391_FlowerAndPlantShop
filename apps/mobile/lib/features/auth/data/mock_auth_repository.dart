import 'dart:async';

import '../models/auth_models.dart';
import 'auth_failure.dart';
import 'auth_repository.dart';

/// Repository giả lập dùng khi chưa cấu hình Supabase (chạy demo) và trong test.
///
/// Quy ước demo:
/// - Mật khẩu [wrongPassword] luôn bị từ chối.
/// - Các tài khoản mẫu hợp lệ được cấu hình sẵn trong [defaultAccounts].
/// - Khi người dùng đăng ký mới qua [signUp], tài khoản sẽ được lưu vào danh sách
///   để có thể đăng nhập bằng mật khẩu vừa đăng ký.
/// - Nhập sai email hoặc sai mật khẩu sẽ ném [AuthFailureCode.invalidCredentials].
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({
    this.delay = const Duration(milliseconds: 600),
    bool initialSignedIn = false,
    Map<String, Set<String>>? initialAccounts,
  })  : _isSignedIn = initialSignedIn,
        _accounts = {
          for (final entry in defaultAccounts.entries)
            entry.key: Set<String>.from(entry.value),
          if (initialAccounts != null)
            for (final entry in initialAccounts.entries)
              entry.key: Set<String>.from(entry.value),
        };

  static const wrongPassword = 'wrong-password';
  static const existingEmail = 'existing@fleure.vn';

  /// Danh sách tài khoản mẫu hợp lệ phục vụ kiểm thử và demo khi không dùng Supabase.
  static final Map<String, Set<String>> defaultAccounts = {
    'khachhang@fleure.vn': {'ValidPass123!', 'Password123!'},
    'user@fleure.vn': {'Password123!'},
    'admin@nhacohoa.vn': {'Admin@123'},
    'existing@fleure.vn': {'Password123!'},
    'name@example.com': {'Hoa@12345', 'a', 'x'},
    'a@b.vn': {'Hoa@12345', 'x', ' pw ', 'p'},
  };

  final Map<String, Set<String>> _accounts;
  final Duration delay;
  final _signedIn = StreamController<bool>.broadcast();
  final _passwordRecovery = StreamController<bool>.broadcast();
  bool _isSignedIn = false;
  bool _isSessionExpired = false;
  String? mockAccessToken = 'mock-valid-access-token';
  bool _isInPasswordRecovery = false;
  bool mockIsProfileComplete = true;
  Map<String, dynamic>? mockMetadata;
  String? mockEmail;

  /// Đăng ký thêm tài khoản hoặc mật khẩu vào mock repository.
  void registerAccount(String email, String password) {
    final normalized = email.trim().toLowerCase();
    _accounts.putIfAbsent(normalized, () => <String>{}).add(password);
  }

  @override
  bool get isSignedIn => _isSignedIn && !_isSessionExpired;

  @override
  String? get accessToken =>
      (_isSignedIn && !_isSessionExpired) ? mockAccessToken : null;

  void simulateSessionExpired() {
    _isSessionExpired = true;
    _signedIn.add(false);
  }

  @override
  Future<bool> refreshSessionIfExpired() async {
    if (!_isSignedIn) return false;
    if (_isSessionExpired) {
      _isSignedIn = false;
      _signedIn.add(false);
      return false;
    }
    return true;
  }

  @override
  bool get isInPasswordRecovery => _isInPasswordRecovery;

  @override
  Stream<bool> get passwordRecoveryChanges => _passwordRecovery.stream;

  void simulatePasswordRecovery() {
    _isInPasswordRecovery = true;
    _passwordRecovery.add(true);
  }

  @override
  bool get isProfileComplete => mockIsProfileComplete;

  @override
  Map<String, dynamic>? get currentUserMetadata =>
      mockMetadata ?? {'full_name': 'Người dùng Google'};

  @override
  String? get currentUserEmail => mockEmail ?? 'google_user@gmail.com';

  @override
  Stream<bool> get signedInChanges => _signedIn.stream;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(delay);
    final normalized = email.trim().toLowerCase();
    if (password == wrongPassword) {
      throw const AuthFailure(
        AuthFailureCode.invalidCredentials,
        'Email hoặc mật khẩu không đúng.',
      );
    }
    final allowedPasswords = _accounts[normalized];
    if (allowedPasswords == null || !allowedPasswords.contains(password)) {
      throw const AuthFailure(
        AuthFailureCode.invalidCredentials,
        'Email hoặc mật khẩu không đúng.',
      );
    }
    mockEmail = normalized;
    _setSignedIn(true);
  }

  @override
  Future<void> signInWithGoogle() async {
    await Future<void>.delayed(delay);
    _setSignedIn(true);
  }

  @override
  Future<void> resendSignupEmail({required String email}) async {
    await Future<void>.delayed(delay);
  }

  /// Giả lập người dùng bấm link xác nhận trong email (test và demo).
  void simulateEmailConfirmed() => _setSignedIn(true);

  @override
  Future<SignUpResult> signUp(RegisterRequest request) async {
    await Future<void>.delayed(delay);
    final normalized = request.email.trim().toLowerCase();
    if (normalized == existingEmail || _accounts.containsKey(normalized)) {
      throw const AuthFailure(
        AuthFailureCode.userAlreadyExists,
        'Email này đã được đăng ký. Vui lòng đăng nhập.',
      );
    }
    _accounts[normalized] = {request.password};
    mockEmail = normalized;
    mockMetadata = {
      'full_name': request.fullName,
      'phone': request.phone,
      'address': request.address,
    };
    return SignUpResult.needsEmailVerification;
  }

  @override
  Future<void> signOut() async {
    _setSignedIn(false);
  }

  @override
  Future<void> completeProfile(CompleteProfileRequest request) async {
    await Future<void>.delayed(delay);
    mockIsProfileComplete = true;
    _setSignedIn(true);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await Future<void>.delayed(delay);
    mockEmail = email.trim().toLowerCase();
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    await Future<void>.delayed(delay);
    if (mockEmail != null) {
      _accounts[mockEmail!] = {newPassword};
    }
    _isInPasswordRecovery = false;
    _passwordRecovery.add(false);
    _setSignedIn(false);
  }

  @override
  Future<void> cancelPasswordRecovery() async {
    _isInPasswordRecovery = false;
    _passwordRecovery.add(false);
    _setSignedIn(false);
  }

  void _setSignedIn(bool value) {
    _isSignedIn = value;
    _isSessionExpired = false;
    _signedIn.add(value);
  }

  Future<void> dispose() async {
    await _signedIn.close();
    await _passwordRecovery.close();
  }
}
