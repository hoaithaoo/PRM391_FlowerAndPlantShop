import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;
import 'package:flutter_test/flutter_test.dart'
    as flutter_test
    show testWidgets;
import 'package:plant_flower_mobile/features/auth/auth.dart';

import '../support/auth_test_harness.dart';

void main() {
  late FakeAuthRepository repo;

  // Repo phải được tạo trong FakeAsync zone của test (không phải ở setUp)
  void testWidgets(
    String description,
    Future<void> Function(WidgetTester tester) body,
  ) {
    flutter_test.testWidgets(description, (tester) async {
      repo = FakeAuthRepository();
      await body(tester);
      unawaited(repo.dispose());
    });
  }

  Future<GlobalKey<NavigatorState>> openGate(
    WidgetTester tester, {
    Size size = kSmallPhone,
  }) async {
    final nav = await pumpAuthApp(tester, repo, size: size);
    await pushRoute(tester, nav, AuthRoutes.gate);
    return nav;
  }

  group('hiển thị', () {
    testWidgets('có đủ nội dung theo thiết kế', (tester) async {
      await openGate(tester);

      expect(find.byType(LoginGateScreen), findsOneWidget);
      expect(find.text('Đăng Nhập Để Tiếp Tục'), findsOneWidget); // header
      expect(find.text('Đăng nhập để tiếp tục'), findsOneWidget); // tiêu đề
      expect(find.text('FLEURÉ STUDIO'), findsOneWidget);
      expect(find.text('ĐẶC QUYỀN HỘI VIÊN FLEURÉ'), findsOneWidget);
      expect(
        find.textContaining('Bạn cần đăng nhập để thêm sản phẩm vào giỏ'),
        findsOneWidget,
      );
      expect(find.text('Tiếp tục với Google'), findsOneWidget);
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.text('Để sau, tôi muốn tiếp tục xem hoa'), findsOneWidget);
      expect(find.textContaining('Bảo mật với Supabase Auth'), findsOneWidget);
      for (final key in [
        'gate_back_button',
        'gate_close_button',
        'gate_google_button',
        'gate_login_button',
        'gate_later_button',
      ]) {
        await tester.ensureVisible(byKey(key));
        expect(byKey(key), findsOneWidget, reason: key);
      }
    });

    testWidgets('đã bỏ avatar, chuông và chia sẻ khỏi header', (tester) async {
      await openGate(tester);

      expect(find.byType(CircleAvatar), findsNothing);
      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
      expect(find.byIcon(Icons.notifications), findsNothing);
      expect(find.byIcon(Icons.notifications_none), findsNothing);
      expect(find.byIcon(Icons.share), findsNothing);
      expect(find.byIcon(Icons.share_outlined), findsNothing);
    });

    for (final size in [kSmallPhone, kPhone]) {
      testWidgets(
        'không overflow ở ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await openGate(tester, size: size);
          expect(tester.takeException(), isNull);
          // Cuộn xuống cuối vẫn không lỗi
          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -2000),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(
            find.textContaining('Bảo mật với Supabase Auth'),
            findsOneWidget,
          );
        },
      );
    }

    testWidgets('không overflow khi chữ phóng to 1.3x', (tester) async {
      final nav = await pumpAuthApp(tester, repo, textScale: 1.3);
      await pushRoute(tester, nav, AuthRoutes.gate);
      expect(tester.takeException(), isNull);
    });
  });

  group('điều hướng', () {
    testWidgets('nút Đăng nhập đẩy màn đăng nhập', (tester) async {
      final nav = await openGate(tester);
      await tapKey(tester, 'gate_login_button');
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Chào mừng bạn'), findsOneWidget);
      // Quay lại (nút back hệ thống) từ màn đăng nhập về lại gate
      nav.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.byType(LoginGateScreen), findsOneWidget);
    });

    for (final key in [
      'gate_back_button',
      'gate_close_button',
      'gate_later_button',
    ]) {
      testWidgets('$key pop về màn trước', (tester) async {
        await openGate(tester);
        await tapKey(tester, key);
        await tester.pumpAndSettle();

        expect(find.byType(LoginGateScreen), findsNothing);
        expect(find.text(kHomeText), findsOneWidget);
      });

      testWidgets('$key không làm gì và không crash khi là route đầu', (
        tester,
      ) async {
        await pumpAuthApp(tester, repo, home: const LoginGateScreen());
        await tapKey(tester, key);
        await tester.pumpAndSettle();

        expect(find.byType(LoginGateScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Google', () {
    testWidgets('bấm gọi signInWithGoogle một lần và hoàn tất đăng nhập', (
      tester,
    ) async {
      await openGate(tester);
      await tapKey(tester, 'gate_google_button');
      await settle(tester);

      expect(repo.count('signInWithGoogle'), 1);
      // Mock phát signedIn=true -> completeAuth: về màn nền + SnackBar chào mừng
      expect(find.byType(LoginGateScreen), findsNothing);
      expect(find.text(kHomeText), findsOneWidget);
      expect(find.text(kLoginSuccessText), findsOneWidget);
    });

    testWidgets('đang loading: hiện vòng xoay và chặn bấm đôi', (tester) async {
      final blocker = repo.block('signInWithGoogle');
      await openGate(tester);

      await tapKey(tester, 'gate_google_button');
      expect(
        find.descendant(
          of: byKey('gate_google_button'),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      await tester.tap(byKey('gate_google_button'));
      await tester.tap(byKey('gate_google_button'));
      await tester.pump();
      expect(repo.count('signInWithGoogle'), 1);

      blocker.complete();
      await settle(tester);
      expect(repo.count('signInWithGoogle'), 1);
    });

    testWidgets('lỗi server hiện SnackBar và nút bấm lại được', (tester) async {
      repo.failWith(
        'signInWithGoogle',
        const AuthFailure(AuthFailureCode.network, 'Mất mạng rồi.'),
      );
      await openGate(tester);
      await tapKey(tester, 'gate_google_button');
      await settle(tester);

      expect(snackText('Mất mạng rồi.'), findsOneWidget);
      expect(find.byType(LoginGateScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('người dùng huỷ (cancelled) thì không báo lỗi', (tester) async {
      repo.failWith(
        'signInWithGoogle',
        const AuthFailure(AuthFailureCode.cancelled, 'Đã huỷ.'),
      );
      await openGate(tester);
      await tapKey(tester, 'gate_google_button');
      await settle(tester);

      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(LoginGateScreen), findsOneWidget);
    });

    testWidgets('lỗi không phải AuthFailure vẫn hiện câu chung, không crash', (
      tester,
    ) async {
      repo.failWith('signInWithGoogle', StateError('boom'));
      await openGate(tester);
      await tapKey(tester, 'gate_google_button');
      await settle(tester);

      expect(
        snackText('Đã có lỗi xảy ra. Vui lòng thử lại sau.'),
        findsOneWidget,
      );
    });

    testWidgets('OAuth quay về (signedInChanges=true) -> completeAuth', (
      tester,
    ) async {
      await openGate(tester);
      repo.emitSignedIn(true);
      await settle(tester);

      expect(find.byType(LoginGateScreen), findsNothing);
      expect(find.text(kHomeText), findsOneWidget);
      expect(find.text(kLoginSuccessText), findsOneWidget);
    });

    testWidgets('signedInChanges=false thì không làm gì', (tester) async {
      await openGate(tester);
      repo.emitSignedIn(false);
      await settle(tester);

      expect(find.byType(LoginGateScreen), findsOneWidget);
    });

    testWidgets('gate nằm dưới màn khác: sự kiện signedIn do màn trên xử lý', (
      tester,
    ) async {
      await openGate(tester);
      await tapKey(tester, 'gate_login_button');
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      repo.emitSignedIn(true);
      await settle(tester);

      // Toàn bộ luồng đóng, SnackBar chỉ hiện một lần (không bị gate bắn đôi)
      expect(find.text(kHomeText), findsOneWidget);
      expect(find.text(kLoginSuccessText), findsOneWidget);
    });
  });

  testWidgets('dispose khi request đang chạy không crash', (tester) async {
    final blocker = repo.block('signInWithGoogle');
    await openGate(tester);
    await tapKey(tester, 'gate_google_button');

    await unmountApp(tester);
    blocker.complete();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
  });
}
