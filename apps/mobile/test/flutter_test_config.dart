import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/utils/auth_theme.dart';

/// Biến môi trường để giữ font mặc định Ahem của FlutterTest (rộng 1em mỗi
/// ký tự). Dùng khi muốn kiểm tra overflow ở trường hợp xấu nhất:
/// `PFS_TEST_FONT=ahem flutter test`.
const _fontEnvVar = 'PFS_TEST_FONT';

/// Giá trị [_fontEnvVar] để bỏ qua việc nạp font (giữ Ahem).
const _ahemValue = 'ahem';

/// Font đi kèm repo (Roboto, Apache-2.0, xem test/fonts/LICENSE.txt).
const _fontFiles = [
  'roboto-regular.ttf',
  'roboto-medium.ttf',
  'roboto-bold.ttf',
];

/// Hai family mà giao diện auth đang dùng (xem AuthFonts).
const _families = ['Inter', 'Playfair Display'];

/// Chạy trước mọi file test trong thư mục test/.
///
/// - Tắt tải Google Fonts qua mạng.
/// - Font mặc định của FlutterTest (Ahem) rộng một em mỗi ký tự nên test
///   overflow báo tràn giả. Nạp Roboto đi kèm repo (test/fonts) làm font thay
///   cho Inter và Playfair Display để độ rộng chữ gần thực tế hơn (Inter hơi
///   rộng hơn Roboto vài %). Không phụ thuộc cache của Flutter SDK nên chạy
///   giống nhau trên CI.
/// - `PFS_TEST_FONT=ahem` bỏ qua việc nạp font (giữ Ahem).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  AuthFonts.useGoogleFonts = false;
  await _loadRealisticFonts();
  await testMain();
}

Future<void> _loadRealisticFonts() async {
  if (Platform.environment[_fontEnvVar]?.toLowerCase() == _ahemValue) {
    stderr.writeln(
      '[flutter_test_config] $_fontEnvVar=$_ahemValue: giữ font Ahem '
      '(mỗi ký tự rộng 1em), test overflow sẽ khắt khe hơn thực tế.',
    );
    return;
  }

  final dir = _findFontsDirectory();
  if (dir == null) {
    stderr.writeln(
      '[flutter_test_config] CẢNH BÁO: không tìm thấy thư mục test/fonts '
      '(${_fontFiles.join(', ')}). Test sẽ dùng font Ahem rộng 1em mỗi ký '
      'tự nên có thể báo overflow giả.',
    );
    return;
  }

  for (final family in _families) {
    final loader = FontLoader(family);
    for (final name in _fontFiles) {
      final bytes = File('${dir.path}/$name').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}

/// Tìm `test/fonts` bằng cách đi lên tối đa 8 cấp từ thư mục hiện tại, rồi từ
/// vị trí file test đang chạy ([Platform.script]).
Directory? _findFontsDirectory() {
  final starts = <Directory>[Directory.current];
  final script = Platform.script;
  if (script.scheme == 'file') {
    starts.add(File.fromUri(script).parent);
  }
  for (final start in starts) {
    var dir = start.absolute;
    for (var depth = 0; depth <= 8; depth++) {
      for (final candidate in [
        '${dir.path}/test/fonts',
        '${dir.path}/fonts',
        '${dir.path}/apps/mobile/test/fonts',
      ]) {
        if (_hasAllFonts(candidate)) return Directory(candidate);
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
  }
  return null;
}

bool _hasAllFonts(String path) =>
    _fontFiles.every((name) => File('$path/$name').existsSync());
