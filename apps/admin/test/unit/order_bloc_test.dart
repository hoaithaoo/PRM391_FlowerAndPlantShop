import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plant_flower_admin/core/network/admin_api_client.dart';
import 'package:plant_flower_admin/features/orders/bloc/order_bloc.dart';
import 'package:plant_flower_admin/features/orders/bloc/order_event.dart';
import 'package:plant_flower_admin/features/orders/bloc/order_state.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

class MockAdminApiClient extends Mock implements AdminApiClient {}

void main() {
  group('OrderBloc Unit Tests (Spec 9.11, 9.12 & Spec 11)', () {
    late MockAdminApiClient mockApiClient;
    late OrderBloc orderBloc;

    final testOrder = OrderModel(
      id: 'ord_101',
      orderCode: 'NCH-2026-001',
      customerName: 'Nguyễn Phương Hà',
      customerPhone: '0912345678',
      customerAddress: '123 Nguyễn Huệ, Quận 1, TP.HCM',
      totalAmount: 390000,
      status: OrderStatus.pending,
      paymentStatus: PaymentStatus.paid,
      paymentMethod: 'SEPAY (QR Chuyển Khoản)',
      createdAt: DateTime.now(),
      items: const [],
    );

    setUp(() {
      mockApiClient = MockAdminApiClient();
      orderBloc = OrderBloc(apiClient: mockApiClient);
    });

    tearDown(() {
      orderBloc.close();
    });

    test('Trạng thái ban đầu phải là OrderInitial', () {
      expect(orderBloc.state, equals(OrderInitial()));
    });

    blocTest<OrderBloc, OrderState>(
      'FetchOrdersEvent tải danh sách đơn hàng thành công',
      build: () {
        when(() => mockApiClient.getOrders(status: any(named: 'status')))
            .thenAnswer((_) async => [testOrder]);
        return orderBloc;
      },
      act: (bloc) => bloc.add(const FetchOrdersEvent()),
      expect: () => [
        OrderLoading(),
        OrderLoaded(orders: [testOrder]),
      ],
      verify: (_) {
        verify(() => mockApiClient.getOrders(status: null)).called(1);
      },
    );

    blocTest<OrderBloc, OrderState>(
      'UpdateOrderStatusEvent chuyển trạng thái hợp lệ (PENDING -> CONFIRMED) thành công',
      build: () {
        when(
          () => mockApiClient.updateOrderStatus('ord_101', OrderStatus.confirmed),
        ).thenAnswer((_) async => testOrder.copyWith(status: OrderStatus.confirmed));
        when(() => mockApiClient.getOrders(status: any(named: 'status')))
            .thenAnswer((_) async => [testOrder.copyWith(status: OrderStatus.confirmed)]);
        return orderBloc;
      },
      act: (bloc) => bloc.add(
        const UpdateOrderStatusEvent(
          orderId: 'ord_101',
          newStatus: OrderStatus.confirmed,
        ),
      ),
      expect: () => [
        isA<OrderActionSuccess>().having(
          (s) => s.message,
          'thông báo cập nhật thành công',
          contains('Đã xác nhận'),
        ),
        OrderLoading(),
        isA<OrderLoaded>(),
      ],
      verify: (_) {
        verify(
          () => mockApiClient.updateOrderStatus('ord_101', OrderStatus.confirmed),
        ).called(1);
      },
    );

    blocTest<OrderBloc, OrderState>(
      'UpdateOrderStatusEvent khi đơn đã kết thúc (DELIVERED) bắn lỗi ORDER_STATUS_INVALID',
      build: () {
        when(
          () => mockApiClient.updateOrderStatus('ord_101', OrderStatus.cancelled),
        ).thenThrow(
          Exception(
            'Đơn hàng đã kết thúc (Đã giao), không thể thay đổi trạng thái (ORDER_STATUS_INVALID)',
          ),
        );
        return orderBloc;
      },
      act: (bloc) => bloc.add(
        const UpdateOrderStatusEvent(
          orderId: 'ord_101',
          newStatus: OrderStatus.cancelled,
        ),
      ),
      expect: () => [
        const OrderError(
          'Đơn hàng đã kết thúc (Đã giao), không thể thay đổi trạng thái (ORDER_STATUS_INVALID)',
        ),
      ],
    );
  });
}
