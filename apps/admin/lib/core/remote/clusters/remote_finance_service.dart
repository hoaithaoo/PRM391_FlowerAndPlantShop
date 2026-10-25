import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:plant_flower_shared/plant_flower_shared.dart';
import '../../services/contracts/admin_finance_service.dart';

class RemoteFinanceService implements AdminFinanceService {
  final http.Client httpClient;
  final String baseUrl;
  final Map<String, String> Function() headersProvider;
  final void Function(http.Response res)? responseValidator;

  RemoteFinanceService({
    required this.httpClient,
    required this.baseUrl,
    required this.headersProvider,
    this.responseValidator,
  });

  @override
  Future<List<InvoiceModel>> getInvoices({
    InvoiceStatus? status,
    String? search,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      if (status != null) 'status': status.name,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final uri = Uri.parse('$baseUrl/admin/invoices').replace(
      queryParameters: queryParams,
    );
    final res = await httpClient.get(uri, headers: headersProvider());
    responseValidator?.call(res);
    final data = jsonDecode(res.body)['data'] as List<dynamic>;
    return data.map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<InvoiceModel> getInvoiceDetail(String id) async {
    final uri = Uri.parse('$baseUrl/admin/invoices/$id');
    final res = await httpClient.get(uri, headers: headersProvider());
    responseValidator?.call(res);
    final data = jsonDecode(res.body)['data'];
    return InvoiceModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<SepayTransactionModel>> getSepayTransactions({
    bool? isMatched,
    String? search,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      if (isMatched != null) 'matched': isMatched.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final uri = Uri.parse('$baseUrl/admin/sepay-transactions').replace(
      queryParameters: queryParams,
    );
    final res = await httpClient.get(uri, headers: headersProvider());
    responseValidator?.call(res);
    final data = jsonDecode(res.body)['data'] as List<dynamic>;
    return data.map((e) => SepayTransactionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<SepayTransactionModel> manualMatchTransaction({
    required String transactionId,
    required String orderCode,
  }) async {
    final res = await httpClient.post(
      Uri.parse('$baseUrl/admin/sepay-transactions/$transactionId/match'),
      headers: headersProvider(),
      body: jsonEncode({'orderCode': orderCode}),
    );
    responseValidator?.call(res);
    return SepayTransactionModel.fromJson(jsonDecode(res.body)['data']);
  }
}
