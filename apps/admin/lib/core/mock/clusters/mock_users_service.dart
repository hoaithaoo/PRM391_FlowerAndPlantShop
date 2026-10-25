import 'package:plant_flower_shared/plant_flower_shared.dart';
import '../../services/contracts/admin_users_service.dart';

class MockUsersService implements AdminUsersService {
  final List<UserProfile> _mockUsers = [
    UserProfile(
      id: 'admin-uuid-001',
      email: 'admin@nhacohoa.vn',
      fullName: 'Nguyễn Tiến (Admin Trưởng)',
      phone: '0901234567',
      role: UserRole.admin,
      status: AccountStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    UserProfile(
      id: 'user-uuid-101',
      email: 'phuongha@gmail.com',
      fullName: 'Nguyễn Phương Hà',
      phone: '0912345678',
      role: UserRole.user,
      status: AccountStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
    UserProfile(
      id: 'user-uuid-102',
      email: 'hoangnam@gmail.com',
      fullName: 'Lê Hoàng Nam',
      phone: '0988776655',
      role: UserRole.user,
      status: AccountStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    UserProfile(
      id: 'user-uuid-103',
      email: 'minhanh.vu@gmail.com',
      fullName: 'Vũ Minh Anh',
      phone: '0977665544',
      role: UserRole.user,
      status: AccountStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    UserProfile(
      id: 'user-uuid-104',
      email: 'baduser@spam.com',
      fullName: 'Tài Khoản Vi Phạm',
      phone: '0933221100',
      role: UserRole.user,
      status: AccountStatus.disabled,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  @override
  Future<List<UserProfile>> getUsers({
    String? search,
    UserRole? role,
    AccountStatus? status,
    int page = 1,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var list = List<UserProfile>.from(_mockUsers);
    if (role != null) {
      list = list.where((u) => u.role == role).toList();
    }
    if (status != null) {
      list = list.where((u) => u.status == status).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      list = list
          .where((u) =>
              (u.fullName?.toLowerCase().contains(q) ?? false) ||
              u.email.toLowerCase().contains(q) ||
              (u.phone?.contains(q) ?? false))
          .toList();
    }
    return list;
  }

  @override
  Future<UserProfile> getUserDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final user = _mockUsers.firstWhere(
      (u) => u.id == id,
      orElse: () => throw Exception('Không tìm thấy người dùng (USER_NOT_FOUND)'),
    );
    return user;
  }

  @override
  Future<UserProfile> updateUser(
    String id, {
    UserRole? role,
    AccountStatus? status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockUsers.indexWhere((u) => u.id == id);
    if (index != -1) {
      final current = _mockUsers[index];
      if (current.id == 'admin-uuid-001' && status == AccountStatus.disabled) {
        throw Exception('Không thể tự khóa tài khoản Admin chính mình (ADMIN_SELF_LOCK_FORBIDDEN)');
      }
      final updated = current.copyWith(
        role: role ?? current.role,
        status: status ?? current.status,
      );
      _mockUsers[index] = updated;
      return updated;
    }
    throw Exception('Không tìm thấy người dùng (USER_NOT_FOUND)');
  }
}
