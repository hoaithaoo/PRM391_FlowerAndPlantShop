import 'package:plant_flower_shared/plant_flower_shared.dart';

abstract class AdminOrdersService {
  Future<List<OrderModel>> getOrders({OrderStatus? status, String? search});
  Future<OrderModel> updateOrderStatus(String id, OrderStatus newStatus);
}
