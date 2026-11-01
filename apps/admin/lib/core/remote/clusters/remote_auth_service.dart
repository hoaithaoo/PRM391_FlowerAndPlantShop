import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:plant_flower_shared/plant_flower_shared.dart';
import '../../network/api_exceptions.dart';
import '../../services/contracts/admin_auth_service.dart';

class RemoteAuthService implements AdminAuthService {
  final http.Client httpClient;
  final String baseUrl;
  final Map<String, String> Function() headersProvider;
  final void Function(http.Response res)? responseValidator;
  final void Function(String? token)? onTokenSaved;

  RemoteAuthService({
    required this.httpClient,
    required this.baseUrl,
    required this.headersProvider,
    this.responseValidator,
    this.onTokenSaved,
  });

  @override
  Future<UserProfile> loginWithEmailPassword(String email, String password) async {
    final res = await httpClient.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: headersProvider(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    responseValidator?.call(res);
    final data = jsonDecode(res.body)['data'];
    final profile = UserProfile.fromJson(
      data['profile'] as Map<String, dynamic>,
    );
    // App quản trị chỉ cho tài khoản ADMIN.
    if (profile.role != UserRole.admin) {
      throw const ForbiddenException();
    }
    final token = data['token'] as String?;
    if (token != null) {
      onTokenSaved?.call(token);
    }
    return profile;
  }
}
