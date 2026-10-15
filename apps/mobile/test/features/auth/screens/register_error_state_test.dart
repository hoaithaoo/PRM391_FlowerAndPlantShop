import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';
import 'package:plant_flower_mobile/features/auth/widgets/auth_common.dart';

import '../support/auth_test_harness.dart';
import '../support/register_test_helpers.dart';

/// Bấm "Đăng ký tài khoản" khi form còn trống: vào layout lỗi với 7 mục.
Future<void> submitEmpty(WidgetTester tester) async {
  await tapKey(tester, 'register_submit_button');
  await settle(tester);
}

/// Điền dữ liệu y hệt thiết kế rồi submit: 6 lỗi, riêng địa chỉ hợp lệ.
Future<void> enterDesignErrorState(WidgetTester tester) async {
  await fillDesignErrorData(tester);
  await tapKey(tester, 'register_submit_button');
  await settle(tester);
}

String errorCount(WidgetTester tester) =>
    tester.widget<Text>(byKey('register_error_count')).data!;

AuthFieldStatus statusOf(WidgetTester tester, String field) =>
    tester.widget<AuthTextField>(byKey('register_${field}_field')).status;

Icon statusIcon(WidgetTester tester, String field) =>
    tester.widget<Icon>(byKey('register_status_icon_$field'));

String ruleText(WidgetTester tester, String rule) {
  final text = find.descendant(
    of: byKey('register_password_rule_$rule'),
    matching: find.byType(Text),
  );
  return tester.widget<Text>(text).data!;
}

