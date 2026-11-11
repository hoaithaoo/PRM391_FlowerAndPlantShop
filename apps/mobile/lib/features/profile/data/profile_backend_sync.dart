import 'package:plant_flower_api_client/plant_flower_api_client.dart';

import '../../auth/data/address_geocoder.dart';
import '../../auth/data/auth_failure.dart';
import '../../auth/models/auth_models.dart';
import '../../checkout/data/checkout_repository.dart';
import '../../checkout/models/checkout_flow_models.dart';
import 'profile_repository.dart';

/// Sau màn "Hoàn thiện thông tin": ghi họ tên, số điện thoại vào hồ sơ backend
/// và thêm địa chỉ giao hàng vào Sổ địa chỉ (bỏ qua nếu đã có địa chỉ y hệt,
/// để bấm lưu lại sau lỗi không tạo bản trùng).
class ProfileBackendSyncer {
  ProfileBackendSyncer({
    required ProfileRepository profileRepository,
    required CheckoutRepository checkoutRepository,
  }) : _profiles = profileRepository,
       _addresses = checkoutRepository;

  final ProfileRepository _profiles;
  final CheckoutRepository _addresses;

  Future<void> call(CompleteProfileRequest request, GeoPoint? point) async {
    final fullName = request.fullName.trim();
    final phone = request.phone.replaceAll(RegExp(r'[^\d+]'), '');
    final address = request.address.trim();
    try {
      await _profiles.updateProfile(fullName: fullName, phone: phone);
      final existing = await _addresses.listAddresses();
      if (existing.any((item) => item.fullAddress.trim() == address)) return;
      await _addresses.saveAddress(
        CheckoutAddress(
          id: newAddressId,
          label: 'Nhà riêng',
          recipientName: fullName,
          phone: phone,
          addressLine: address,
          ward: '',
          district: '',
          city: '',
          isDefault: existing.isEmpty,
          latitude: point?.latitude,
          longitude: point?.longitude,
        ),
      );
    } on ApiException catch (error) {
      throw AuthFailure(
        error.code == ApiException.networkErrorCode
            ? AuthFailureCode.network
            : AuthFailureCode.unknown,
        'Chưa lưu được hồ sơ: ${error.message}',
      );
    }
  }
}
