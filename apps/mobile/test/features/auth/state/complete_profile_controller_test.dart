import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/core/location/location_service.dart';
import 'package:plant_flower_mobile/core/location/delivery_location.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';

import '../support/auth_test_harness.dart';
import '../support/current_address_test_service.dart';

void main() {
  late FakeAuthRepository repo;
  late CompleteProfileController controller;
  late TestCurrentAddressService addressService;

  setUp(() {
    repo = FakeAuthRepository();
    repo.currentUserMetadata = {'full_name': 'Nguyễn Văn Google'};
    repo.currentUserEmail = 'google_user@gmail.com';
    addressService = TestCurrentAddressService();
    controller = CompleteProfileController(
      repository: repo,
      currentAddressService: addressService,
    );
  });

  tearDown(() => controller.dispose());

  group('CompleteProfileController', () {
    test('tên Google không hợp lệ thì để trống, hợp lệ thì điền sẵn', () {
      expect(controller.fullNameController.text, 'Nguyễn Văn Google');
      final badRepo = FakeAuthRepository()
        ..currentUserMetadata = {'full_name': '03.phamhoangdinh'};
      final bad = CompleteProfileController(repository: badRepo);
      addTearDown(bad.dispose);
      expect(bad.fullNameController.text, isEmpty);
    });

    test('lưu đúng ghim đã chọn và giữ tọa độ khi bổ sung tầng/căn hộ',
        () async {
      controller.phoneController.text = '0912345678';
      controller.selectDeliveryLocation(const DeliveryLocation(
        coordinates: LocationCoordinates(
            latitude: 10.77888, longitude: 106.69999, accuracy: 0),
        address: '123 Đường Hoa, TP. Hồ Chí Minh',
      ));
      controller.addressDetailsController.text = 'Căn hộ 302';
      controller.toggleAgreement();
      await controller.submit();
      expect(repo.lastCompleteProfile?.latitude, 10.77888);
      expect(repo.lastCompleteProfile?.longitude, 106.69999);
      expect(repo.lastCompleteProfile?.address,
          'Căn hộ 302, 123 Đường Hoa, TP. Hồ Chí Minh');
    });

    test('chuyển sang nhập thủ công không gửi ghim cũ cho địa chỉ khác',
        () async {
      controller.selectDeliveryLocation(const DeliveryLocation(
        coordinates: LocationCoordinates(
            latitude: 10.77, longitude: 106.69, accuracy: 0),
        address: '123 Đường Hoa, TP. Hồ Chí Minh',
      ));
      controller.useManualAddress();
      controller.addressController.text = 'Địa chỉ khác, Đà Lạt';
      controller.phoneController.text = '0912345678';
      controller.toggleAgreement();
      await controller.submit();
      expect(repo.lastCompleteProfile?.latitude, isNull);
      expect(repo.lastCompleteProfile?.longitude, isNull);
    });
    test('không tự xin vị trí khi mở màn, chỉ điền địa chỉ khi được yêu cầu',
        () async {
      expect(addressService.calls, 0);
      await controller.useCurrentLocation();
      expect(addressService.calls, 1);
      expect(controller.addressController.text, contains('123 Đường Hoa'));
      expect(controller.state.address, controller.addressController.text);
      expect(controller.state.locationMessage, contains('kiểm tra số nhà'));
      expect(controller.state.isLocating, isFalse);
      expect(repo.calls, isEmpty);
    });

    test('đang định vị thì chặn bấm lặp và gửi form', () async {
      final pending = Completer<String>();
      addressService.resolve = () => pending.future;
      final locating = controller.useCurrentLocation();
      expect(controller.state.isLocating, isTrue);
      await controller.useCurrentLocation();
      expect((await controller.submit()).outcome, CompleteProfileOutcome.busy);
      expect(addressService.calls, 1);
      pending.complete('456 Đường Hoa, TP. Hồ Chí Minh');
      await locating;
      expect(controller.state.isBusy, isFalse);
    });

    test('địa chỉ nhập tay khi GPS đang chờ không bị ghi đè', () async {
      final pending = Completer<String>();
      addressService.resolve = () => pending.future;
      final locating = controller.useCurrentLocation();
      controller.addressController.text = 'Căn hộ 12, địa chỉ tôi vừa nhập';
      pending.complete('Địa chỉ lấy từ GPS');
      await locating;
      expect(controller.state.address, 'Căn hộ 12, địa chỉ tôi vừa nhập');
      expect(controller.state.locationMessage, contains('giữ địa chỉ'));
    });

    test('từ chối quyền giữ địa chỉ cũ và vẫn cho phép nhập tay', () async {
      controller.addressController.text = 'Địa chỉ đã nhập trước đó';
      addressService.resolve =
          () async => throw const LocationException(LocationFailure.denied);
      await controller.useCurrentLocation();
      expect(controller.state.locationFailure, LocationFailure.denied);
      expect(controller.state.locationError, contains('chưa cấp quyền'));
      expect(controller.state.address, 'Địa chỉ đã nhập trước đó');
      expect(controller.state.isLocating, isFalse);
      controller.addressController.text = 'Địa chỉ nhận hàng mới';
      expect(controller.state.locationError, isNull);
    });

    test('quyền bị chặn vĩnh viễn có đường mở cài đặt', () async {
      addressService.resolve = () async =>
          throw const LocationException(LocationFailure.deniedForever);
      await controller.useCurrentLocation();
      expect(controller.state.locationFailure, LocationFailure.deniedForever);
      await controller.openAppSettings();
      expect(addressService.appSettingsCalls, 1);
    });

    test('rời màn khi đang định vị không truy cập text controller đã dispose',
        () async {
      final pending = Completer<String>();
      addressService.resolve = () => pending.future;
      final temporary = CompleteProfileController(
          repository: repo, currentAddressService: addressService);
      final locating = temporary.useCurrentLocation();
      temporary.dispose();
      pending.complete('Địa chỉ đến sau khi rời màn');
      await expectLater(locating, completes);
    });

    test('khởi tạo prefill họ tên và email từ metadata', () {
      expect(controller.fullNameController.text, 'Nguyễn Văn Google');
      expect(controller.state.fullName, 'Nguyễn Văn Google');
      expect(controller.state.email, 'google_user@gmail.com');
      expect(controller.state.showErrors, isFalse);
    });

    test('submit khi form trống: báo invalid và hiển thị lỗi', () async {
      controller.fullNameController.clear();
      final result = await controller.submit();

      expect(result.outcome, CompleteProfileOutcome.invalid);
      expect(controller.state.showErrors, isTrue);
      expect(controller.state.errors.hasAny, isTrue);
      expect(controller.state.errors.fullName, isNotNull);
      expect(controller.state.errors.phone, isNotNull);
      expect(controller.state.errors.address, isNotNull);
      expect(controller.state.errors.agreement, isNotNull);
      expect(repo.calls, isEmpty);
    });

    test('submit khi dữ liệu hợp lệ: gọi completeProfile thành công', () async {
      controller.phoneController.text = '0912345678';
      controller.addressController.text =
          '123 Đường Hoa Hồng, Phường 1, TP.HCM';
      controller.toggleAgreement();

      final result = await controller.submit();

      expect(result.outcome, CompleteProfileOutcome.success);
      expect(repo.calls, ['completeProfile']);
      expect(repo.lastCompleteProfile?.fullName, 'Nguyễn Văn Google');
      expect(repo.lastCompleteProfile?.phone, '0912345678');
      expect(
        repo.lastCompleteProfile?.address,
        '123 Đường Hoa Hồng, Phường 1, TP.HCM',
      );
    });

    test('submit thất bại khi repo ném AuthFailure: hiển thị lỗi', () async {
      controller.phoneController.text = '0912345678';
      controller.addressController.text =
          '123 Đường Hoa Hồng, Phường 1, TP.HCM';
      controller.toggleAgreement();

      repo.failWith(
        'completeProfile',
        const AuthFailure(AuthFailureCode.network, 'Lỗi mạng.'),
      );

      final result = await controller.submit();

      expect(result.outcome, CompleteProfileOutcome.failed);
      expect(result.message, 'Lỗi mạng.');
      expect(controller.state.errorMessage, 'Lỗi mạng.');
    });

    test('signOut gọi signOut trên repository', () async {
      await controller.signOut();
      expect(repo.calls, ['signOut']);
    });
  });
}
