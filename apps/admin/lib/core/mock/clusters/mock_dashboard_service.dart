import 'package:plant_flower_shared/plant_flower_shared.dart';
import '../../services/contracts/admin_dashboard_service.dart';

class MockDashboardService implements AdminDashboardService {
  @override
  Future<DashboardStatsModel> getDashboardStats({DateTime? from, DateTime? to}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    double scale = 1.0;
    String label = '30 ngày qua';
    if (from != null && to != null) {
      final days = to.difference(from).inDays.abs() + 1;
      if (days <= 1) {
        scale = 0.08;
        label = 'Hôm nay';
      } else if (days <= 7) {
        scale = 0.35;
        label = '7 ngày qua';
      } else if (days <= 31) {
        scale = 1.0;
        label = '30 ngày qua';
      } else {
        scale = days / 30.0;
        label = 'Tùy chỉnh ($days ngày)';
      }
    }

    final totalOrders = (142 * scale).round().clamp(1, 1000);
    final paidRevenue = 74650000 * scale;
    final netProfit = paidRevenue * 0.385; // 38.5% margin

    final dailyProfits = [
      const DailyProfitRecord(
        date: '14/10',
        revenue: 3850000,
        cost: 2350000,
        profit: 1500000,
        profitMargin: 38.9,
        orderCount: 8,
      ),
      const DailyProfitRecord(
        date: '13/10',
        revenue: 4200000,
        cost: 2500000,
        profit: 1700000,
        profitMargin: 40.5,
        orderCount: 11,
      ),
      const DailyProfitRecord(
        date: '12/10',
        revenue: 4950000,
        cost: 2950000,
        profit: 2000000,
        profitMargin: 40.4,
        orderCount: 13,
      ),
      const DailyProfitRecord(
        date: '11/10',
        revenue: 3600000,
        cost: 2200000,
        profit: 1400000,
        profitMargin: 38.9,
        orderCount: 9,
      ),
      const DailyProfitRecord(
        date: '10/10',
        revenue: 6100000,
        cost: 3600000,
        profit: 2500000,
        profitMargin: 41.0,
        orderCount: 16,
      ),
      const DailyProfitRecord(
        date: '09/10',
        revenue: 3200000,
        cost: 1950000,
        profit: 1250000,
        profitMargin: 39.1,
        orderCount: 8,
      ),
      const DailyProfitRecord(
        date: '08/10',
        revenue: 4500000,
        cost: 2700000,
        profit: 1800000,
        profitMargin: 40.0,
        orderCount: 12,
      ),
      const DailyProfitRecord(
        date: '07/10',
        revenue: 3900000,
        cost: 2400000,
        profit: 1500000,
        profitMargin: 38.5,
        orderCount: 10,
      ),
      const DailyProfitRecord(
        date: '06/10',
        revenue: 3100000,
        cost: 1950000,
        profit: 1150000,
        profitMargin: 37.1,
        orderCount: 7,
      ),
      const DailyProfitRecord(
        date: '05/10',
        revenue: 5600000,
        cost: 3300000,
        profit: 2300000,
        profitMargin: 41.0,
        orderCount: 14,
      ),
      const DailyProfitRecord(
        date: '04/10',
        revenue: 2900000,
        cost: 1800000,
        profit: 1100000,
        profitMargin: 37.9,
        orderCount: 6,
      ),
      const DailyProfitRecord(
        date: '03/10',
        revenue: 3400000,
        cost: 2100000,
        profit: 1300000,
        profitMargin: 38.2,
        orderCount: 8,
      ),
      const DailyProfitRecord(
        date: '02/10',
        revenue: 4100000,
        cost: 2450000,
        profit: 1650000,
        profitMargin: 40.2,
        orderCount: 10,
      ),
      const DailyProfitRecord(
        date: '01/10',
        revenue: 3700000,
        cost: 2300000,
        profit: 1400000,
        profitMargin: 37.8,
        orderCount: 9,
      ),
    ];

    return DashboardStatsModel(
      revenueToday: 1850000 * scale,
      revenueMonth: paidRevenue,
      paidRevenue: paidRevenue,
      netProfit: netProfit,
      profitMargin: 38.5,
      totalOrders: totalOrders,
      pendingOrders: (5 * scale).round().clamp(0, 50),
      totalProducts: 48,
      lowStockProducts: 3,
      totalUsers: 136,
      dailyProfits: dailyProfits,
      dateRangeLabel: label,
      from: from,
      to: to,
    );
  }
}
