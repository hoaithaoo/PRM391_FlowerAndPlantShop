import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';

import 'auth_test_harness.dart';

// Câu báo lỗi nguyên văn từ màn "Đăng ký - Lỗi" của thiết kế
const nameError = 'Tên không được chứa số và các ký tự đặc biệt.';
const phoneError =
    'Số điện thoại chỉ được chứa chữ số hoặc định dạng (+mã quốc gia) '
    'số (ví dụ: +84912345678 hoặc 0912345678), không được chứa chữ cái '
    'hay ký tự đặc biệt.';
const emailError =
    'Email không đúng định dạng tiêu chuẩn (ví dụ hợp lệ: name@example.com).';
const passwordError =
    'Mật khẩu phải tối thiểu 8 ký tự, có ít nhất 1 chữ cái in hoa, 1 chữ số '
    'và 1 ký tự đặc biệt (@, #, \$, %, v.v.).';
const confirmError = 'Mật khẩu xác nhận không khớp với mật khẩu đã nhập.';
const agreementError =
    'Vui lòng đồng ý với Điều khoản dịch vụ và Chính sách bảo mật.';

const validAddress = '470 An Dương Vương, P. An Lạc, Bình Tân, TP.HCM';

/// Mở màn đăng ký phía trên "login" (stack: HOME > login > register) hoặc
/// trực tiếp trên HOME.
Future<GlobalKey<NavigatorState>> openRegister(
  WidgetTester tester,
  FakeAuthRepository repo, {
  Size size = kSmallPhone,
  double textScale = 1,
}) async {
  final nav = await pumpAuthApp(tester, repo, size: size, textScale: textScale);
  await pushRoute(tester, nav, AuthRoutes.register);
  return nav;
}

/// Điền form đăng ký (mặc định toàn dữ liệu hợp lệ).
Future<void> fillRegister(
  WidgetTester tester, {
  String name = 'Nguyễn Phương Hà',
  String phone = '0912345678',
  String email = 'phuongha@gmail.com',
  String address = validAddress,
  String password = 'Hoa@12345',
  String? confirm,
}) async {
  await enterIn(tester, 'register_full_name_field', name);
  await enterIn(tester, 'register_phone_field', phone);
  await enterIn(tester, 'register_email_field', email);
  await enterIn(tester, 'register_address_field', address);
  await enterIn(tester, 'register_password_field', password);
  await enterIn(tester, 'register_confirm_password_field', confirm ?? password);
}

/// Dữ liệu y hệt màn "Đăng ký - Lỗi": 6 lỗi (địa chỉ hợp lệ).
Future<void> fillDesignErrorData(WidgetTester tester) async {
  await fillRegister(
    tester,
    name: 'Phương Hà 123@#',
    phone: '0912-abc-xyz',
    email: 'phuongha.fleuré@domain',
    password: 'hoa12345',
    confirm: 'Hoa@12345',
  );
}

Future<void> tapAgreement(WidgetTester tester) =>
    tapKey(tester, 'register_agreement_checkbox');

bool isChecked(WidgetTester tester) {
  final box = find.descendant(
    of: byKey('register_agreement_checkbox'),
    matching: find.byIcon(Icons.check),
  );
  return box.evaluate().isNotEmpty;
}

double scrollOffset(WidgetTester tester) => tester
    .state<ScrollableState>(find.byType(Scrollable).first)
    .position
    .pixels;

const registerFields = [
  'full_name',
  'phone',
  'email',
  'address',
  'password',
  'confirm_password',
];
