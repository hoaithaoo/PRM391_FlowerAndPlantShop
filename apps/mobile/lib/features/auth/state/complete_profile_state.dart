import '../utils/auth_validators.dart';

/// Kết quả kiểm tra tính hợp lệ của form hoàn thiện thông tin.
class CompleteProfileErrors {
  const CompleteProfileErrors({
    this.fullName,
    this.phone,
    this.address,
    this.agreement,
  });

  final String? fullName;
  final String? phone;
  final String? address;
  final String? agreement;

  bool get hasAny =>
      fullName != null || phone != null || address != null || agreement != null;
}

/// Trạng thái của màn hình Hoàn thiện thông tin tài khoản Google.
class CompleteProfileState {
  const CompleteProfileState({
    this.fullName = '',
    this.phone = '',
    this.address = '',
    this.email = '',
    this.agreed = false,
    this.showErrors = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final String fullName;
  final String phone;
  final String address;
  final String email;
  final bool agreed;
  final bool showErrors;
  final bool isSubmitting;
  final String? errorMessage;

  CompleteProfileErrors get errors {
    return CompleteProfileErrors(
      fullName: AuthValidators.fullName(fullName),
      phone: AuthValidators.phone(phone),
      address: AuthValidators.address(address),
      agreement: AuthValidators.agreement(agreed),
    );
  }

  bool get showErrorLayout => showErrors && errors.hasAny;

  CompleteProfileState copyWith({
    String? fullName,
    String? phone,
    String? address,
    String? email,
    bool? agreed,
    bool? showErrors,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CompleteProfileState(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      email: email ?? this.email,
      agreed: agreed ?? this.agreed,
      showErrors: showErrors ?? this.showErrors,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
