import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/admin_api_client.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final AdminApiClient apiClient;

  OrderBloc({required this.apiClient}) : super(OrderInitial()) {
    on<FetchOrdersEvent>(_onFetchOrders);
    on<UpdateOrderStatusEvent>(_onUpdateOrderStatus);
  }

  Future<void> _onFetchOrders(FetchOrdersEvent event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final orders = await apiClient.getOrders(status: event.statusFilter);
      emit(OrderLoaded(orders: orders, currentFilter: event.statusFilter));
    } catch (e) {
      emit(OrderError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateOrderStatus(UpdateOrderStatusEvent event, Emitter<OrderState> emit) async {
    try {
      await apiClient.updateOrderStatus(event.orderId, event.newStatus);
      emit(OrderActionSuccess('Cập nhật trạng thái đơn #${event.orderId} thành "${event.newStatus.label}"!'));
      
      final currentFilter = (state is OrderLoaded) ? (state as OrderLoaded).currentFilter : null;
      add(FetchOrdersEvent(statusFilter: currentFilter));
    } catch (e) {
      emit(OrderError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
