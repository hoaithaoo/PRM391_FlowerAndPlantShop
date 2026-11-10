import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/contracts/admin_incidents_service.dart';

/// Gọi API thật /admin/incidents: lấy danh sách phiếu sự cố và cập nhật trạng thái/ghi chú.
class RemoteIncidentsService implements AdminIncidentsService {
  final http.Client httpClient;
  final String baseUrl;
  final Map<String, String> Function() headersProvider;
  final void Function(http.Response res)? responseValidator;

  RemoteIncidentsService({
    required this.httpClient,
    required this.baseUrl,
    required this.headersProvider,
    this.responseValidator,
  });

  @override
  Future<List<IncidentModel>> getIncidents({
    String? status,
    String? category,
    String? search,
  }) async {
    // Giới hạn: lấy 100 phiếu mới nhất, thêm phân trang khi vượt quá.
    final uri = Uri.parse('$baseUrl/admin/incidents').replace(
      queryParameters: <String, String>{
        'limit': '100',
        'status': ?status,
        'category': ?category,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final res = await httpClient.get(uri, headers: headersProvider());
    responseValidator?.call(res);
    final items = jsonDecode(res.body)['data']['items'] as List<dynamic>;
    return items
        .map((e) => IncidentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<IncidentModel> updateIncident(
    String id, {
    required String status,
    String? adminNote,
  }) async {
    // Backend tự gửi thông báo cho khách nếu trạng thái thay đổi.
    final res = await httpClient.patch(
      Uri.parse('$baseUrl/admin/incidents/${Uri.encodeComponent(id)}'),
      headers: headersProvider(),
      body: jsonEncode({'status': status, 'adminNote': adminNote}),
    );
    responseValidator?.call(res);
    return IncidentModel.fromJson(
      jsonDecode(res.body)['data'] as Map<String, dynamic>,
    );
  }
}
