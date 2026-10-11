enum FulfillmentMode { delivery, pickup }

enum LocalPaymentMethod { sepay, cod, payAtStore }

extension LocalPaymentMethodLabel on LocalPaymentMethod {
  String get label => switch (this) {
    LocalPaymentMethod.sepay => 'Chuyển khoản SePay QR',
    LocalPaymentMethod.cod => 'Thanh toán khi nhận hàng',
    LocalPaymentMethod.payAtStore => 'Thanh toán tại cửa hàng',
  };

  String get description => switch (this) {
    LocalPaymentMethod.sepay => 'Quét mã QR, xác nhận tự động và an toàn',
    LocalPaymentMethod.cod => 'Thanh toán cho người giao hoa khi nhận hàng',
    LocalPaymentMethod.payAtStore => 'Thanh toán khi đến nhận hoa tại studio',
  };
}

class CheckoutAddress {
  const CheckoutAddress({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.addressLine,
    required this.ward,
    required this.district,
    required this.city,
    this.driverNote = '',
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String label;
  final String recipientName;
  final String phone;
  final String addressLine;
  final String ward;
  final String district;
  final String city;
  final String driverNote;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  String get fullAddress => '$addressLine, $ward, $district, $city';

  CheckoutAddress copyWith({
    String? label,
    String? recipientName,
    String? phone,
    String? addressLine,
    String? ward,
    String? district,
    String? city,
    String? driverNote,
    bool? isDefault,
    double? latitude,
    double? longitude,
  }) {
    return CheckoutAddress(
      id: id,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      addressLine: addressLine ?? this.addressLine,
      ward: ward ?? this.ward,
      district: district ?? this.district,
      city: city ?? this.city,
      driverNote: driverNote ?? this.driverNote,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

class PickupBranch {
  const PickupBranch({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.readyTime,
    required this.openingHours,
    required this.imageAsset,
    this.isOpen = true,
  });

  final String id;
  final String name;
  final String address;
  final String distance;
  final String readyTime;
  final String openingHours;
  final String imageAsset;
  final bool isOpen;
}

class CheckoutTimelineStep {
  const CheckoutTimelineStep({
    required this.title,
    required this.description,
    this.isActive = false,
  });

  final String title;
  final String description;
  final bool isActive;
}
