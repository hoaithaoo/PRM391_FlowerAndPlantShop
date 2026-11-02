import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/app/app.dart';
import 'package:plant_flower_mobile/app/main_shell.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';
import 'package:plant_flower_mobile/features/chatbot/data/mock_chatbot_repository.dart';
import 'package:plant_flower_mobile/features/checkout/data/mock_checkout_repository.dart';
import 'package:plant_flower_mobile/features/products/data/mock_product_repository.dart';
import 'package:plant_flower_mobile/features/products/screens/home_screen.dart';

import '../support/cart_test_repository.dart';

void main() {
  const phoneSize = Size(390, 844);

  Widget buildApp(AuthRepository authRepository) {
    return PlantFlowerApp(
      authRepository: authRepository,
      productRepository: MockProductRepository(latency: Duration.zero),
      cartRepository: TestCartRepository(),
      chatbotRepository: MockChatbotRepository(),
      checkoutRepository: const MockCheckoutRepository(),
    );
  }

  testWidgets(
    'Chưa đăng nhập: mở app hiển thị LoginScreen và có thể chuyển sang RegisterScreen',
    (tester) async {
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      final authRepo = MockAuthRepository(
        delay: Duration.zero,
        initialSignedIn: false,
      );

      await tester.pumpWidget(buildApp(authRepo));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(MainShell), findsNothing);

      // Chuyển sang trang đăng ký
      await tester.tap(find.byKey(const Key('login_register_link')));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Đăng nhập thành công: AuthSessionGate chuyển thẳng vào Trang chủ (MainShell)',
    (tester) async {
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      final authRepo = MockAuthRepository(
        delay: Duration.zero,
        initialSignedIn: false,
      );

      await tester.pumpWidget(buildApp(authRepo));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);

      // Điền email và mật khẩu
      await tester.enterText(
        find.byKey(const Key('login_identifier_field')),
        'khachhang@fleure.vn',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'ValidPass123!',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      // Đã chuyển sang Trang chủ MainShell
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Session đã hết hạn: app giữ ở LoginScreen và không cho vào Trang chủ',
    (tester) async {
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      final authRepo = MockAuthRepository(
        delay: Duration.zero,
        initialSignedIn: true,
      );
      authRepo.simulateSessionExpired();

      await tester.pumpWidget(buildApp(authRepo));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(MainShell), findsNothing);
    },
  );

  testWidgets(
    'Session còn hạn: mở app vào thẳng Trang chủ mà không cần đăng nhập lại',
    (tester) async {
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      final authRepo = MockAuthRepository(
        delay: Duration.zero,
        initialSignedIn: true,
      );

      await tester.pumpWidget(buildApp(authRepo));
      await tester.pumpAndSettle();

      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    },
  );

  testWidgets(
    'Đang ở Trang chủ nhưng Đăng xuất hoặc Session hết hạn: tự động quay lại LoginScreen',
    (tester) async {
      tester.view.physicalSize = phoneSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      final authRepo = MockAuthRepository(
        delay: Duration.zero,
        initialSignedIn: true,
      );

      await tester.pumpWidget(buildApp(authRepo));
      await tester.pumpAndSettle();

      expect(find.byType(MainShell), findsOneWidget);

      // Mô phỏng hết hạn phiên hoặc đăng xuất
      await authRepo.signOut();
      await tester.pumpAndSettle();

      expect(find.byType(MainShell), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );
}
