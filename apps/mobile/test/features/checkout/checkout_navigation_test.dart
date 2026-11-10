import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/app/main_shell.dart';

import '../../support/product_test_app.dart';

void main() {
  testWidgets('nút thanh toán trong giỏ gọi luồng checkout', (tester) async {
    var opened = false;
    await pumpProductApp(
      tester,
      MainShell(
        initialTab: MainTab.cart,
        onCheckout: () => opened = true,
      ),
    );

    await tester.tap(find.byKey(const Key('cart-checkout')));
    await tester.pump();

    expect(opened, isTrue);
  });
}
