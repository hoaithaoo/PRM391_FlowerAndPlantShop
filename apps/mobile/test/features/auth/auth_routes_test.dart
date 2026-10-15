import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';

void main() {
  test('tên route', () {
    expect(AuthRoutes.gate, '/auth');
    expect(AuthRoutes.login, '/auth/login');
    expect(AuthRoutes.register, '/auth/register');
    expect(AuthRoutes.otp, '/auth/otp');
  });

  group('onGenerateRoute', () {
    for (final name in [
      AuthRoutes.gate,
      AuthRoutes.login,
      AuthRoutes.register,
    ]) {
      test('trả MaterialPageRoute cho $name', () {
        final route = AuthRoutes.onGenerateRoute(RouteSettings(name: name));
        expect(route, isA<MaterialPageRoute<void>>());
        expect(route!.settings.name, name);
      });
    }

    test('trả route OTP khi có OtpArgs', () {
      const args = OtpArgs(email: 'a@b.vn', purpose: OtpPurpose.signup);
      final route = AuthRoutes.onGenerateRoute(
        const RouteSettings(name: AuthRoutes.otp, arguments: args),
      );
      expect(route, isA<MaterialPageRoute<void>>());
      expect(route!.settings.name, AuthRoutes.otp);
      expect(route.settings.arguments, same(args));
    });

    test('OTP thiếu args -> null', () {
      expect(
        AuthRoutes.onGenerateRoute(const RouteSettings(name: AuthRoutes.otp)),
        isNull,
      );
    });

    test('OTP với args sai kiểu -> null', () {
      expect(
        AuthRoutes.onGenerateRoute(
          const RouteSettings(name: AuthRoutes.otp, arguments: 'a@b.vn'),
        ),
        isNull,
      );
    });

    test('tên route lạ hoặc null -> null', () {
      expect(
        AuthRoutes.onGenerateRoute(const RouteSettings(name: '/khong-co')),
        isNull,
      );
      expect(
        AuthRoutes.onGenerateRoute(const RouteSettings(name: '/auth/login/')),
        isNull,
      );
      expect(AuthRoutes.onGenerateRoute(const RouteSettings()), isNull);
    });
  });

  group('completeAuth', () {
    testWidgets('đóng toàn bộ luồng về route đầu và hiện SnackBar', (
      tester,
    ) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Text('home')),
        ),
      );
      navigatorKey.currentState!
        ..push(MaterialPageRoute<void>(builder: (_) => const Text('a')))
        ..push(MaterialPageRoute<void>(builder: (_) => const Text('b')));
      await tester.pumpAndSettle();
      expect(find.text('b'), findsOneWidget);

      AuthRoutes.completeAuth(navigatorKey.currentContext!);
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      expect(find.text('b'), findsNothing);
      expect(
        find.text('Đăng nhập thành công. Chào mừng bạn đến Fleuré!'),
        findsOneWidget,
      );
    });
  });
}
