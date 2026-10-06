import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plant_flower_admin/core/network/admin_api_client.dart';
import 'package:plant_flower_admin/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:plant_flower_admin/features/dashboard/screens/dashboard_screen.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

class MockAdminApiClient extends Mock implements AdminApiClient {}

void main() {
  group('DashboardScreen Widget Tests (PRM393 Testing Requirement)', () {
    late MockAdminApiClient mockApiClient;

    const testStats = DashboardStatsModel(
      revenueToday: 1500000,
      revenueMonth: 35000000,
      totalOrders: 80,
      pendingOrders: 5,
      totalProducts: 40,
      lowStockProducts: 2,
    );

    setUp(() {
      mockApiClient = MockAdminApiClient();
    });

    testWidgets('Hiển thị các chỉ số kinh doanh chính xác khi Dashboard tải xong', (tester) async {
      when(() => mockApiClient.getDashboardStats()).thenAnswer((_) async => testStats);

      final cubit = DashboardCubit(apiClient: mockApiClient);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<DashboardCubit>.value(
            value: cubit,
            child: DashboardScreen(
              onNavigateToOrders: () {},
              onNavigateToProducts: () {},
            ),
          ),
        ),
      );

      // Trigger initial load and settle animation
      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề màn hình
      expect(find.text('Tổng Quan Kinh Doanh'), findsOneWidget);

      // Kiểm tra các nhãn chỉ số tài chính và vận hành
      expect(find.text('Doanh thu hôm nay'), findsOneWidget);
      expect(find.text('Doanh thu tháng'), findsOneWidget);
      expect(find.text('Đơn chờ duyệt'), findsOneWidget);
      expect(find.text('Sắp hết hàng'), findsOneWidget);

      // Kiểm tra số lượng
      expect(find.text('5'), findsOneWidget); // pendingOrders
      expect(find.text('2'), findsOneWidget); // lowStockProducts

      cubit.close();
    });
  });
}
