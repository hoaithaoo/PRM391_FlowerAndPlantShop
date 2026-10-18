import '../models/checkout_flow_models.dart';
import '../models/checkout_summary.dart';
import '../utils/checkout_assets.dart';

abstract final class CheckoutMockData {
  static const pickupTimeSlots = <String>[
    '10:00 – 11:00',
    '13:00 – 14:00',
    '15:00 – 16:00',
    '18:00 – 19:00',
  ];

  static const addresses = <CheckoutAddress>[
    CheckoutAddress(
      id: 'home',
      label: 'Nhà riêng',
      recipientName: 'Nguyễn Minh Anh',
      phone: '090 123 4567',
      addressLine: '15 Nguyễn Thiện Thuật',
      ward: 'Phường 2',
      district: 'Quận 3',
      city: 'TP. Hồ Chí Minh',
      driverNote: 'Gọi trước 10 phút, giao tại sảnh.',
      isDefault: true,
      latitude: 10.7703,
      longitude: 106.6822,
    ),
    CheckoutAddress(
      id: 'office',
      label: 'Văn phòng',
      recipientName: 'Nguyễn Minh Anh',
      phone: '090 123 4567',
      addressLine: '72 Lê Thánh Tôn',
      ward: 'Phường Bến Nghé',
      district: 'Quận 1',
      city: 'TP. Hồ Chí Minh',
      driverNote: 'Gửi lễ tân tầng trệt.',
    ),
    CheckoutAddress(
      id: 'mother',
      label: 'Nhà của mẹ',
      recipientName: 'Trần Ngọc Lan',
      phone: '091 886 2288',
      addressLine: '28 Đường số 7',
      ward: 'Phường An Khánh',
      district: 'TP. Thủ Đức',
      city: 'TP. Hồ Chí Minh',
    ),
  ];

  static const branches = <PickupBranch>[
    PickupBranch(
      id: 'thao-dien',
      name: 'Fleuré Thảo Điền',
      address: '24 Nguyễn Ư Dĩ, Thảo Điền, TP. Thủ Đức',
      distance: '2,1 km',
      readyTime: 'Sẵn sàng sau 45 phút',
      openingHours: 'Mở cửa · 08:00 – 21:00',
      imageAsset: CheckoutAssets.pickupBouquet,
    ),
    PickupBranch(
      id: 'district-1',
      name: 'Fleuré Đồng Khởi',
      address: '91 Đồng Khởi, Bến Nghé, Quận 1',
      distance: '4,8 km',
      readyTime: 'Sẵn sàng sau 60 phút',
      openingHours: 'Mở cửa · 08:30 – 21:30',
      imageAsset: CheckoutAssets.pickupArrangement,
    ),
    PickupBranch(
      id: 'district-3',
      name: 'Fleuré Tú Xương',
      address: '35 Tú Xương, Võ Thị Sáu, Quận 3',
      distance: '6,2 km',
      readyTime: 'Sẵn sàng sau 75 phút',
      openingHours: 'Mở cửa · 09:00 – 20:30',
      imageAsset: CheckoutAssets.pickupNotice,
    ),
  ];

  static const summary = CheckoutSummary(
    items: <CheckoutSummaryItem>[
      CheckoutSummaryItem(
        productId: 'bo-hoa-nang-tho',
        name: 'Nàng Thơ Ban Mai',
        variant: 'Bó tiêu chuẩn · Thiệp viết tay',
        quantity: 1,
        unitPrice: 1280000,
        subtotal: 1280000,
        imageAsset: CheckoutAssets.deliveryBouquet,
      ),
      CheckoutSummaryItem(
        productId: 'binh-hoa-moc-mien',
        name: 'Bình Mộc Miên',
        variant: 'Bình gốm kem · Cỡ nhỏ',
        quantity: 1,
        unitPrice: 320000,
        subtotal: 320000,
        imageAsset: CheckoutAssets.deliveryVase,
      ),
    ],
    subtotal: 1600000,
    tax: 0,
    shippingFee: 45000,
    discount: 119200,
    grandTotal: 1525800,
  );

  static const orderCode = 'FLR-241005-0186';
  static const transactionCode = 'SP24100592817';
  static const paymentCode = 'FLR2410050186';
  static const bankAccount = '0912 345 678';
  static const bankOwner = 'CONG TY TNHH FLEURE VIET NAM';
}
