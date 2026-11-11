import 'package:flutter/widgets.dart';

import 'favorite_controller.dart';

class FavoriteScope extends InheritedNotifier<FavoriteController> {
  const FavoriteScope({
    super.key,
    required FavoriteController controller,
    required super.child,
  }) : super(notifier: controller);

  static FavoriteController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FavoriteScope>()?.notifier;

  static FavoriteController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(
      controller != null,
      'Không tìm thấy FavoriteScope phía trên widget này.',
    );
    return controller!;
  }
}
