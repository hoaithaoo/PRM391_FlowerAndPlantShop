import 'package:plant_flower_shared/plant_flower_shared.dart';

abstract class AdminAuthService {
  Future<UserProfile> loginWithEmailPassword(String email, String password);
}
