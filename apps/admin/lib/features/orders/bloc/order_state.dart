import 'package:equatable/equatable.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderLoaded extends OrderState {
  final List<OrderModel> orders;
  final OrderStatus? currentFilter;

  const OrderLoaded({
    required this.orders,
    this.currentFilter,
  });

  @override
  List<Object?> get props => [orders, currentFilter];
}

class OrderActionSuccess extends OrderState {
  final String message;

  const OrderActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class OrderError extends OrderState {
  final String message;

  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}
