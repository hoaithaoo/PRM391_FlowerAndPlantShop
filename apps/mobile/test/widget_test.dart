import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';
import 'package:plant_flower_mobile/main.dart';

void main() {
  setUp(() => AuthFonts.useGoogleFonts = false);

  testWidgets('App mở thẳng màn Đăng nhập khi chưa có phiên', (tester) async {
    final repository = MockAuthRepository(delay: Duration.zero);
    addTearDown(repository.dispose);
    await tester.pumpWidget(PlantFlowerApp(authRepository: repository));
    await tester.pump();

    expect(find.byType(AuthSessionGate), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SignedInPlaceholder), findsNothing);
  });
}
