import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/contracts/admin_faqs_service.dart';

/// Gọi API thật /admin/faqs (GET, POST, PATCH /:id, DELETE /:id).
/// responseValidator ném lỗi khi status không phải 2xx (dùng chung với các service khác).
class RemoteFaqsService implements AdminFaqsService {
  final http.Client httpClient;
  final String baseUrl;
  final Map<String, String> Function() headersProvider;
  final void Function(http.Response res)? responseValidator;

  RemoteFaqsService({
    required this.httpClient,
    required this.baseUrl,
    required this.headersProvider,
    this.responseValidator,
  });

  // Không có id -> /admin/faqs; có id -> /admin/faqs/{id}.
  Uri _uri([String? id]) => Uri.parse(
      '$baseUrl/admin/faqs${id == null ? '' : '/${Uri.encodeComponent(id)}'}');

  AdminFaq _parse(http.Response res) {
    responseValidator?.call(res);
    return AdminFaq.fromJson(jsonDecode(res.body)['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<AdminFaq>> getFaqs() async {
    final res = await httpClient.get(_uri(), headers: headersProvider());
    responseValidator?.call(res);
    return (jsonDecode(res.body)['data']['items'] as List<dynamic>)
        .map((e) => AdminFaq.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AdminFaq> createFaq(AdminFaq faq) async => _parse(await httpClient
      .post(_uri(), headers: headersProvider(), body: jsonEncode(faq.toBody())));

  @override
  Future<AdminFaq> updateFaq(AdminFaq faq) async => _parse(await httpClient
      .patch(_uri(faq.id), headers: headersProvider(), body: jsonEncode(faq.toBody())));

  @override
  Future<void> deleteFaq(String id) async {
    final res = await httpClient.delete(_uri(id), headers: headersProvider());
    responseValidator?.call(res);
  }
}
