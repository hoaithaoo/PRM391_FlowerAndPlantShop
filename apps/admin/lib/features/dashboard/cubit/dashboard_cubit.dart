import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/admin_api_client.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final AdminApiClient apiClient;
  DateTime? currentFrom;
  DateTime? currentTo;

  DashboardCubit({required this.apiClient}) : super(DashboardInitial());

  Future<void> loadStats({DateTime? from, DateTime? to}) async {
    currentFrom = from;
    currentTo = to;
    emit(DashboardLoading());
    try {
      final stats = await apiClient.getDashboardStats(from: from, to: to);
      emit(DashboardLoaded(stats));
    } catch (e) {
      emit(DashboardError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> refreshStats() async {
    try {
      final stats = await apiClient.getDashboardStats(from: currentFrom, to: currentTo);
      emit(DashboardLoaded(stats));
    } catch (e) {
      emit(DashboardError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> setDateRange(DateTime? from, DateTime? to) async {
    await loadStats(from: from, to: to);
  }
}
