import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

/// Cấu hình riêng cho thư mục này: KHÔNG nạp font thật, giữ font Ahem mặc định
/// của flutter_test (mỗi ký tự rộng 1em) để CI luôn bắt được lỗi tràn khi
/// font rộng, kể cả khi font Roboto đóng gói có sẵn ở các thư mục khác.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppFonts.useGoogleFonts = false;
  await testMain();
}
