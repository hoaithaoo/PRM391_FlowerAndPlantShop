import 'package:equatable/equatable.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class FetchOrdersEvent extends OrderEvent {
  final OrderStatus? statusFilter;

  const FetchOrdersEvent({this.statusFilter});

  @override
  List<Object?> get props => [statusFilter];
}

class UpdateOrderStatusEvent extends OrderEvent {
  final String orderId;
  final OrderStatus newStatus;

  const UpdateOrderStatusEvent({
    required this.orderId,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [orderId, newStatus];
}
