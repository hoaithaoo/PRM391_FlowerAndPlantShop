import 'package:flutter/widgets.dart';

import 'cart_controller.dart';

class CartScope extends InheritedNotifier<CartController> {
  const CartScope({
    super.key,
    required CartController controller,
    required super.child,
  }) : super(notifier: controller);

  static CartController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CartScope>();
    assert(scope != null, 'Không tìm thấy CartScope phía trên widget này.');
    return scope!.notifier!;
  }
}
