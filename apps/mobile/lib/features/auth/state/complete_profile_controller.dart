import 'package:flutter/widgets.dart';

import '../../../core/location/current_address_service.dart';
import '../../../core/location/delivery_location.dart';
import '../../../core/location/location_service.dart';
import '../data/auth_failure.dart';
import '../data/auth_repository.dart';
import '../models/auth_models.dart';
import '../utils/auth_validators.dart';
import 'complete_profile_state.dart';

enum CompleteProfileOutcome { busy, invalid, success, failed }

class CompleteProfileSubmitResult {
  const CompleteProfileSubmitResult(this.outcome, {this.message});

  final CompleteProfileOutcome outcome;
  final String? message;
}

/// Điều khiển màn hoàn thiện thông tin còn thiếu sau khi đăng nhập Google.
class CompleteProfileController extends ChangeNotifier {
  CompleteProfileController({
    required AuthRepository repository,
    CurrentAddressService currentAddressService = const CurrentAddressService(),
  })  : _repository = repository,
        _currentAddressService = currentAddressService {
    final meta = repository.currentUserMetadata ?? {};
    final googleName =
        ((meta['full_name'] as String?) ?? (meta['name'] as String?) ?? '')
            .trim();
    // Tên Google kiểu "03.phamhoangdinh" không hợp lệ: để trống cho người dùng
    // tự nhập thay vì điền sẵn rồi báo lỗi.
    final initialName =
        AuthValidators.fullName(googleName) == null ? googleName : '';
    final initialEmail =
        repository.currentUserEmail ?? (meta['email'] as String?) ?? '';

    fullNameController.text = initialName;
    _state = CompleteProfileState(fullName: initialName, email: initialEmail);

    fullNameController.addListener(_syncText);
    phoneController.addListener(_syncText);
    addressController.addListener(_syncText);
    addressDetailsController.addListener(_syncText);
  }

  final AuthRepository _repository;
  final CurrentAddressService _currentAddressService;
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final addressDetailsController = TextEditingController();

  CompleteProfileState _state = const CompleteProfileState();
  bool _isDisposed = false;

  CompleteProfileState get state => _state;

  void _syncText() {
    _setState(
      _state.copyWith(
        fullName: fullNameController.text,
        phone: phoneController.text,
        address: addressController.text,
        addressDetails: addressDetailsController.text,
        clearSelectedLocation: addressController.text != _state.address,
        clearLocationFeedback: addressController.text != _state.address,
      ),
    );
  }

  void toggleAgreement() {
    _setState(_state.copyWith(agreed: !_state.agreed));
  }

  void selectDeliveryLocation(DeliveryLocation location) {
    if (_isDisposed ||
        _state.isBusy ||
        !location.coordinates.isValid ||
        location.address.trim().isEmpty) {
      return;
    }
    addressController.text = location.address;
    _setState(
      _state.copyWith(selectedLocation: location, clearLocationFeedback: true),
    );
  }

  void useManualAddress() {
    if (!_state.isBusy) _setState(_state.copyWith(clearSelectedLocation: true));
  }

  bool get supportsLocationSettings => _currentAddressService.supportsSettings;

  Future<bool> openAppSettings() => _currentAddressService.openAppSettings();

  Future<bool> openLocationSettings() =>
      _currentAddressService.openLocationSettings();

  Future<void> useCurrentLocation() async {
    if (_isDisposed || _state.isBusy) return;
    final previousAddress = addressController.text;
    _setState(_state.copyWith(isLocating: true, clearLocationFeedback: true));
    try {
      final address = await _currentAddressService.getCurrentAddress();
      if (_isDisposed) return;
      // Người dùng có thể đang nhập tay trong lúc GPS hoặc mạng còn chờ.
      if (addressController.text != previousAddress) {
        _setState(
          _state.copyWith(locationMessage: 'Đã giữ địa chỉ bạn vừa nhập.'),
        );
        return;
      }
      addressController.text = address;
      _setState(
        _state.copyWith(
          locationMessage:
              'Đã điền địa chỉ gần vị trí của bạn. Hãy kiểm tra số nhà trước khi lưu.',
        ),
      );
    } on LocationException catch (error) {
      _setState(
        _state.copyWith(
          locationError:
              '${error.failure.message} Bạn vẫn có thể nhập địa chỉ bên dưới.',
          locationFailure: error.failure,
        ),
      );
    } on AddressLookupException catch (error) {
      _setState(_state.copyWith(locationError: error.message));
    } catch (_) {
      _setState(
        _state.copyWith(
          locationError:
              'Chưa lấy được địa chỉ hiện tại. Bạn có thể thử lại hoặc nhập địa chỉ bên dưới.',
        ),
      );
    } finally {
      _setState(_state.copyWith(isLocating: false));
    }
  }

  Future<CompleteProfileSubmitResult> submit() async {
    if (_state.isBusy || _isDisposed) {
      return const CompleteProfileSubmitResult(CompleteProfileOutcome.busy);
    }

    _setState(_state.copyWith(showErrors: true, clearError: true));
    if (_state.errors.hasAny) {
      return const CompleteProfileSubmitResult(CompleteProfileOutcome.invalid);
    }

    _setState(_state.copyWith(isSubmitting: true));
    try {
      await _repository.completeProfile(
        CompleteProfileRequest(
          fullName: _state.fullName.trim(),
          phone: _state.phone.trim(),
          address: [
            if (_state.addressDetails.trim().isNotEmpty)
              _state.addressDetails.trim(),
            _state.address.trim(),
          ].join(', '),
          latitude: _state.selectedLocation?.coordinates.latitude,
          longitude: _state.selectedLocation?.coordinates.longitude,
        ),
      );
      return const CompleteProfileSubmitResult(CompleteProfileOutcome.success);
    } on AuthFailure catch (e) {
      _setState(_state.copyWith(errorMessage: e.message));
      return CompleteProfileSubmitResult(
        CompleteProfileOutcome.failed,
        message: e.message,
      );
    } catch (_) {
      const msg = 'Đã có lỗi xảy ra. Vui lòng thử lại sau.';
      _setState(_state.copyWith(errorMessage: msg));
      return const CompleteProfileSubmitResult(
        CompleteProfileOutcome.failed,
        message: msg,
      );
    } finally {
      _setState(_state.copyWith(isSubmitting: false));
    }
  }

  Future<void> signOut() => _repository.signOut();

  void _setState(CompleteProfileState next) {
    if (_isDisposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    fullNameController.removeListener(_syncText);
    phoneController.removeListener(_syncText);
    addressController.removeListener(_syncText);
    addressDetailsController.removeListener(_syncText);
    fullNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    addressDetailsController.dispose();
    super.dispose();
  }
}
