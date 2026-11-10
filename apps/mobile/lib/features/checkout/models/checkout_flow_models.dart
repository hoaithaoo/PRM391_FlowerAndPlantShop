import '../utils/checkout_assets.dart';

enum FulfillmentMode { delivery, pickup }

/// Khung giờ nhận tại quán; backend chỉ kiểm tra thời điểm ở tương lai.
const pickupTimeSlots = <String>[
  '10:00 – 11:00',
  '13:00 – 14:00',
  '15:00 – 16:00',
  '18:00 – 19:00',
];

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

/// Id tạm của địa chỉ chưa lưu lên server.
const newAddressId = 'new-address';

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

  /// Backend lưu địa chỉ một chuỗi: app ghi `số nhà, phường, quận, thành phố`
  /// nên tách lại được khi đủ phần, còn lại giữ nguyên ở [addressLine].
  factory CheckoutAddress.fromJson(Map<String, dynamic> json) {
    final parts = (json['addressLine'] as String).split(', ');
    final hasDivisions = parts.length >= 4;
    final divisions = hasDivisions ? parts.length - 3 : parts.length;
    return CheckoutAddress(
      id: json['id'] as String,
      label: json['label'] as String? ?? 'Nhà riêng',
      recipientName: json['recipientName'] as String,
      phone: json['recipientPhone'] as String,
      addressLine: parts.take(divisions).join(', '),
      ward: hasDivisions ? parts[divisions] : '',
      district: hasDivisions ? parts[divisions + 1] : '',
      city: hasDivisions ? parts[divisions + 2] : '',
      driverNote: json['deliveryNote'] as String? ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  bool get isNew => id == newAddressId;

  bool get hasCoordinates => latitude != null && longitude != null;

  String get normalizedPhone => phone.replaceAll(RegExp(r'[^\d+]'), '');

  String get fullAddress => <String>[
    addressLine,
    ward,
    district,
    city,
  ].where((part) => part.trim().isNotEmpty).join(', ');

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'recipientName': recipientName,
      'recipientPhone': normalizedPhone,
      'addressLine': fullAddress,
      'label': label,
      'deliveryNote': driverNote,
      'isDefault': isDefault,
      if (hasCoordinates) 'latitude': latitude,
      if (hasCoordinates) 'longitude': longitude,
    };
  }

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
    this.latitude,
    this.longitude,
    this.phone,
    this.distanceKm,
    this.shippingFee,
    this.estimatedDeliveryMinutes,
  });

  /// Một phần tử của `GET /stores`.
  factory PickupBranch.fromJson(Map<String, dynamic> json) {
    final distanceKm = _nullableDouble(json['distanceKm']);
    return PickupBranch(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      distance: distanceKm == null
          ? 'Chưa rõ khoảng cách'
          : '${distanceKm.toStringAsFixed(1).replaceAll('.', ',')} km',
      readyTime: 'Hoa được chuẩn bị trước giờ bạn ghé',
      openingHours: json['openingHours'] as String? ?? 'Liên hệ cửa hàng',
      imageAsset: CheckoutAssets.pickupBouquet,
      latitude: _nullableDouble(json['latitude']),
      longitude: _nullableDouble(json['longitude']),
      phone: json['phone'] as String?,
      distanceKm: distanceKm,
      shippingFee: json['shippingFee'] as num?,
      estimatedDeliveryMinutes:
          (json['estimatedDeliveryMinutes'] as num?)?.toInt(),
    );
  }

  final String id;
  final String name;
  final String address;
  final String distance;
  final String readyTime;
  final String openingHours;
  final String imageAsset;
  final bool isOpen;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final double? distanceKm;
  final num? shippingFee;
  final int? estimatedDeliveryMinutes;

  bool get hasValidCoordinates =>
      latitude != null &&
      longitude != null &&
      latitude!.isFinite &&
      longitude!.isFinite &&
      latitude! >= -90 &&
      latitude! <= 90 &&
      longitude! >= -180 &&
      longitude! <= 180;

  static double? _nullableDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
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
