import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:plant_flower_mobile/core/location/current_address_service.dart';
import 'package:plant_flower_mobile/core/location/location_service.dart';
import 'package:plant_flower_mobile/features/auth/auth.dart';
import 'package:plant_flower_mobile/features/auth/widgets/auth_common.dart';

import '../support/auth_test_harness.dart';
import '../support/current_address_test_service.dart';

Future<GlobalKey<NavigatorState>> openCompleteProfile(
  WidgetTester tester,
  FakeAuthRepository repo, {
  CurrentAddressService currentAddressService = const CurrentAddressService(),
  Size size = kSmallPhone,
  double textScale = 1,
}) async {
  final nav = await pumpAuthApp(
    tester,
    repo,
    home: CompleteProfileScreen(currentAddressService: currentAddressService),
    size: size,
    textScale: textScale,
  );
  return nav;
}

void main() {
  authTestWidgets('nút lưu luôn trong màn hình và phần tầng/căn hộ chỉ mở khi cần', (tester, repo) async {
    await openCompleteProfile(tester, repo);
    final before = tester.getRect(byKey('complete_profile_submit_button'));
    expect(before.bottom, lessThanOrEqualTo(kSmallPhone.height));
    expect(byKey('complete_profile_address_details_field'), findsNothing);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pump();
    expect(tester.getRect(byKey('complete_profile_submit_button')), before);
    await tapKey(tester, 'complete_profile_expand_details');
    expect(byKey('complete_profile_address_details_field'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('CompleteProfileScreen - Giao diện & Hiển thị', () {
    authTestWidgets('hiển thị đầy đủ tiêu đề và các trường nhập',
        (tester, repo) async {
      repo.currentUserMetadata = {'full_name': 'Lê Hoa'};
      repo.currentUserEmail = 'lehoa@gmail.com';

      await openCompleteProfile(tester, repo);

      expect(find.text('Hoàn thiện thông tin'), findsOneWidget);
      expect(find.text('Nhà Có Hoa'), findsOneWidget);
      expect(find.text('Tài khoản Google đã liên kết'), findsOneWidget);
      expect(find.text('lehoa@gmail.com'), findsOneWidget);
      expect(find.text('Lê Hoa'), findsOneWidget);
      expect(byKey('complete_profile_fullname_field'), findsOneWidget);
      expect(byKey('complete_profile_phone_field'), findsOneWidget);
      expect(byKey('complete_profile_address_field'), findsOneWidget);
      expect(byKey('complete_profile_agreement_checkbox'), findsOneWidget);
      expect(byKey('complete_profile_submit_button'), findsOneWidget);
      expect(byKey('complete_profile_sign_out_button'), findsOneWidget);
      expect(byKey('complete_profile_location_button'), findsOneWidget);
    });

    authTestWidgets(
        'báo lỗi khi bấm Hoàn tất mà thiếu số điện thoại và địa chỉ', (
      tester,
      repo,
    ) async {
      await openCompleteProfile(tester, repo);

      await tapKey(tester, 'complete_profile_submit_button');
      await settle(tester);

      expect(find.text('Vui lòng nhập số điện thoại.'), findsOneWidget);
      expect(find.text('Vui lòng nhập địa chỉ nhận hàng.'), findsOneWidget);
      expect(
          find.text(
              'Vui lòng đồng ý với Điều khoản dịch vụ và Chính sách bảo mật.'),
          findsOneWidget);
      expect(repo.calls, isEmpty);
    });

    authTestWidgets(
        'điền hợp lệ và bấm Hoàn tất gọi completeProfile thành công', (
      tester,
      repo,
    ) async {
      repo.currentUserMetadata = {'full_name': 'Lê Hoa'};
      repo.currentUserEmail = 'lehoa@gmail.com';

      await openCompleteProfile(tester, repo);

      await enterIn(tester, 'complete_profile_phone_field', '0912345678');
      await enterIn(tester, 'complete_profile_address_field',
          '456 Lê Lợi, Quận 1, TP.HCM');
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

  group('chọn địa chỉ trên bản đồ', () {
    authTestWidgets('tra tên đường thất bại vẫn nhập địa chỉ tại ghim và xác nhận được', (tester, repo) async {
      final service = TestCurrentAddressService()
        ..resolve = () async => throw const AddressLookupException();
      await openCompleteProfile(tester, repo, currentAddressService: service);
      await tapKey(tester, 'complete_profile_map_button');
      await settle(tester);
      await tester.drag(find.byType(FlutterMap), const Offset(60, 25));
      await tester.pump(const Duration(milliseconds: 650));
      await settle(tester);
      await tapKey(tester, 'delivery_location_enter_address');
      showKeyboard(tester, 300);
      await tester.pumpAndSettle();
      await enterIn(tester, 'delivery_location_manual_address', '123 Đường Hoa, TP. Hồ Chí Minh');
      expect(tester.takeException(), isNull);
      await tapKey(tester, 'delivery_location_confirm');
      await settle(tester);
      expect(find.text('123 Đường Hoa, TP. Hồ Chí Minh'), findsOneWidget);
      expect(find.text('Đã chọn vị trí trên bản đồ'), findsOneWidget);
    });

    authTestWidgets(
        'lấy GPS, kéo bản đồ, xác nhận rồi lưu đúng ghim và tầng/căn hộ',
        (tester, repo) async {
      repo.currentUserMetadata = {'full_name': 'Lê Hoa'};
      final service = TestCurrentAddressService();
      await openCompleteProfile(tester, repo, currentAddressService: service);
      expect(service.coordinateCalls, 0);
      await enterIn(tester, 'complete_profile_phone_field', '0912345678');
      await tapKey(tester, 'complete_profile_location_button');
      await settle(tester);
      expect(service.coordinateCalls, 1);
      expect(find.byType(FlutterMap), findsOneWidget);
      await tester.drag(find.byType(FlutterMap), const Offset(80, 35));
      await tester.pump(const Duration(milliseconds: 650));
      await settle(tester);
      final picked = service.lookups.last;
      expect(picked.longitude, isNot(106.69));
      expect(repo.calls, isEmpty);
      await tapKey(tester, 'delivery_location_confirm');
      await settle(tester);
      expect(find.text('Đã chọn vị trí trên bản đồ'), findsOneWidget);
      await tapKey(tester, 'complete_profile_expand_details');
      await enterIn(tester, 'complete_profile_address_details_field',
          'Tầng 3, căn hộ 302');
      await tapKey(tester, 'complete_profile_agreement_checkbox');
      await tapKey(tester, 'complete_profile_submit_button');
      await settle(tester);
      expect(repo.lastCompleteProfile?.latitude, picked.latitude);
      expect(repo.lastCompleteProfile?.longitude, picked.longitude);
      expect(repo.lastCompleteProfile?.address,
          startsWith('Tầng 3, căn hộ 302, '));
    });

    authTestWidgets('đang tìm địa chỉ thì chưa cho xác nhận ghim',
        (tester, repo) async {
      final pending = Completer<String>();
      final service = TestCurrentAddressService()
        ..resolve = () => pending.future;
      await openCompleteProfile(tester, repo, currentAddressService: service);
      await tapKey(tester, 'complete_profile_location_button');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Đang tìm địa chỉ tại ghim…'), findsOneWidget);
      final confirm =
          tester.widget<AuthPrimaryButton>(byKey('delivery_location_confirm'));
      expect(confirm.onPressed, isNull);
      pending.complete('123 Đường Hoa, TP. Hồ Chí Minh');
      await settle(tester);
    });

    authTestWidgets(
        'chọn bản đồ không cần quyền GPS, hủy không đổi địa chỉ đã nhập',
        (tester, repo) async {
      final service = TestCurrentAddressService();
      await openCompleteProfile(tester, repo, currentAddressService: service);
      await enterIn(
          tester, 'complete_profile_address_field', 'Địa chỉ đã nhập tay');
      await tapKey(tester, 'complete_profile_map_button');
      await settle(tester);
      expect(service.coordinateCalls, 0);
      expect(
          tester
              .widget<AuthPrimaryButton>(byKey('delivery_location_confirm'))
              .onPressed,
          isNull);
      await tester.tap(find.byTooltip('Quay lại'));
      await settle(tester);
      expect(find.text('Địa chỉ đã nhập tay'), findsOneWidget);
    });

    for (final failure in [
      LocationFailure.deniedForever,
      LocationFailure.serviceDisabled
    ]) {
      authTestWidgets('lỗi $failure vẫn kéo được map và mở đúng cài đặt',
          (tester, repo) async {
        final service = TestCurrentAddressService()
          ..locate = () async => throw LocationException(failure);
        await openCompleteProfile(tester, repo, currentAddressService: service);
        await tapKey(tester, 'complete_profile_location_button');
        await settle(tester);
        await tapKey(tester, 'delivery_location_settings');
        expect(service.appSettingsCalls,
            failure == LocationFailure.deniedForever ? 1 : 0);
        expect(service.locationSettingsCalls,
            failure == LocationFailure.serviceDisabled ? 1 : 0);
        await tester.drag(find.byType(FlutterMap), const Offset(60, 40));
        await tester.pump(const Duration(milliseconds: 650));
        await settle(tester);
        expect(
            tester
                .widget<AuthPrimaryButton>(byKey('delivery_location_confirm'))
                .onPressed,
            isNotNull);
        await tapKey(tester, 'delivery_location_confirm');
        await settle(tester);
        await tapKey(tester, 'complete_profile_manual_address');
        await enterIn(
            tester, 'complete_profile_address_field', 'Địa chỉ nhập tay');
        expect(find.text('Địa chỉ nhập tay'), findsOneWidget);
      });
    }

    for (final size in [kSmallPhone, kPhone]) {
      authTestWidgets('form và bản đồ không tràn ở $size khi phóng chữ',
          (tester, repo) async {
        repo.currentUserEmail =
            'tai.khoan.google.dia.chi.email.dai@example.com';
        final service = TestCurrentAddressService();
        await openCompleteProfile(tester, repo,
            currentAddressService: service, size: size, textScale: 1.3);
        await tapKey(tester, 'complete_profile_map_button');
        await settle(tester);
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(FlutterMap), const Offset(50, 25));
        await tester.pump(const Duration(milliseconds: 650));
        await settle(tester);
        expect(tester.takeException(), isNull);
        await tapKey(tester, 'delivery_location_confirm');
        await settle(tester);
        await tapKey(tester, 'complete_profile_submit_button');
        expect(tester.takeException(), isNull);
        showKeyboard(tester, 300);
        await tester.pumpAndSettle();
        await tapKey(tester, 'complete_profile_expand_details');
        await enterIn(
            tester, 'complete_profile_address_details_field', 'Căn hộ 12');
        expect(tester.takeException(), isNull);
        expect(tester.getRect(byKey('complete_profile_submit_button')).bottom,
            lessThanOrEqualTo(size.height - 300));
      });
    }
  });
}
