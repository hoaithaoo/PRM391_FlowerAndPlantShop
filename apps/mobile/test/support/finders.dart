import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/app/main_shell.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

/// Màu nền của [Material] đầu tiên bên trong widget có [key].
Color? chipBackground(WidgetTester tester, Key key) {
  final material = find.descendant(
    of: find.byKey(key),
    matching: find.byType(Material),
  );
  expect(material, findsWidgets, reason: 'Không có Material trong $key');
  return tester.widget<Material>(material.first).color;
}

/// Chip danh mục (trang chủ hoặc danh mục) đang ở trạng thái được chọn.
bool isChipSelected(WidgetTester tester, Key key) {
  return chipBackground(tester, key) == AppColors.primaryLight;
}

/// Chạm một tab trên thanh điều hướng dưới.
Future<void> tapNav(WidgetTester tester, MainTab tab) async {
  await tester.tap(
    find.descendant(
      of: find.byType(AppBottomNav),
      matching: find.text(tab.label),
    ),
  );
  await tester.pumpAndSettle();
}

/// Tab đang hiển thị của [MainShell].
MainTab currentTab(WidgetTester tester) {
  final stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
  return MainTab.values[stack.index!];
}

/// Văn bản của một [Text] hoặc [Text.rich] tìm theo [finder].
String textOf(WidgetTester tester, Finder finder) {
  final widget = tester.widget<Text>(finder);
  return widget.data ?? widget.textSpan!.toPlainText();
}

/// Cuộn [scrollable] cho tới khi [target] hiện ra.
Future<void> scrollTo(
  WidgetTester tester,
  Finder target, {
  Finder? scrollable,
  double delta = 300,
}) {
  return tester.scrollUntilVisible(
    target,
    delta,
    scrollable: scrollable,
    maxScrolls: 100,
  );
}

/// Màu nền của [Material] gần nhất bao quanh widget có [key].
Color? ancestorMaterialColor(WidgetTester tester, Key key) {
  final material = find.ancestor(
    of: find.byKey(key),
    matching: find.byType(Material),
  );
  expect(material, findsWidgets, reason: 'Không có Material bao quanh $key');
  return tester.widget<Material>(material.first).color;
}

/// Bơm vài khung hình theo thời gian thay cho `pumpAndSettle` khi trên màn
/// còn animation chạy mãi (ví dụ CircularProgressIndicator).
Future<void> pumpFrames(WidgetTester tester, [int frames = 6]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
