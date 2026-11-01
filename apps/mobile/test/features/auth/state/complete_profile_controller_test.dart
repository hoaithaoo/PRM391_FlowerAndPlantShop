import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';

import '../support/auth_test_harness.dart';

void main() {
  late FakeAuthRepository repo;
  late CompleteProfileController controller;

  setUp(() {
    repo = FakeAuthRepository();
    repo.currentUserMetadata = {'full_name': 'Nguyễn Văn Google'};
    repo.currentUserEmail = 'google_user@gmail.com';
    controller = CompleteProfileController(repository: repo);
  });

  tearDown(() => controller.dispose());

  group('CompleteProfileController', () {
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
      controller.addressController.text = '123 Đường Hoa Hồng, Phường 1, TP.HCM';
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
      controller.addressController.text = '123 Đường Hoa Hồng, Phường 1, TP.HCM';
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

