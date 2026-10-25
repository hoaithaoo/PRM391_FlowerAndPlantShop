import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:plant_flower_shared/plant_flower_shared.dart';
import '../../services/contracts/admin_dashboard_service.dart';

class RemoteDashboardService implements AdminDashboardService {
  final http.Client httpClient;
  final String baseUrl;
  final Map<String, String> Function() headersProvider;
  final void Function(http.Response res)? responseValidator;

  RemoteDashboardService({
    required this.httpClient,
    required this.baseUrl,
    required this.headersProvider,
    this.responseValidator,
  });

  @override
  Future<DashboardStatsModel> getDashboardStats({DateTime? from, DateTime? to}) async {
    final queryParams = <String, String>{
      if (from != null) 'from': from.toIso8601String(),
      if (to != null) 'to': to.toIso8601String(),
    };
    final uri = Uri.parse('$baseUrl/admin/dashboard').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final res = await httpClient.get(uri, headers: headersProvider());
    responseValidator?.call(res);
    final data = jsonDecode(res.body)['data'];
    return DashboardStatsModel.fromJson(
      data['stats'] as Map<String, dynamic>,
    );
  }
}
