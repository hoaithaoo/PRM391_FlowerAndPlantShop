import 'package:flutter/widgets.dart';

import '../data/auth_failure.dart';
import '../data/auth_repository.dart';
import '../models/auth_models.dart';
import 'complete_profile_state.dart';

enum CompleteProfileOutcome {
  busy,
  invalid,
  success,
  failed,
}

class CompleteProfileSubmitResult {
  const CompleteProfileSubmitResult(this.outcome, {this.message});

  final CompleteProfileOutcome outcome;
  final String? message;
}

/// Điều khiển màn hoàn thiện thông tin còn thiếu sau khi đăng nhập Google.
class CompleteProfileController extends ChangeNotifier {
  CompleteProfileController({required AuthRepository repository})
    : _repository = repository {
    final meta = repository.currentUserMetadata ?? {};
    final initialName =
        (meta['full_name'] as String?) ??
        (meta['name'] as String?) ??
        '';
    final initialEmail =
        repository.currentUserEmail ??
        (meta['email'] as String?) ??
        '';

    fullNameController.text = initialName;
    _state = CompleteProfileState(
      fullName: initialName,
      email: initialEmail,
    );

    fullNameController.addListener(_syncText);
    phoneController.addListener(_syncText);
    addressController.addListener(_syncText);
  }

  final AuthRepository _repository;
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  CompleteProfileState _state = const CompleteProfileState();
  bool _isDisposed = false;

  CompleteProfileState get state => _state;

  void _syncText() {
    _setState(
      _state.copyWith(
        fullName: fullNameController.text,
        phone: phoneController.text,
        address: addressController.text,
      ),
    );
  }

  void toggleAgreement() {
    _setState(_state.copyWith(agreed: !_state.agreed));
  }

  Future<CompleteProfileSubmitResult> submit() async {
    if (_state.isSubmitting) {
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
          address: _state.address.trim(),
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
    fullNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }
}
