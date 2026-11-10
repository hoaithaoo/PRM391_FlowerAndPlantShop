import 'checkout_flow_models.dart';
import 'checkout_result.dart';
import 'checkout_summary.dart';

/// Đơn vừa đặt thành công, đủ dữ liệu cho các màn QR và kết quả.
class PlacedOrder {
  const PlacedOrder({
    required this.result,
    required this.summary,
    required this.address,
    this.cardMessage = '',
    this.pickupTime,
  });

  final CheckoutResult result;
  final CheckoutSummary summary;

  /// Nơi giao, hoặc cửa hàng khi nhận tại quán.
  final CheckoutAddress address;
  final String cardMessage;

  /// Thời gian nhận hiển thị cho khách; có giá trị nghĩa là nhận tại quán.
  final String? pickupTime;
}
