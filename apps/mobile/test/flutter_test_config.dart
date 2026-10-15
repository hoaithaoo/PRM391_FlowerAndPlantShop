import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/auth/utils/auth_theme.dart';

/// Chạy trước mọi file test trong thư mục test/.
///
/// - Tắt tải Google Fonts qua mạng.
/// - Font mặc định của FlutterTest (Ahem) rộng một em mỗi ký tự nên test
///   overflow báo tràn giả. Nạp Roboto của Flutter SDK làm font thay cho Inter
///   và Playfair Display để độ rộng chữ gần thực tế hơn (Inter hơi rộng hơn
///   Roboto vài %). Không tìm thấy font thì giữ nguyên Ahem.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  AuthFonts.useGoogleFonts = false;
  await _loadRealisticFonts();
  await testMain();
}

Future<void> _loadRealisticFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<ByteData?> read(String name) async {
    final file = File('$dir/$name');
    if (!file.existsSync()) return null;
    return ByteData.sublistView(await file.readAsBytes());
  }

  for (final family in ['Inter', 'Playfair Display']) {
    final loader = FontLoader(family);
    var added = false;
    for (final name in [
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf',
    ]) {
      final data = await read(name);
      if (data == null) continue;
      loader.addFont(Future.value(data));
      added = true;
    }
    if (added) await loader.load();
  }
}
