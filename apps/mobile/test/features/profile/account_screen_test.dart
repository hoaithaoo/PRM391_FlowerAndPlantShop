import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';
import 'package:plant_flower_mobile/features/checkout/checkout.dart';
import 'package:plant_flower_mobile/features/profile/data/mock_profile_repository.dart';
import 'package:plant_flower_mobile/features/profile/screens/account_screen.dart';

void main() {
  testWidgets('hiện hồ sơ, email che bớt và đủ mục theo Figma', (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AuthScope(
        repository: MockAuthRepository(),
        child: MaterialApp(
          home: Scaffold(
            body: AccountScreen(
              repository: MockProfileRepository(),
              checkoutRepository: const MockCheckoutRepository(),
              onSignOut: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
    expect(find.text('de***@nhacohoa.vn'), findsOneWidget);
    expect(find.text('0901 234 567'), findsOneWidget);
    expect(find.text('Chờ duyệt'), findsOneWidget);
    expect(find.text('TÀI KHOẢN & MUA HÀNG'), findsOneWidget);
    expect(find.byKey(const Key('account_sign_out')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
