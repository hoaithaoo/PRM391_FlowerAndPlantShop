import 'package:plant_flower_shared/plant_flower_shared.dart';
import '../../services/contracts/admin_orders_service.dart';

class MockOrdersService implements AdminOrdersService {
  final List<OrderModel> _mockOrders = [
    OrderModel(
      id: 'ord_101',
      orderCode: 'NCH-2026-001',
      customerName: 'Trần Thị Thu Hà',
      customerPhone: '0988112233',
      customerAddress: '128 Nguyễn Đình Chiểu, P. Đa Kao, Quận 1, TP.HCM',
      totalAmount: 390000,
      status: OrderStatus.pending,
      paymentStatus: PaymentStatus.paid,
      paymentMethod: 'SEPAY (QR Chuyển Khoản)',
      note: 'Giao giờ hành chính, gọi trước 15 phút',
      createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
      items: const [
        OrderItemModel(
          id: 'item_1',
          productId: 'p1',
          productName: 'Sen Hồng Tháp Mười (Bình Gốm Đất Nung)',
          quantity: 1,
          unitPrice: 390000,
          subtotal: 390000,
        ),
      ],
    ),
    OrderModel(
      id: 'ord_102',
      orderCode: 'NCH-2026-002',
      customerName: 'Lê Hoàng Nam',
      customerPhone: '0912345678',
      customerAddress: 'Tòa nhà Bitexco, Bến Nghé, Quận 1, TP.HCM',
      totalAmount: 570000,
      status: OrderStatus.confirmed,
      paymentStatus: PaymentStatus.paid,
      paymentMethod: 'SEPAY (QR Chuyển Khoản)',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      items: const [
        OrderItemModel(
          id: 'item_2',
          productId: 'p2',
          productName: 'Bó Cẩm Tú Cầu Xanh Lam Đà Lạt',
          quantity: 1,
          unitPrice: 320000,
          subtotal: 320000,
        ),
        OrderItemModel(
          id: 'item_3',
          productId: 'p3',
          productName: 'Cây Kim Tiền Chiêu Tài',
          quantity: 1,
          unitPrice: 220000,
          subtotal: 220000,
        ),
      ],
    ),
    OrderModel(
      id: 'ord_103',
      orderCode: 'NCH-2026-003',
      customerName: 'Vũ Minh Anh',
      customerPhone: '0977665544',
      customerAddress: '45 Lê Duẩn, Quận 1, TP.HCM',
      totalAmount: 280000,
      status: OrderStatus.shipping,
      paymentStatus: PaymentStatus.paid,
      paymentMethod: 'COD',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      items: const [
        OrderItemModel(
          id: 'item_4',
          productId: 'p4',
          productName: 'Bó Hoa Hướng Dương Nắng Mới',
          quantity: 1,
          unitPrice: 280000,
          subtotal: 280000,
        ),
      ],
    ),
  ];

  @override
  Future<List<OrderModel>> getOrders({
    OrderStatus? status,
    String? search,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var list = List<OrderModel>.from(_mockOrders);
    if (status != null) {
      list = list.where((o) => o.status == status).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      list = list
          .where((o) =>
              o.orderCode.toLowerCase().contains(q) ||
              o.customerName.toLowerCase().contains(q) ||
              o.customerPhone.contains(q))
          .toList();
    }
    return list;
  }

  @override
  Future<OrderModel> updateOrderStatus(String id, OrderStatus newStatus) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockOrders.indexWhere((o) => o.id == id);
    if (index != -1) {
      final currentOrder = _mockOrders[index];
      if (currentOrder.status == OrderStatus.delivered) {
        throw Exception('Đơn hàng đã hoàn tất, không thể đổi trạng thái (ORDER_STATUS_INVALID)');
      }
      final updated = currentOrder.copyWith(status: newStatus);
      _mockOrders[index] = updated;
      return updated;
    }
    throw Exception('Không tìm thấy đơn hàng (ORDER_NOT_FOUND)');
  }
}
