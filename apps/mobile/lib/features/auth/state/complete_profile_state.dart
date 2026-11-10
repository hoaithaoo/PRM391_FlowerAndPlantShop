import '../../../core/location/location_service.dart';
import '../../../core/location/delivery_location.dart';
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
    this.addressDetails = '',
    this.selectedLocation,
    this.email = '',
    this.agreed = false,
    this.showErrors = false,
    this.isSubmitting = false,
    this.isLocating = false,
    this.locationError,
    this.locationMessage,
    this.locationFailure,
    this.errorMessage,
  });

  final String fullName;
  final String phone;
  final String address;
  final String addressDetails;
  final DeliveryLocation? selectedLocation;
  final String email;
  final bool agreed;
  final bool showErrors;
  final bool isSubmitting;
  final bool isLocating;
  final String? locationError;
  final String? locationMessage;
  final LocationFailure? locationFailure;
  final String? errorMessage;

  bool get isBusy => isSubmitting || isLocating;

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
    String? addressDetails,
    DeliveryLocation? selectedLocation,
    bool clearSelectedLocation = false,
    String? email,
    bool? agreed,
    bool? showErrors,
    bool? isSubmitting,
    bool? isLocating,
    String? locationError,
    String? locationMessage,
    LocationFailure? locationFailure,
    bool clearLocationFeedback = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CompleteProfileState(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      addressDetails: addressDetails ?? this.addressDetails,
      selectedLocation: clearSelectedLocation
          ? null
          : selectedLocation ?? this.selectedLocation,
      email: email ?? this.email,
      agreed: agreed ?? this.agreed,
      showErrors: showErrors ?? this.showErrors,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLocating: isLocating ?? this.isLocating,
      locationError:
          clearLocationFeedback ? null : locationError ?? this.locationError,
      locationMessage: clearLocationFeedback
          ? null
          : locationMessage ?? this.locationMessage,
      locationFailure: clearLocationFeedback
          ? null
          : locationFailure ?? this.locationFailure,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
