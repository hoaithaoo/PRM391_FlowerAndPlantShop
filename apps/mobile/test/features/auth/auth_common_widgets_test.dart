import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/utils/auth_theme.dart';
import 'package:plant_flower_mobile/features/auth/widgets/auth_common.dart';

Widget _host(Widget child) {
  return MaterialApp(
    theme: AuthTheme.data(ThemeData(useMaterial3: true)),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  setUp(() => AuthFonts.useGoogleFonts = false);

  group('AuthPrimaryButton', () {
    testWidgets('tap gọi callback', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(AuthPrimaryButton(label: 'Đăng nhập', onPressed: () => taps++)),
      );

      expect(find.text('Đăng nhập'), findsOneWidget);
      await tester.tap(find.byType(AuthPrimaryButton));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('isLoading hiện vòng xoay, ẩn nhãn và không gọi callback', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          AuthPrimaryButton(
            label: 'Đăng nhập',
            isLoading: true,
            onPressed: () => taps++,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Đăng nhập'), findsNothing);
      await tester.tap(find.byType(AuthPrimaryButton));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('không loading thì không có vòng xoay', (tester) async {
      await tester.pumpWidget(
        _host(AuthPrimaryButton(label: 'OK', onPressed: () {})),
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('onPressed null: không tap được và mờ đi', (tester) async {
      await tester.pumpWidget(
        _host(const AuthPrimaryButton(label: 'Xác nhận', onPressed: null)),
      );

      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(AuthPrimaryButton),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0.6);
      expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
      // Tap vào nút bị vô hiệu không ném lỗi
      await tester.tap(find.byType(AuthPrimaryButton), warnIfMissed: false);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('hiện icon đầu/cuối khi được cấu hình', (tester) async {
      await tester.pumpWidget(
        _host(
          AuthPrimaryButton(
            label: 'Đăng ký tài khoản',
            onPressed: () {},
            leadingIcon: Icons.mail_outline,
            trailingIcon: Icons.arrow_forward,
          ),
        ),
      );
      expect(find.byIcon(Icons.mail_outline), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });
  });

  group('AuthGoogleButton', () {
    testWidgets('tap gọi callback; loading thì không', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          AuthGoogleButton(
            label: 'Tiếp tục với Google',
            onPressed: () => taps++,
          ),
        ),
      );
      await tester.tap(find.byType(AuthGoogleButton));
      expect(taps, 1);

      await tester.pumpWidget(
        _host(
          AuthGoogleButton(
            label: 'Tiếp tục với Google',
            isLoading: true,
            onPressed: () => taps++,
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(AuthGoogleButton));
      expect(taps, 1);
    });
  });

  group('AuthTextField', () {
    testWidgets('nhập text cập nhật controller và gọi onChanged', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      String? lastChanged;
      await tester.pumpWidget(
        _host(
          AuthTextField(
            controller: controller,
            hintText: 'Nhập email',
            onChanged: (v) => lastChanged = v,
          ),
        ),
      );

      expect(find.text('Nhập email'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'name@example.com');
      expect(controller.text, 'name@example.com');
      expect(lastChanged, 'name@example.com');
    });

    testWidgets('onSubmitted được gọi khi nhấn done', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      String? submitted;
      await tester.pumpWidget(
        _host(
          AuthTextField(
            controller: controller,
            hintText: 'x',
            onSubmitted: (v) => submitted = v,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(submitted, 'abc');
    });

    BoxDecoration decorationOf(WidgetTester tester) {
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(AuthTextField),
              matching: find.byType(Container),
            )
            .first,
      );
      return container.decoration! as BoxDecoration;
    }

    testWidgets('status error có viền 2px màu AuthPalette.error', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          AuthTextField(
            controller: controller,
            hintText: 'x',
            status: AuthFieldStatus.error,
          ),
        ),
      );
      final border = decorationOf(tester).border! as Border;
      expect(border.top.color, AuthPalette.error);
      expect(border.top.width, 2);
    });

    testWidgets('status valid có viền sage; normal không viền', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          AuthTextField(
            controller: controller,
            hintText: 'x',
            status: AuthFieldStatus.valid,
          ),
        ),
      );
      expect(
        (decorationOf(tester).border! as Border).top.color,
        AuthPalette.sage,
      );

      await tester.pumpWidget(
        _host(AuthTextField(controller: controller, hintText: 'x')),
      );
      expect(decorationOf(tester).border, isNull);
    });

    testWidgets('obscureText che ký tự; prefixIcon và suffix được vẽ', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          AuthTextField(
            controller: controller,
            hintText: 'x',
            obscureText: true,
            prefixIcon: Icons.lock_outline,
            suffix: const Icon(Icons.cancel),
          ),
        ),
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isTrue,
      );
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('enabled=false thì TextField bị vô hiệu', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          AuthTextField(controller: controller, hintText: 'x', enabled: false),
        ),
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    });
  });

  group('PasswordVisibilityButton', () {
    testWidgets('obscured=true hiện icon "hiện mật khẩu"', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          PasswordVisibilityButton(obscured: true, onPressed: () => taps++),
        ),
      );
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byTooltip('Hiện mật khẩu'), findsOneWidget);

      await tester.tap(find.byType(PasswordVisibilityButton));
      expect(taps, 1);
    });

    testWidgets('obscured=false hiện icon "ẩn mật khẩu"', (tester) async {
      await tester.pumpWidget(
        _host(PasswordVisibilityButton(obscured: false, onPressed: () {})),
      );
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byTooltip('Ẩn mật khẩu'), findsOneWidget);
    });
  });

  group('AuthFieldError', () {
    testWidgets('hiển thị dấu "!" và message màu error', (tester) async {
      await tester.pumpWidget(
        _host(const AuthFieldError(message: 'Vui lòng nhập họ và tên.')),
      );
      expect(find.text('!'), findsOneWidget);
      expect(find.text('Vui lòng nhập họ và tên.'), findsOneWidget);
      final text = tester.widget<Text>(find.text('Vui lòng nhập họ và tên.'));
      expect(text.style!.color, AuthPalette.error);
    });

    testWidgets('message dài tự xuống dòng, không overflow', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 200,
            child: AuthFieldError(
              message:
                  'Số điện thoại chỉ được chứa chữ số hoặc định dạng '
                  '(+mã quốc gia) số (ví dụ: +84912345678 hoặc 0912345678), '
                  'không được chứa chữ cái hay ký tự đặc biệt.',
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('showAuthError', () {
    testWidgets('hiện SnackBar với message và nền errorDeep', (tester) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  showAuthError(context, 'Email hoặc mật khẩu không đúng.'),
              child: const Text('go'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Email hoặc mật khẩu không đúng.'), findsOneWidget);
      expect(
        tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor,
        AuthPalette.errorDeep,
      );
    });

    testWidgets('lỗi mới thay thế lỗi cũ', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );

      showAuthError(ctx, 'Lỗi một');
      await tester.pump();
      showAuthError(ctx, 'Lỗi hai');
      await tester.pumpAndSettle();

      expect(find.text('Lỗi hai'), findsOneWidget);
      expect(find.text('Lỗi một'), findsNothing);
    });
  });

  group('AuthLabeledDivider / AuthPill / GoogleLogo', () {
    testWidgets('hiển thị nhãn; pill viết hoa', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 300, child: AuthLabeledDivider(label: 'HOẶC')),
              AuthPill(label: 'Botanical', showDot: true),
              GoogleLogo(),
            ],
          ),
        ),
      );
      expect(find.text('HOẶC'), findsOneWidget);
      expect(find.text('BOTANICAL'), findsOneWidget);
      expect(find.byType(GoogleLogo), findsOneWidget);
    });
  });
}
