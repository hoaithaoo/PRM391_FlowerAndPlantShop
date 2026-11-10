import 'package:plant_flower_shared/plant_flower_shared.dart';

abstract class AdminDashboardService {
  Future<DashboardStatsModel> getDashboardStats({DateTime? from, DateTime? to});
}
