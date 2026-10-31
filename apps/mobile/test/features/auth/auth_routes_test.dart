import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';

import 'support/auth_test_harness.dart';

void main() {
  test('tên route', () {
    expect(AuthRoutes.login, '/auth/login');
    expect(AuthRoutes.register, '/auth/register');
    expect(AuthRoutes.verifyEmail, '/auth/verify-email');
    expect(AuthRoutes.forgotPassword, '/auth/forgot-password');
    expect(AuthRoutes.completeProfile, '/auth/complete-profile');
    expect(AuthRoutes.resetPassword, '/auth/reset-password');
  });

  group('onGenerateRoute', () {
    for (final name in [
      AuthRoutes.login,
      AuthRoutes.register,
      AuthRoutes.forgotPassword,
      AuthRoutes.completeProfile,
      AuthRoutes.resetPassword,
    ]) {
      test('trả MaterialPageRoute cho $name', () {
        final route = AuthRoutes.onGenerateRoute(RouteSettings(name: name));
        expect(route, isA<MaterialPageRoute<void>>());
        expect(route!.settings.name, name);
      });
    }

    test('verifyEmail có arguments String -> route giữ nguyên settings', () {
      const settings = RouteSettings(
        name: AuthRoutes.verifyEmail,
        arguments: 'a@b.vn',
      );
      final route = AuthRoutes.onGenerateRoute(settings);
      expect(route, isA<MaterialPageRoute<void>>());
      expect(route!.settings.name, AuthRoutes.verifyEmail);
      expect(route.settings.arguments, 'a@b.vn');
    });

    testWidgets('verifyEmail dựng EmailVerificationScreen đúng email', (
      tester,
    ) async {
      final repo = FakeAuthRepository();
      addTearDown(repo.dispose);
      final nav = await pumpAuthApp(tester, repo);
      await pushRoute(
        tester,
        nav,
        AuthRoutes.verifyEmail,
        arguments: 'phuongha@gmail.com',
      );

      final screen = tester.widget<EmailVerificationScreen>(
        find.byType(EmailVerificationScreen),
      );
      expect(screen.email, 'phuongha@gmail.com');
      await unmountApp(tester);
    });

    test('verifyEmail thiếu arguments -> null', () {
      expect(
        AuthRoutes.onGenerateRoute(
          const RouteSettings(name: AuthRoutes.verifyEmail),
        ),
        isNull,
      );
    });

    test('verifyEmail với arguments sai kiểu -> null', () {
      for (final args in <Object>[
        42,
        true,
        <String>['a@b.vn'],
        Object(),
      ]) {
        expect(
          AuthRoutes.onGenerateRoute(
            RouteSettings(name: AuthRoutes.verifyEmail, arguments: args),
          ),
          isNull,
          reason: 'arguments: $args',
        );
      }
    });

    test('tên route lạ hoặc null -> null (kể cả route gate/otp cũ)', () {
      for (final name in [
        '/khong-co',
        '/auth/login/',
        '/auth',
        '/auth/otp',
        '/AUTH/LOGIN',
      ]) {
        expect(
          AuthRoutes.onGenerateRoute(RouteSettings(name: name)),
          isNull,
          reason: name,
        );
      }
      expect(AuthRoutes.onGenerateRoute(const RouteSettings()), isNull);
    });
  });

  group('openVerifyEmail', () {
    testWidgets('đẩy route verify-email kèm email làm arguments', (
      tester,
    ) async {
      final repo = FakeAuthRepository();
      addTearDown(repo.dispose);
      final nav = await pumpAuthApp(tester, repo);

      unawaited(AuthRoutes.openVerifyEmail(nav.currentContext!, 'x@y.vn'));
      await tester.pumpAndSettle();

      expect(find.byType(EmailVerificationScreen), findsOneWidget);
      expect(byKey('verify_email_address'), findsOneWidget);
      expect(tester.widget<Text>(byKey('verify_email_address')).data, 'x@y.vn');
      await unmountApp(tester);
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
      expect(find.text(kLoginSuccessText), findsOneWidget);
    });
  });
}
