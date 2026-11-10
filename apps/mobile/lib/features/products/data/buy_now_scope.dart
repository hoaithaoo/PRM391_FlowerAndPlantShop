import 'package:flutter/widgets.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

typedef BuyNowCallback = void Function(ProductDetail product, int quantity);

/// Cho màn chi tiết sản phẩm mở thanh toán mà không cần biết repository checkout.
class BuyNowScope extends InheritedWidget {
  const BuyNowScope({super.key, required this.onBuyNow, required super.child});

  final BuyNowCallback onBuyNow;

  static BuyNowCallback? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<BuyNowScope>()?.onBuyNow;

  @override
  bool updateShouldNotify(BuyNowScope oldWidget) => false;
}
