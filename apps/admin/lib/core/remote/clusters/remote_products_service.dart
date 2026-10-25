import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:plant_flower_shared/plant_flower_shared.dart';
import '../../services/contracts/admin_products_service.dart';

class RemoteProductsService implements AdminProductsService {
  final http.Client httpClient;
  final String baseUrl;
  final Map<String, String> Function() headersProvider;
  final void Function(http.Response res)? responseValidator;

  RemoteProductsService({
    required this.httpClient,
    required this.baseUrl,
    required this.headersProvider,
    this.responseValidator,
  });

  @override
  Future<List<ProductModel>> getProducts({
    String? categoryId,
    String? search,
  }) async {
    final queryParams = <String, String>{
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final uri = Uri.parse('$baseUrl/admin/products').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final res = await httpClient.get(uri, headers: headersProvider());
    responseValidator?.call(res);
    final data = jsonDecode(res.body)['data'] as List<dynamic>;
    return data.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<ProductModel> addProduct(ProductModel product) async {
    final res = await httpClient.post(
      Uri.parse('$baseUrl/admin/products'),
      headers: headersProvider(),
      body: jsonEncode(product.toJson()),
    );
    responseValidator?.call(res);
    final data = jsonDecode(res.body)['data'];
    return ProductModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    final res = await httpClient.put(
      Uri.parse('$baseUrl/admin/products/${product.id}'),
      headers: headersProvider(),
      body: jsonEncode(product.toJson()),
    );
    responseValidator?.call(res);
    final data = jsonDecode(res.body)['data'];
    return ProductModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteProduct(String id) async {
    final res = await httpClient.delete(
      Uri.parse('$baseUrl/admin/products/$id'),
      headers: headersProvider(),
    );
    responseValidator?.call(res);
  }
}
