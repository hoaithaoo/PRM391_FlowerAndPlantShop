import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/overflow_scenarios.dart';

/// Cùng kịch bản với `test/layout/overflow_test.dart` nhưng chạy bằng font
/// Ahem (xem `flutter_test_config.dart` cùng thư mục): chữ rất rộng nên nếu
/// một Row không co giãn được thì sẽ tràn ở đây.
void main() {
  testWidgets('đang dùng font Ahem (mỗi ký tự rộng đúng 1em)', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            'abcd',
            style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 10),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.text('abcd')).width, 40);
  });

  defineOverflowScenarios('Ahem 360x800', size: const Size(360, 800));
  defineOverflowScenarios(
    'Ahem 390x844 chữ phóng to 1.3',
    size: const Size(390, 844),
    textScale: 1.3,
  );
}
