import '../models/checkout_flow_models.dart';
import '../models/checkout_request.dart';
import '../models/checkout_result.dart';
import '../models/voucher.dart';

abstract interface class CheckoutRepository {
  Future<CheckoutResult> checkout(
    CheckoutRequest request, {
    required String idempotencyKey,
  });

  Future<List<CheckoutAddress>> listAddresses();

  /// Tạo mới hoặc cập nhật. Thiếu tọa độ thì server tự tra từ địa chỉ.
  Future<CheckoutAddress> saveAddress(CheckoutAddress address);

  /// Phí ship xem trước; số cuối cùng do `checkout` quyết định.
  Future<num> estimateShippingFee({
    required double latitude,
    required double longitude,
  });

  /// Cửa hàng đang mở; có tọa độ thì server sắp xếp từ gần đến xa.
  Future<List<PickupBranch>> listStores({double? latitude, double? longitude});

  Future<String> getPaymentStatus(String paymentId);

  Future<void> cancelOrder(String orderId, {String? reason});

  Future<List<Voucher>> availableVouchers();

  Future<Voucher> validateVoucher(String code);
}
