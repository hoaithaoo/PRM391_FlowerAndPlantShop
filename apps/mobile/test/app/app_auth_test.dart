import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/app/app.dart';
import 'package:plant_flower_mobile/app/main_shell.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';
import 'package:plant_flower_mobile/features/cart/state/cart_scope.dart';
import 'package:plant_flower_mobile/features/chatbot/data/mock_chatbot_repository.dart';
import 'package:plant_flower_mobile/features/checkout/data/mock_checkout_repository.dart';
import 'package:plant_flower_mobile/features/notifications/data/mock_notification_repository.dart';
import 'package:plant_flower_mobile/features/products/data/mock_product_repository.dart';

import '../support/cart_test_repository.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, AuthRepository auth) async {
    await tester.pumpWidget(
      PlantFlowerApp(
        authRepository: auth,
        productRepository: MockProductRepository(latency: Duration.zero),
        cartRepository: TestCartRepository(),
        chatbotRepository: MockChatbotRepository(),
        checkoutRepository: const MockCheckoutRepository(),
        notificationRepository: MockNotificationRepository(
          delay: Duration.zero,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('signed out: shows login, hides main shell and chatbot', (
    tester,
  ) async {
    await pumpApp(tester, MockAuthRepository(delay: Duration.zero));

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(MainShell), findsNothing);
    expect(find.byKey(const Key('chatbot-launcher')), findsNothing);
  });

  testWidgets('sign in loads the cart, sign out clears it', (tester) async {
    final auth = MockAuthRepository(delay: Duration.zero);
    await pumpApp(tester, auth);

    final signIn = auth.signInWithPassword(email: 'a@b.vn', password: 'secret');
    await tester.pumpAndSettle();
    await signIn;
    await tester.pumpAndSettle();

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byKey(const Key('chatbot-launcher')), findsOneWidget);
    final context = tester.element(find.byType(MainShell));
    final cart = CartScope.of(context);
    expect(cart.totalQuantity, demoCartSnapshot.totalQuantity);

    await tester.tap(find.bySemanticsLabel(MainTab.account.label));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account_sign_out')));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byKey(const Key('chatbot-launcher')), findsNothing);
    expect(cart.totalQuantity, 0);
    expect(cart.isEmpty, isTrue);
  });
}
