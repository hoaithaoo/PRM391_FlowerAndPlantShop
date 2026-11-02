import 'payment_method.dart';

/// Mua ngay: chỉ đặt sản phẩm này, không đọc giỏ hàng.
class CheckoutBuyNow {
  const CheckoutBuyNow({required this.productId, required this.quantity});

  final String productId;
  final int quantity;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'productId': productId,
    'quantity': quantity,
  };
}

class CheckoutRequest {
  const CheckoutRequest({
    required this.receiverName,
    required this.phone,
    this.address,
    this.latitude,
    this.longitude,
    required this.paymentMethod,
    this.note,
    this.voucherCode,
    this.shippingVoucherCode,
    this.buyNow,
    this.pickupStoreId,
    this.pickupAt,
  });

  final String receiverName;
  final String phone;
  final String? address;
  final double? latitude;
  final double? longitude;
  final PaymentMethod paymentMethod;
  final String? note;
  final String? voucherCode;
  final String? shippingVoucherCode;
  final CheckoutBuyNow? buyNow;

  /// Có giá trị nghĩa là nhận tại quán; server tự lấy địa chỉ cửa hàng.
  final String? pickupStoreId;
  final DateTime? pickupAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'receiverName': receiverName,
      'phone': phone,
      if (address != null) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'paymentMethod': paymentMethod.apiValue,
      if (note != null && note!.isNotEmpty) 'note': note,
      if (voucherCode != null && voucherCode!.isNotEmpty)
        'voucherCode': voucherCode,
      if (shippingVoucherCode != null)
        'shippingVoucherCode': shippingVoucherCode,
      if (buyNow != null) 'buyNow': buyNow!.toJson(),
      if (pickupStoreId != null) 'pickupStoreId': pickupStoreId,
      if (pickupAt != null) 'pickupAt': pickupAt!.toUtc().toIso8601String(),
    };
  }
}
