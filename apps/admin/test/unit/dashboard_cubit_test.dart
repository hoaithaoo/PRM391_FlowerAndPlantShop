import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plant_flower_admin/core/network/admin_api_client.dart';
import 'package:plant_flower_admin/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:plant_flower_admin/features/dashboard/cubit/dashboard_state.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

class MockAdminApiClient extends Mock implements AdminApiClient {}

void main() {
  group('DashboardCubit Unit Tests (Spec 9.1 & Phase 4)', () {
    late MockAdminApiClient mockApiClient;
    late DashboardCubit dashboardCubit;

    const testStats = DashboardStatsModel(
      revenueToday: 1500000,
      revenueMonth: 35000000,
      totalOrders: 80,
      pendingOrders: 5,
      totalProducts: 40,
      lowStockProducts: 2,
      totalUsers: 120,
      paidRevenue: 32000000,
      dateRangeLabel: '30 ngày qua',
    );

    setUp(() {
      mockApiClient = MockAdminApiClient();
      dashboardCubit = DashboardCubit(apiClient: mockApiClient);
    });

    tearDown(() {
      dashboardCubit.close();
    });

    test('Trạng thái ban đầu phải là DashboardInitial', () {
      expect(dashboardCubit.state, equals(DashboardInitial()));
    });

    blocTest<DashboardCubit, DashboardState>(
      'loadStats() tải chỉ số KPI thành công',
      build: () {
        when(() => mockApiClient.getDashboardStats(
              from: any(named: 'from'),
              to: any(named: 'to'),
            )).thenAnswer((_) async => testStats);
        return dashboardCubit;
      },
      act: (cubit) => cubit.loadStats(),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardLoaded>()
            .having((s) => s.stats.totalOrders, 'totalOrders', 80)
            .having((s) => s.stats.totalUsers, 'totalUsers', 120)
            .having((s) => s.stats.paidRevenue, 'paidRevenue', 32000000),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'setDateRange() lọc số liệu theo ngày thành công',
      build: () {
        when(() => mockApiClient.getDashboardStats(
              from: any(named: 'from'),
              to: any(named: 'to'),
            )).thenAnswer((_) async => testStats.copyWith(
              dateRangeLabel: '7 ngày qua',
              totalOrders: 25,
            ));
        return dashboardCubit;
      },
      act: (cubit) => cubit.setDateRange(
        DateTime.now().subtract(const Duration(days: 7)),
        DateTime.now(),
      ),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardLoaded>()
            .having((s) => s.stats.dateRangeLabel, 'label', '7 ngày qua')
            .having((s) => s.stats.totalOrders, 'totalOrders', 25),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'loadStats() phát ra DashboardError khi API gặp lỗi',
      build: () {
        when(() => mockApiClient.getDashboardStats(
              from: any(named: 'from'),
              to: any(named: 'to'),
            )).thenThrow(Exception('Lỗi kết nối máy chủ'));
        return dashboardCubit;
      },
      act: (cubit) => cubit.loadStats(),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardError>().having((s) => s.message, 'message', 'Lỗi kết nối máy chủ'),
      ],
    );
  });
}
