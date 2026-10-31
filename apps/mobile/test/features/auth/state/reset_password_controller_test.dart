import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';

import '../support/auth_test_harness.dart';

void main() {
  late FakeAuthRepository repo;
  late ResetPasswordController controller;

  setUp(() {
    repo = FakeAuthRepository();
    controller = ResetPasswordController(repository: repo);
  });

  tearDown(() => controller.dispose());

  group('ResetPasswordController', () {
    test('mật khẩu yếu hoặc xác nhận không khớp: invalid và hiện lỗi', () async {
      controller.newPasswordController.text = '123';
      controller.confirmPasswordController.text = '456';

      final result = await controller.submit();

      expect(result.outcome, ResetPasswordOutcome.invalid);
      expect(controller.state.showErrors, isTrue);
      expect(controller.state.newPasswordError, isNotNull);
      expect(controller.state.confirmPasswordError, isNotNull);
      expect(repo.calls, isEmpty);
    });

    test('toggle obscure thay đổi trạng thái ẩn hiện mật khẩu', () {
      expect(controller.state.obscureNewPassword, isTrue);
      controller.toggleObscureNewPassword();
      expect(controller.state.obscureNewPassword, isFalse);

      expect(controller.state.obscureConfirmPassword, isTrue);
      controller.toggleObscureConfirmPassword();
      expect(controller.state.obscureConfirmPassword, isFalse);
    });

    test('mật khẩu hợp lệ: gọi updatePassword thành công', () async {
      controller.newPasswordController.text = 'Hoa@12345';
      controller.confirmPasswordController.text = 'Hoa@12345';

      final result = await controller.submit();

      expect(result.outcome, ResetPasswordOutcome.success);
      expect(repo.calls, ['updatePassword']);
      expect(repo.lastNewPassword, 'Hoa@12345');
    });

    test('lỗi mạng khi đổi mật khẩu: hiển thị generalError', () async {
      controller.newPasswordController.text = 'Hoa@12345';
      controller.confirmPasswordController.text = 'Hoa@12345';
      repo.failWith(
        'updatePassword',
        const AuthFailure(AuthFailureCode.network, 'Lỗi mạng.'),
      );

      final result = await controller.submit();

      expect(result.outcome, ResetPasswordOutcome.failed);
      expect(controller.state.generalError, 'Lỗi mạng.');
    });

    test('cancel gọi cancelPasswordRecovery', () async {
      await controller.cancel();
      expect(repo.calls, ['cancelPasswordRecovery']);
    });
  });
}

