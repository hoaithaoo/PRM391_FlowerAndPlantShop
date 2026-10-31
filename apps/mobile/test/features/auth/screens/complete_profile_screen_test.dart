import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';

import '../support/auth_test_harness.dart';

Future<GlobalKey<NavigatorState>> openCompleteProfile(
  WidgetTester tester,
  FakeAuthRepository repo,
) async {
  final nav = await pumpAuthApp(
    tester,
    repo,
    home: const CompleteProfileScreen(),
  );
  return nav;
}

void main() {
  group('CompleteProfileScreen - Giao diện & Hiển thị', () {
    authTestWidgets('hiển thị đầy đủ tiêu đề và các trường nhập', (tester, repo) async {
      repo.currentUserMetadata = {'full_name': 'Lê Hoa'};
      repo.currentUserEmail = 'lehoa@gmail.com';

      await openCompleteProfile(tester, repo);

      expect(find.text('Hoàn thiện thông tin'), findsOneWidget);
      expect(find.text('GOOGLE SIGN-IN'), findsOneWidget);
      expect(find.text('lehoa@gmail.com'), findsOneWidget);
      expect(find.text('Lê Hoa'), findsOneWidget);
      expect(byKey('complete_profile_fullname_field'), findsOneWidget);
      expect(byKey('complete_profile_phone_field'), findsOneWidget);
      expect(byKey('complete_profile_address_field'), findsOneWidget);
      expect(byKey('complete_profile_agreement_checkbox'), findsOneWidget);
      expect(byKey('complete_profile_submit_button'), findsOneWidget);
      expect(byKey('complete_profile_sign_out_button'), findsOneWidget);
    });

    authTestWidgets('báo lỗi khi bấm Hoàn tất mà thiếu số điện thoại và địa chỉ', (
      tester,
      repo,
    ) async {
      await openCompleteProfile(tester, repo);

      await tapKey(tester, 'complete_profile_submit_button');
      await settle(tester);

      expect(find.text('Vui lòng nhập số điện thoại.'), findsOneWidget);
      expect(find.text('Vui lòng nhập địa chỉ nhận hàng.'), findsOneWidget);
      expect(find.text('Vui lòng đồng ý với Điều khoản dịch vụ và Chính sách bảo mật.'), findsOneWidget);
      expect(repo.calls, isEmpty);
    });

    authTestWidgets('điền hợp lệ và bấm Hoàn tất gọi completeProfile thành công', (
      tester,
      repo,
    ) async {
      repo.currentUserMetadata = {'full_name': 'Lê Hoa'};
      repo.currentUserEmail = 'lehoa@gmail.com';

      await openCompleteProfile(tester, repo);

      await enterIn(tester, 'complete_profile_phone_field', '0912345678');
      await enterIn(tester, 'complete_profile_address_field', '456 Lê Lợi, Quận 1, TP.HCM');
      await tapKey(tester, 'complete_profile_agreement_checkbox');
      await settle(tester);

      await tapKey(tester, 'complete_profile_submit_button');
      await settle(tester);

      expect(repo.calls, ['completeProfile']);
      expect(repo.lastCompleteProfile?.fullName, 'Lê Hoa');
      expect(repo.lastCompleteProfile?.phone, '0912345678');
      expect(repo.lastCompleteProfile?.address, '456 Lê Lợi, Quận 1, TP.HCM');
    });

    authTestWidgets('bấm nút Đăng xuất gọi repo.signOut', (tester, repo) async {
      await openCompleteProfile(tester, repo);

      await tapKey(tester, 'complete_profile_sign_out_button');
      await settle(tester);

      expect(repo.calls, ['signOut']);
    });
  });
}

