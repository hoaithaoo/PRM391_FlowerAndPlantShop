import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:plant_flower_shared/plant_flower_shared.dart';
import '../../services/contracts/admin_orders_service.dart';

class RemoteOrdersService implements AdminOrdersService {
  final http.Client httpClient;
  final String baseUrl;
  final Map<String, String> Function() headersProvider;
  final void Function(http.Response res)? responseValidator;

  RemoteOrdersService({
    required this.httpClient,
    required this.baseUrl,
    required this.headersProvider,
    this.responseValidator,
  });

  @override
  Future<List<OrderModel>> getOrders({
    OrderStatus? status,
    String? search,
  }) async {
    final queryParams = <String, String>{
      if (status != null) 'status': status.name,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final uri = Uri.parse('$baseUrl/admin/orders').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final res = await httpClient.get(uri, headers: headersProvider());
    responseValidator?.call(res);
    final data = jsonDecode(res.body)['data'] as List<dynamic>;
    return data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<OrderModel> updateOrderStatus(String id, OrderStatus newStatus) async {
    final res = await httpClient.put(
      Uri.parse('$baseUrl/admin/orders/$id/status'),
      headers: headersProvider(),
      body: jsonEncode({'status': newStatus.name}),
    );
    responseValidator?.call(res);
    final data = jsonDecode(res.body)['data'];
    return OrderModel.fromJson(data as Map<String, dynamic>);
  }
}
