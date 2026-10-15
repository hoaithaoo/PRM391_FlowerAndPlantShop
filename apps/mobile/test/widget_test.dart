import 'package:flutter_test/flutter_test.dart';

import 'package:plant_flower_mobile/features/auth/auth.dart';
import 'package:plant_flower_mobile/main.dart';

void main() {
  setUp(() => AuthFonts.useGoogleFonts = false);

  testWidgets('App mở màn đăng nhập để tiếp tục', (tester) async {
    await tester.pumpWidget(
      PlantFlowerApp(authRepository: MockAuthRepository(delay: Duration.zero)),
    );
    await tester.pump();

    expect(find.byType(LoginGateScreen), findsOneWidget);
  });
}
