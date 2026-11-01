import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:plant_flower_shared/plant_flower_shared.dart';
import '../../services/contracts/admin_categories_service.dart';

class RemoteCategoriesService implements AdminCategoriesService {
  final http.Client httpClient;
  final String baseUrl;
  final Map<String, String> Function() headersProvider;
  final void Function(http.Response res)? responseValidator;

  RemoteCategoriesService({
    required this.httpClient,
    required this.baseUrl,
    required this.headersProvider,
    this.responseValidator,
  });

  @override
  Future<List<CategoryModel>> getCategories() async {
    final uri = Uri.parse('$baseUrl/admin/categories');
    final res = await httpClient.get(uri, headers: headersProvider());
    responseValidator?.call(res);
    final data = jsonDecode(res.body)['data'] as List<dynamic>;
    return data.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<CategoryModel> addCategory(CategoryModel category) async {
    final res = await httpClient.post(
      Uri.parse('$baseUrl/admin/categories'),
      headers: headersProvider(),
      body: jsonEncode(category.toJson()),
    );
    responseValidator?.call(res);
    final data = jsonDecode(res.body)['data'];
    return CategoryModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<CategoryModel> updateCategory(CategoryModel category) async {
    final res = await httpClient.patch(
      Uri.parse('$baseUrl/admin/categories/${category.id}'),
      headers: headersProvider(),
      body: jsonEncode(category.toJson()),
    );
    responseValidator?.call(res);
    final data = jsonDecode(res.body)['data'];
    return CategoryModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteCategory(String id) async {
    final res = await httpClient.delete(
      Uri.parse('$baseUrl/admin/categories/$id'),
      headers: headersProvider(),
    );
    responseValidator?.call(res);
  }
}
