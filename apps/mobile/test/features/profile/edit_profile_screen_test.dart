import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/checkout/data/checkout_repository.dart';
import 'package:plant_flower_mobile/features/checkout/models/checkout_flow_models.dart';
import 'package:plant_flower_mobile/features/profile/data/mock_profile_repository.dart';
import 'package:plant_flower_mobile/features/profile/models/profile_models.dart';
import 'package:plant_flower_mobile/features/profile/screens/edit_profile_screen.dart';

class _Addresses implements CheckoutRepository {
  _Addresses(this.items);
  List<CheckoutAddress> items;
  final saved = <CheckoutAddress>[];
  bool fail = false;

  @override
  Future<List<CheckoutAddress>> listAddresses() async {
    if (fail) throw Exception('offline');
    return items;
  }

  @override
  Future<CheckoutAddress> saveAddress(CheckoutAddress address) async {
    saved.add(address);
    return address;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _home = CheckoutAddress(
  id: 'a1',
  label: 'Nhà riêng',
  recipientName: 'Phạm Hoàng Định',
  phone: '0912345678',
  addressLine: '123 Đường Hoa, TP. Hồ Chí Minh',
  ward: '',
  district: '',
  city: '',
  isDefault: true,
  latitude: 10.77,
  longitude: 106.7,
);

const _profile = UserProfile(
  id: 'u1',
  email: 'pdinh460@gmail.com',
  fullName: 'Phạm Hoàng Định',
  phone: '0912345678',
);

Future<Object?> _open(
  WidgetTester tester,
  _Addresses addresses, {
  UserProfile profile = _profile,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  Object? popped;
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () async {
          popped = await Navigator.of(context).push<UserProfile>(
            MaterialPageRoute(
              builder: (_) => EditProfileScreen(
                repository: MockProfileRepository(),
                profile: profile,
                checkoutRepository: addresses,
              ),
            ),
          );
        },
        child: const Text('open'),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return popped;
}

void main() {
  testWidgets('hiện đủ thông tin như lúc điền và địa chỉ mặc định',
      (tester) async {
    await _open(tester, _Addresses([_home]));
    expect(find.text('Phạm Hoàng Định'), findsOneWidget);
    expect(find.text('0912345678'), findsOneWidget);
    expect(find.text('pdinh460@gmail.com'), findsOneWidget);
    expect(find.text('123 Đường Hoa, TP. Hồ Chí Minh'), findsOneWidget);
    expect(find.text('Đã chọn vị trí trên bản đồ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('thêm tầng/căn hộ thì cập nhật địa chỉ, giữ toạ độ',
      (tester) async {
    final addresses = _Addresses([_home]);
    await _open(tester, addresses);
    await tester.tap(find.byKey(const Key('profile-expand-details')));
    await tester.pump();
    await tester.enterText(
        find.byKey(const Key('profile-address-details')), 'Tầng 3');
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();
    final saved = addresses.saved.single;
    expect(saved.id, 'a1');
    expect(saved.fullAddress, 'Tầng 3, 123 Đường Hoa, TP. Hồ Chí Minh');
    expect(saved.latitude, 10.77);
    expect(find.byType(EditProfileScreen), findsNothing);
  });

  testWidgets('không đổi địa chỉ thì chỉ lưu hồ sơ', (tester) async {
    final addresses = _Addresses([_home]);
    await _open(tester, addresses);
    await tester.enterText(find.byKey(const Key('profile-name')), 'Lê Hoa');
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();
    expect(addresses.saved, isEmpty);
    expect(find.byType(EditProfileScreen), findsNothing);
  });

  testWidgets('chưa có địa chỉ thì tạo mới làm mặc định', (tester) async {
    final addresses = _Addresses([]);
    await _open(tester, addresses);
    await tester.enterText(
        find.byKey(const Key('profile-address')), '45 Lê Lợi, Quận 1, TP.HCM');
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();
    final saved = addresses.saved.single;
    expect(saved.isNew, isTrue);
    expect(saved.isDefault, isTrue);
    expect(saved.recipientName, 'Phạm Hoàng Định');
  });

  testWidgets('thiếu tên, SĐT, địa chỉ thì báo lỗi và không lưu',
      (tester) async {
    final addresses = _Addresses([]);
    await _open(tester, addresses,
        profile: const UserProfile(id: 'u1', email: 'x@gmail.com'));
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập họ và tên.'), findsOneWidget);
    expect(find.text('Vui lòng nhập số điện thoại.'), findsOneWidget);
    expect(find.byKey(const Key('profile-address-error')), findsOneWidget);
    expect(addresses.saved, isEmpty);
    expect(find.byType(EditProfileScreen), findsOneWidget);
  });

  testWidgets('không tải được địa chỉ thì có nút thử lại, vẫn lưu được hồ sơ',
      (tester) async {
    final addresses = _Addresses([_home])..fail = true;
    await _open(tester, addresses);
    expect(find.text('Không tải được địa chỉ đã lưu.'), findsOneWidget);
    addresses.fail = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('123 Đường Hoa, TP. Hồ Chí Minh'), findsOneWidget);
  });
}
