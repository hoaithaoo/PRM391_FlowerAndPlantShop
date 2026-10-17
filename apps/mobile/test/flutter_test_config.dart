import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

/// Chạy trước mọi file test trong thư mục test/.
///
/// - Tắt tải Google Fonts qua mạng.
/// - Font mặc định của FlutterTest (Ahem) rộng một em mỗi ký tự nên test
///   overflow báo tràn giả. Nạp Roboto (Apache-2.0, kèm trong `test/fonts/`)
///   thay cho các font của DESIGN.md để độ rộng chữ gần thực tế hơn. Không
///   phụ thuộc cache của Flutter SDK nên chạy giống nhau ở local và CI.
/// - Đặt biến môi trường `PFS_TEST_FONT=ahem` để bỏ qua việc nạp font (giữ
///   Ahem), dùng để tái hiện môi trường mà font không nạp được.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppFonts.useGoogleFonts = false;
  if (Platform.environment['PFS_TEST_FONT']?.toLowerCase() == 'ahem') {
    // ignore: avoid_print
    print('[flutter_test_config] PFS_TEST_FONT=ahem: dùng font Ahem mặc định.');
  } else {
    await _loadRealisticFonts();
  }
  await testMain();
}

const _fontFiles = ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf'];

/// Thư mục `test/fonts` của package, tìm theo thư mục hiện tại (melos và
/// `flutter test` đều chạy ở gốc package) rồi theo đường dẫn file test.
Directory? _findFontDir() {
  final starts = <Directory>[Directory.current];
  try {
    starts.add(File.fromUri(Platform.script).parent);
  } on Object {
    // Platform.script có thể không phải file URI
  }
  for (final start in starts) {
    var dir = start.absolute;
    for (var i = 0; i < 8; i++) {
      for (final candidate in [
        Directory('${dir.path}/test/fonts'),
        Directory('${dir.path}/fonts'),
        Directory('${dir.path}/apps/mobile/test/fonts'),
      ]) {
        if (File('${candidate.path}/${_fontFiles.first}').existsSync()) {
          return candidate;
        }
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
  }
  return null;
}

Future<void> _loadRealisticFonts() async {
  final dir = _findFontDir();
  if (dir == null) {
    // ignore: avoid_print
    print(
      '[flutter_test_config] CẢNH BÁO: không tìm thấy test/fonts/roboto-*.ttf; '
      'dùng font Ahem nên test overflow có thể báo tràn giả.',
    );
    return;
  }
  final data = <ByteData>[];
  for (final name in _fontFiles) {
    final file = File('${dir.path}/$name');
    if (!file.existsSync()) {
      // ignore: avoid_print
      print('[flutter_test_config] CẢNH BÁO: thiếu ${file.path}');
      continue;
    }
    data.add(ByteData.sublistView(await file.readAsBytes()));
  }
  if (data.isEmpty) return;
  for (final family in [
    'Plus Jakarta Sans',
    'Cormorant Garamond',
    'Dancing Script',
  ]) {
    final loader = FontLoader(family);
    for (final bytes in data) {
      loader.addFont(Future.value(bytes));
    }
    await loader.load();
  }
}
