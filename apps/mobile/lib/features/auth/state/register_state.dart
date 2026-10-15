import '../utils/auth_validators.dart';

/// Các ô nhập (không gồm checkbox) trên form đăng ký.
enum RegisterField {
  fullName('full_name'),
  phone('phone'),
  email('email'),
  address('address'),
  password('password'),
  confirmPassword('confirm_password');

  const RegisterField(this.keyName);

  /// Hậu tố dùng đặt `Key` (ví dụ `register_<keyName>_field`).
  final String keyName;
}

/// Kết quả kiểm tra toàn bộ form; `null` nghĩa là ô đó hợp lệ.
class RegisterErrors {
  const RegisterErrors({
    this.fullName,
    this.phone,
    this.email,
    this.address,
    this.password,
    this.confirmPassword,
    this.agreement,
  });

  final String? fullName;
  final String? phone;
  final String? email;
  final String? address;
  final String? password;
  final String? confirmPassword;
  final String? agreement;

  String? of(RegisterField field) {
    return switch (field) {
      RegisterField.fullName => fullName,
      RegisterField.phone => phone,
      RegisterField.email => email,
      RegisterField.address => address,
      RegisterField.password => password,
      RegisterField.confirmPassword => confirmPassword,
    };
  }

  /// Số mục cần chỉnh, tính cả checkbox đồng ý điều khoản.
  int get count {
    return [
      fullName,
      phone,
      email,
      address,
      password,
      confirmPassword,
      agreement,
    ].where((message) => message != null).length;
  }

  bool get hasAny => count > 0;
}

/// Trạng thái bất biến của màn đăng ký. Nội dung ô nhập nằm ở
/// `TextEditingController`, ở đây chỉ giữ bản sao để kiểm tra.
class RegisterState {
  const RegisterState({
    this.fullName = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.password = '',
    this.confirmPassword = '',
    this.agreed = false,
    this.showErrors = false,
    this.isSubmitting = false,
    this.isGoogleLoading = false,
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
  });

  final String fullName;
  final String phone;
  final String email;
  final String address;
  final String password;
  final String confirmPassword;
  final bool agreed;

  /// Đã bấm "Đăng ký tài khoản" ít nhất một lần.
  final bool showErrors;
  final bool isSubmitting;
  final bool isGoogleLoading;
  final bool obscurePassword;
  final bool obscureConfirmPassword;

  RegisterErrors get errors {
    return RegisterErrors(
      fullName: AuthValidators.fullName(fullName),
      phone: AuthValidators.phone(phone),
      email: AuthValidators.email(email),
      address: AuthValidators.address(address),
      password: AuthValidators.password(password),
      confirmPassword: AuthValidators.confirmPassword(
        confirmPassword,
        password,
      ),
      agreement: AuthValidators.agreement(agreed),
    );
  }

  /// Chỉ hiện layout lỗi (Màn 4) khi đã submit và còn ít nhất một lỗi.
  bool get showErrorLayout => showErrors && errors.hasAny;

  bool get isBusy => isSubmitting || isGoogleLoading;

  RegisterState copyWith({
    String? fullName,
    String? phone,
    String? email,
    String? address,
    String? password,
    String? confirmPassword,
    bool? agreed,
    bool? showErrors,
    bool? isSubmitting,
    bool? isGoogleLoading,
    bool? obscurePassword,
    bool? obscureConfirmPassword,
  }) {
    return RegisterState(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      agreed: agreed ?? this.agreed,
      showErrors: showErrors ?? this.showErrors,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isGoogleLoading: isGoogleLoading ?? this.isGoogleLoading,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
    );
  }
}
