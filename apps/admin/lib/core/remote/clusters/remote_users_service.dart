import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:plant_flower_shared/plant_flower_shared.dart';
import '../../services/contracts/admin_users_service.dart';

class RemoteUsersService implements AdminUsersService {
  final http.Client httpClient;
  final String baseUrl;
  final Map<String, String> Function() headersProvider;
  final void Function(http.Response res)? responseValidator;

  RemoteUsersService({
    required this.httpClient,
    required this.baseUrl,
    required this.headersProvider,
    this.responseValidator,
  });

  static List<dynamic> _listFrom(dynamic data) =>
      data is List ? data : (data as Map<String, dynamic>)['items'] as List<dynamic>;

  @override
  Future<List<UserProfile>> getUsers({
    String? search,
    UserRole? role,
    AccountStatus? status,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (role != null) 'role': role.toApiString(),
      if (status != null) 'status': status.toApiString(),
    };
    final uri = Uri.parse('$baseUrl/admin/users').replace(
      queryParameters: queryParams,
    );
    final res = await httpClient.get(uri, headers: headersProvider());
    responseValidator?.call(res);
    final data = _listFrom(jsonDecode(res.body)['data']);
    return data.map((e) => UserProfile.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<UserProfile> getUserDetail(String id) async {
    final uri = Uri.parse('$baseUrl/admin/users/$id');
    final res = await httpClient.get(uri, headers: headersProvider());
    responseValidator?.call(res);
    final data = jsonDecode(res.body)['data'];
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<UserProfile> updateUser(
    String id, {
    UserRole? role,
    AccountStatus? status,
  }) async {
    final body = <String, dynamic>{
      if (role != null) 'role': role.toApiString(),
      if (status != null) 'status': status.toApiString(),
    };
    final uri = Uri.parse('$baseUrl/admin/users/$id');
    final res = await httpClient.patch(
      uri,
      headers: headersProvider(),
      body: jsonEncode(body),
    );
    responseValidator?.call(res);
    final data = jsonDecode(res.body)['data'];
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }
}
