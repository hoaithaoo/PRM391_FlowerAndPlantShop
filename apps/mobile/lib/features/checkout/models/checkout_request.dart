import 'payment_method.dart';

class CheckoutRequest {
  const CheckoutRequest({
    required this.receiverName,
    required this.phone,
    required this.address,
    this.latitude,
    this.longitude,
    required this.paymentMethod,
    this.note,
  });

  final String receiverName;
  final String phone;
  final String address;
  final double? latitude;
  final double? longitude;
  final PaymentMethod paymentMethod;
  final String? note;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'receiverName': receiverName,
      'phone': phone,
      'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'paymentMethod': paymentMethod.apiValue,
      if (note != null && note!.isNotEmpty) 'note': note,
    };
  }
}
