import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/profile/models/profile_models.dart';

void main() {
  OrderSummary order(String status, String paymentStatus) => OrderSummary(
    id: 'o',
    orderCode: 'ORD',
    status: status,
    paymentStatus: paymentStatus,
    grandTotal: 1,
    createdAt: DateTime(2026),
  );

  test('chỉ hủy được đơn chưa xử lý và chưa thanh toán', () {
    expect(order('PENDING', 'PENDING').canCancel, isTrue);
    expect(order('CONFIRMED', 'PENDING').canCancel, isTrue);
    expect(order('PENDING', 'PAID').canCancel, isFalse);
    expect(order('PREPARING', 'PENDING').canCancel, isFalse);
  });

  test('OrderDetail đọc đơn nhận tại quán', () {
    final detail = OrderDetail.fromJson(<String, dynamic>{
      'id': 'o',
      'orderCode': 'ORD',
      'status': 'PENDING',
      'paymentStatus': 'PENDING',
      'grandTotal': 100000,
      'createdAt': '2026-11-02T01:00:00.000Z',
      'receiverName': 'Lan',
      'phone': '0901234567',
      'address': '1 Đồng Khởi',
      'pickupStore': <String, dynamic>{'id': 's', 'name': 'Quận 1'},
      'pickupAt': '2026-11-03T08:00:00.000Z',
      'items': <dynamic>[
        <String, dynamic>{
          'productName': 'Bó hồng',
          'quantity': 2,
          'subtotal': 100000,
          'imageUrl': null,
        },
      ],
    });

    expect(detail.pickupStoreName, 'Quận 1');
    expect(detail.pickupAt, isNotNull);
    expect(detail.items.single.quantity, 2);
  });
}
