import 'package:plant_flower_shared/plant_flower_shared.dart';
import '../../services/contracts/admin_auth_service.dart';

class MockAuthService implements AdminAuthService {
  final void Function(String? token)? onTokenGenerated;

  MockAuthService({this.onTokenGenerated});

  @override
  Future<UserProfile> loginWithEmailPassword(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (email == 'admin@nhacohoa.vn' || email.contains('admin')) {
      final token = 'mock_admin_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
      onTokenGenerated?.call(token);
      return const UserProfile(
        id: 'admin-uuid-001',
        email: 'admin@nhacohoa.vn',
        fullName: 'Nguyễn Tiến (Admin Trưởng)',
        phone: '0901234567',
        role: UserRole.admin,
        status: AccountStatus.active,
      );
    } else {
      throw Exception('Tài khoản không có quyền ADMIN (403 FORBIDDEN)');
    }
  }
}
