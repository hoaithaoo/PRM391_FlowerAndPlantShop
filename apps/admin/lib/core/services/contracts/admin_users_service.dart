import 'package:plant_flower_shared/plant_flower_shared.dart';

abstract class AdminUsersService {
  Future<List<UserProfile>> getUsers({String? search, UserRole? role, AccountStatus? status, int page = 1});
  Future<UserProfile> getUserDetail(String id);
  Future<UserProfile> updateUser(String id, {UserRole? role, AccountStatus? status});
}