void main() {
  group('vào layout lỗi', () {
    authTestWidgets('submit form trống: 7 mục lỗi (6 ô + checkbox)', (
      tester,
      repo,
    ) async {
      await openRegister(tester, repo);
      await submitEmpty(tester);

      expect(byKey('register_error_summary'), findsOneWidget);
      expect(errorCount(tester), 'Có 7 mục cần điều chỉnh');
      expect(repo.calls, isEmpty);
      for (final f in registerFields) {
        expect(byKey('register_error_$f'), findsOneWidget, reason: f);
        expect(byKey('register_error_mark_$f'), findsOneWidget, reason: f);
        expect(statusOf(tester, f), AuthFieldStatus.error, reason: f);
        expect(statusIcon(tester, f).icon, Icons.cancel, reason: f);
        expect(statusIcon(tester, f).color, AuthPalette.error, reason: f);
        expect(byKey('register_valid_badge_$f'), findsNothing, reason: f);
      }
      expect(byKey('register_error_agreement'), findsOneWidget);
    });

    authTestWidgets(
      'khác layout thường: ẩn banner/social/ưu đãi, có thẻ hỗ trợ',
      (tester, repo) async {
        await openRegister(tester, repo);
        await submitEmpty(tester);

        expect(find.text('FLEURÉ ATELIER'), findsNothing);
        expect(find.text('Tạo tài khoản mới'), findsNothing);
        expect(byKey('register_google_button'), findsNothing);
        expect(find.text('Hoặc đăng ký nhanh bằng'), findsNothing);
        expect(find.text('Đặc quyền chào đón thành viên'), findsNothing);

        expect(find.text('KIỂM TRA THÔNG TIN'), findsOneWidget);
        expect(
          find.text('Đăng ký tài khoản'),
          findsNWidgets(2),
        ); // tiêu đề + nút
        expect(
          find.text(
            'Vui lòng kiểm tra và sửa lại các thông tin chưa chính xác bên dưới '
            'để hoàn tất đăng ký Fleuré Privé.',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'Những trường bị lỗi đã được làm nổi bật với thông báo cụ thể bên '
            'dưới.',
          ),
          findsOneWidget,
        );
        await tester.ensureVisible(byKey('register_support_card'));
        expect(byKey('register_support_card'), findsOneWidget);
        expect(find.text('Cần hỗ trợ đăng ký?'), findsOneWidget);
        expect(
          find.text(
            'Hỗ trợ riêng cho thành viên Privé: 1800 6868 (8:00 - 21:00)',
          ),
          findsNWidgets(1),
        );
        expect(byKey('register_help_button'), findsOneWidget);
        expect(byKey('register_back_button'), findsOneWidget);
      },
    );

    authTestWidgets('nhãn ở trạng thái lỗi đúng theo thiết kế', (
      tester,
      repo,
    ) async {
      await openRegister(tester, repo);
      await submitEmpty(tester);

      for (final label in [
        'HỌ VÀ TÊN',
        'SỐ ĐIỆN THOẠI',
        'ĐỊA CHỈ EMAIL',
        'ĐỊA CHỈ NHẬN HÀNG MẶC ĐỊNH',
        'MẬT KHẨU',
        'XÁC NHẬN MẬT KHẨU',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    authTestWidgets('bấm Đăng ký khi còn lỗi KHÔNG gọi repository', (
      tester,
      repo,
    ) async {
      await openRegister(tester, repo);
      await fillRegister(tester);
      await tapKey(tester, 'register_submit_button'); // chưa tick đồng ý
      await settle(tester);

      expect(repo.calls, isEmpty);
      expect(errorCount(tester), 'Có 1 mục cần điều chỉnh');
    });
  });

  group('dữ liệu y hệt màn "Đăng ký - Lỗi"', () {
    authTestWidgets('6 lỗi, địa chỉ hợp lệ, câu báo nguyên văn', (
      tester,
      repo,
    ) async {
      await openRegister(tester, repo);
      await enterDesignErrorState(tester);

      expect(errorCount(tester), 'Có 6 mục cần điều chỉnh');
      expect(find.text(nameError), findsOneWidget);
      expect(find.text(phoneError), findsOneWidget);
      expect(find.text(emailError), findsOneWidget);
      expect(find.text(passwordError), findsOneWidget);
      expect(find.text(confirmError), findsOneWidget);
      expect(find.text(agreementError), findsOneWidget);

      // Trường hợp lệ: nhãn "HỢP LỆ", icon check_circle sage, viền valid
      expect(byKey('register_valid_badge_address'), findsOneWidget);
      expect(find.text('HỢP LỆ'), findsOneWidget);
      expect(byKey('register_error_address'), findsNothing);
      expect(byKey('register_error_mark_address'), findsNothing);
      expect(statusOf(tester, 'address'), AuthFieldStatus.valid);
      expect(statusIcon(tester, 'address').icon, Icons.check_circle);
      expect(statusIcon(tester, 'address').color, AuthPalette.sage);

      // Các trường lỗi: dấu * đỏ và icon cancel
      for (final f in [
        'full_name',
        'phone',
        'email',
        'password',
        'confirm_password',
      ]) {
        expect(byKey('register_error_mark_$f'), findsOneWidget, reason: f);
        expect(statusOf(tester, f), AuthFieldStatus.error, reason: f);
      }
      expect(tester.widget<Text>(byKey('register_error_mark_phone')).data, '*');
      expect(
        tester.widget<Text>(byKey('register_error_mark_phone')).style!.color,
        AuthPalette.error,
      );
    });

    authTestWidgets(
      'checklist mật khẩu "hoa12345": Đạt/Chưa có đúng thiết kế',
      (tester, repo) async {
        await openRegister(tester, repo);
        await enterDesignErrorState(tester);
        await tester.ensureVisible(byKey('register_password_rules'));
        await tester.pump();

        expect(byKey('register_password_rules'), findsOneWidget);
        expect(ruleText(tester, 'min_length'), 'Tối thiểu 8 ký tự (Đạt)');
        expect(
          ruleText(tester, 'uppercase'),
          'Ít nhất 1 chữ cái in hoa (Chưa có)',
        );
        expect(ruleText(tester, 'digit'), 'Ít nhất 1 chữ số (Đạt)');
        expect(
          ruleText(tester, 'special'),
          'Ít nhất 1 ký tự đặc biệt (Chưa có)',
        );
      },
    );

    authTestWidgets(
      'ô mật khẩu vẫn che ký tự, có nút mắt cạnh icon trạng thái',
      (tester, repo) async {
        await openRegister(tester, repo);
        await enterDesignErrorState(tester);

        final pw = tester.widget<TextField>(
          find.descendant(
            of: byKey('register_password_field'),
            matching: find.byType(TextField),
          ),
        );
        expect(pw.obscureText, isTrue);
        expect(byKey('register_password_visibility_button'), findsOneWidget);
        expect(byKey('register_status_icon_password'), findsOneWidget);

        await tapKey(tester, 'register_password_visibility_button');
        final shown = tester.widget<TextField>(
          find.descendant(
            of: byKey('register_password_field'),
            matching: find.byType(TextField),
          ),
        );
        expect(shown.obscureText, isFalse);
        expect(textOf(tester, 'register_password_field'), 'hoa12345');
      },
    );

    authTestWidgets('dữ liệu đã nhập được giữ nguyên khi đổi layout', (
      tester,
      repo,
    ) async {
      await openRegister(tester, repo);
      await enterDesignErrorState(tester);

      expect(textOf(tester, 'register_full_name_field'), 'Phương Hà 123@#');
      expect(textOf(tester, 'register_phone_field'), '0912-abc-xyz');
      expect(textOf(tester, 'register_email_field'), 'phuongha.fleuré@domain');
      expect(textOf(tester, 'register_address_field'), validAddress);
      expect(textOf(tester, 'register_password_field'), 'hoa12345');
      expect(textOf(tester, 'register_confirm_password_field'), 'Hoa@12345');
    });
  });

  group('cập nhật thời gian thực', () {
    authTestWidgets('sửa đúng từng ô: đếm giảm, chuyển sang "HỢP LỆ"', (
      tester,
      repo,
    ) async {
      await openRegister(tester, repo);
      await enterDesignErrorState(tester);
      expect(errorCount(tester), 'Có 6 mục cần điều chỉnh');

      await enterIn(tester, 'register_full_name_field', 'Nguyễn Phương Hà');
      expect(errorCount(tester), 'Có 5 mục cần điều chỉnh');
      expect(byKey('register_error_full_name'), findsNothing);
      expect(byKey('register_valid_badge_full_name'), findsOneWidget);
      expect(statusOf(tester, 'full_name'), AuthFieldStatus.valid);

      await enterIn(tester, 'register_phone_field', '+84912345678');
      await enterIn(tester, 'register_email_field', 'name@example.com');
      expect(errorCount(tester), 'Có 3 mục cần điều chỉnh');

      await tapAgreement(tester);
      expect(errorCount(tester), 'Có 2 mục cần điều chỉnh');
      expect(byKey('register_error_agreement'), findsNothing);
    });

    authTestWidgets('sửa mật khẩu: checklist cập nhật theo từng ký tự', (
      tester,
      repo,
    ) async {
      await openRegister(tester, repo);
      await enterDesignErrorState(tester);

      await enterIn(tester, 'register_password_field', 'Hoa12345');
      expect(ruleText(tester, 'uppercase'), 'Ít nhất 1 chữ cái in hoa (Đạt)');
      expect(ruleText(tester, 'special'), 'Ít nhất 1 ký tự đặc biệt (Chưa có)');

      await enterIn(tester, 'register_password_field', 'Hoa@1');
      expect(ruleText(tester, 'min_length'), 'Tối thiểu 8 ký tự (Chưa có)');
      expect(ruleText(tester, 'special'), 'Ít nhất 1 ký tự đặc biệt (Đạt)');
    });

    authTestWidgets(
      'mật khẩu hợp lệ: checklist biến mất, xác nhận khớp thì hết lỗi',
      (tester, repo) async {
        await openRegister(tester, repo);
        await enterDesignErrorState(tester);

        await enterIn(tester, 'register_password_field', 'Hoa@12345');
        expect(byKey('register_password_rules'), findsNothing);
        expect(byKey('register_valid_badge_password'), findsOneWidget);
        // Xác nhận "Hoa@12345" nay khớp với mật khẩu mới
        expect(byKey('register_error_confirm_password'), findsNothing);
        expect(byKey('register_valid_badge_confirm_password'), findsOneWidget);
      },
    );

    authTestWidgets(
      'đổi mật khẩu làm ô xác nhận (đang hợp lệ) báo không khớp',
      (tester, repo) async {
        await openRegister(tester, repo);
        await enterDesignErrorState(tester);
        await enterIn(tester, 'register_password_field', 'Hoa@12345');
        expect(byKey('register_error_confirm_password'), findsNothing);

        await enterIn(tester, 'register_password_field', 'Hoa@123456');
        expect(find.text(confirmError), findsOneWidget);
      },
    );

    authTestWidgets('sửa hết lỗi: quay về layout thường, giữ dữ liệu', (
      tester,
      repo,
    ) async {
      await openRegister(tester, repo);
      await enterDesignErrorState(tester);

      await enterIn(tester, 'register_full_name_field', 'Nguyễn Phương Hà');
      await enterIn(tester, 'register_phone_field', '0912345678');
      await enterIn(tester, 'register_email_field', 'phuongha@gmail.com');
      await enterIn(tester, 'register_password_field', 'Hoa@12345');
      await tapAgreement(tester);
      await settle(tester);

      expect(byKey('register_error_summary'), findsNothing);
      expect(find.text('FLEURÉ ATELIER'), findsOneWidget);
      expect(byKey('register_google_button'), findsOneWidget);
      expect(isChecked(tester), isTrue);
      expect(textOf(tester, 'register_email_field'), 'phuongha@gmail.com');
      expect(textOf(tester, 'register_confirm_password_field'), 'Hoa@12345');

      // Từ đây bấm Đăng ký thành công
      await tapKey(tester, 'register_submit_button');
      await settle(tester);
      expect(repo.count('signUp'), 1);
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
    });

    authTestWidgets(
      'sau khi về layout thường, xóa một ô không bật lại layout lỗi',
      (tester, repo) async {
        await openRegister(tester, repo);
        await enterDesignErrorState(tester);

        await enterIn(tester, 'register_full_name_field', 'Nguyễn Phương Hà');
        await enterIn(tester, 'register_phone_field', '0912345678');
        await enterIn(tester, 'register_email_field', 'phuongha@gmail.com');
        await enterIn(tester, 'register_password_field', 'Hoa@12345');
        await tapAgreement(tester);
        await settle(tester);
        expect(byKey('register_error_summary'), findsNothing);

        // Xóa/gõ sai khi chưa bấm Đăng ký: vẫn layout thường
        await enterIn(tester, 'register_email_field', '');
        await settle(tester);
        expect(byKey('register_error_summary'), findsNothing);
        expect(byKey('register_google_button'), findsOneWidget);

        // Bấm Đăng ký lần kế tiếp mới hiện lỗi
        await tapKey(tester, 'register_submit_button');
        await settle(tester);
        expect(byKey('register_error_summary'), findsOneWidget);
        expect(errorCount(tester), 'Có 1 mục cần điều chỉnh');
        expect(repo.count('signUp'), 0);
      },
    );

    authTestWidgets(
      'đang gõ ô cuối thì layout đổi, ô vẫn giữ focus và nội dung',
      (tester, repo) async {
        await openRegister(tester, repo);
        await fillRegister(tester, confirm: 'sai');
        await tapAgreement(tester);
        await tapKey(tester, 'register_submit_button');
        await settle(tester);
        expect(errorCount(tester), 'Có 1 mục cần điều chỉnh');

        await tapKey(tester, 'register_confirm_password_field');
        await tester.enterText(
          byKey('register_confirm_password_field'),
          'Hoa@12345',
        );
        await settle(tester);

        expect(
          byKey('register_error_summary'),
          findsNothing,
        ); // đã về layout thường
        final editable = tester.widget<EditableText>(
          find.descendant(
            of: byKey('register_confirm_password_field'),
            matching: find.byType(EditableText),
          ),
        );
        expect(editable.focusNode.hasFocus, isTrue);
        expect(editable.controller.text, 'Hoa@12345');
      },
    );

    authTestWidgets('bấm Đăng ký lần nữa khi còn lỗi: ở lại layout lỗi', (
      tester,
      repo,
    ) async {
      await openRegister(tester, repo);
      await enterDesignErrorState(tester);
      await tapKey(tester, 'register_submit_button');
      await settle(tester);

      expect(byKey('register_error_summary'), findsOneWidget);
      expect(errorCount(tester), 'Có 6 mục cần điều chỉnh');
      expect(repo.calls, isEmpty);
    });

    authTestWidgets('cuộn lên đầu trang khi vào layout lỗi', (
      tester,
      repo,
    ) async {
      await openRegister(tester, repo);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -3000),
      );
      await tester.pump();
      expect(scrollOffset(tester), greaterThan(0));

      await tapKey(tester, 'register_submit_button');
      await settle(tester);

      expect(byKey('register_error_summary'), findsOneWidget);
      expect(scrollOffset(tester), 0);
      expect(find.text('KIỂM TRA THÔNG TIN'), findsOneWidget);
    });
  });

  group('điều hướng và nút phụ', () {
    authTestWidgets('nút trợ giúp hiện số hỗ trợ 1800 6868', (
      tester,
      repo,
    ) async {
      await openRegister(tester, repo);
      await submitEmpty(tester);
      await tester.tap(byKey('register_help_button'));
      await tester.pump();

      expect(
        snackText(
          'Hỗ trợ riêng cho thành viên Privé: 1800 6868 (8:00 - 21:00)',
        ),
        findsOneWidget,
      );
    });

    authTestWidgets('nút back của header lỗi pop về màn trước', (
      tester,
      repo,
    ) async {
      await openRegister(tester, repo);
      await submitEmpty(tester);
      await tester.tap(byKey('register_back_button'));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsNothing);
      expect(find.text(kHomeText), findsOneWidget);
    });

    authTestWidgets('"Đăng nhập ngay" ở layout lỗi quay về màn đăng nhập', (
      tester,
      repo,
    ) async {
      final nav = await pumpAuthApp(tester, repo);
      await pushRoute(tester, nav, AuthRoutes.login);
      await tapKey(tester, 'login_register_link');
      await tester.pumpAndSettle();
      await submitEmpty(tester);

      await tapKey(tester, 'register_login_link');
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(RegisterScreen), findsNothing);
    });

    authTestWidgets('link điều khoản ở layout lỗi hiện "Đang cập nhật"', (
      tester,
      repo,
    ) async {
      await openRegister(tester, repo);
      await submitEmpty(tester);
      await tester.ensureVisible(byKey('register_agreement_checkbox'));
      await tester.pump();
      // Chọn cụm có "của" để không trùng câu báo lỗi cũng chứa tên chính sách
      await tester.tapOnText(
        find.textRange.ofSubstring('Chính sách bảo mật của'),
      );
      await tester.pump();

      expect(snackText('Đang cập nhật'), findsOneWidget);
      expect(isChecked(tester), isFalse);
      expect(
        find.textContaining('Fleuré Privé.', findRichText: true),
        findsWidgets,
      );
    });

    authTestWidgets('viền ô checkbox chuyển đỏ khi chưa đồng ý ở layout lỗi', (
      tester,
      repo,
    ) async {
      await openRegister(tester, repo);
      await submitEmpty(tester);
      await tester.ensureVisible(byKey('register_agreement_checkbox'));
      await tester.pump();

      final box = tester.widget<Container>(
        find.descendant(
          of: byKey('register_agreement_checkbox'),
          matching: find.byType(Container),
        ),
      );
      final border = (box.decoration! as BoxDecoration).border! as Border;
      expect(border.top.color, AuthPalette.error);
    });
  });

  group('overflow', () {
    for (final size in [kSmallPhone, kPhone]) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';

      authTestWidgets(
        'layout lỗi không overflow ở $label (6 lỗi, cuộn hết trang)',
        (tester, repo) async {
          await openRegister(tester, repo, size: size);
          await enterDesignErrorState(tester);
          expect(tester.takeException(), isNull);

          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -6000),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(byKey('register_support_card'), findsOneWidget);
        },
      );

      authTestWidgets('layout lỗi ($label) không overflow khi bàn phím mở', (
        tester,
        repo,
      ) async {
        showKeyboard(tester, 300);
        await openRegister(tester, repo, size: size);
        await submitEmpty(tester);
        await tapKey(tester, 'register_full_name_field');
        expect(tester.takeException(), isNull);
      });
    }

    authTestWidgets('layout lỗi không overflow khi chữ phóng to 1.3x', (
      tester,
      repo,
    ) async {
      await openRegister(tester, repo, textScale: 1.3);
      await enterDesignErrorState(tester);
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -6000),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
