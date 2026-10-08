import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../../finance/screens/finance_management_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onNavigateToOrders;
  final VoidCallback onNavigateToProducts;

  const DashboardScreen({
    super.key,
    required this.onNavigateToOrders,
    required this.onNavigateToProducts,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Tổng Quan Kinh Doanh',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textLight,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới số liệu',
            onPressed: () => context.read<DashboardCubit>().refreshStats(),
          ),
        ],
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is DashboardError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 54, color: AppColors.statusCancelled),
                    const SizedBox(height: 16),
                    Text(
                      'Không thể tải dữ liệu thống kê',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => context.read<DashboardCubit>().loadStats(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is DashboardLoaded) {
            final stats = state.stats;

            return RefreshIndicator(
              onRefresh: () => context.read<DashboardCubit>().refreshStats(),
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Greeting Banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'HỆ THỐNG TRỰC TUYẾN',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('dd/MM/yyyy').format(DateTime.now()),
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textLight.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Cửa hàng Nhà Có Hoa',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chúc bạn một ngày làm việc hiệu quả và tràn đầy năng lượng!',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.textLight.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'CHỈ SỐ TÀI CHÍNH',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Doanh thu Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Doanh thu hôm nay',
                          value: _currencyFormat.format(stats.revenueToday),
                          icon: Icons.today,
                          iconColor: AppColors.accent,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Doanh thu tháng',
                          value: _currencyFormat.format(stats.revenueMonth),
                          icon: Icons.calendar_month,
                          iconColor: AppColors.primary,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Text(
                    'TÌNH HÌNH VẬN HÀNH',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Đơn hàng & Tồn kho Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildOperationalCard(
                          title: 'Đơn chờ duyệt',
                          count: stats.pendingOrders,
                          totalText: 'Tổng ${stats.totalOrders} đơn',
                          icon: Icons.receipt_long,
                          alert: stats.pendingOrders > 0,
                          alertColor: AppColors.statusPending,
                          onTap: widget.onNavigateToOrders,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildOperationalCard(
                          title: 'Sắp hết hàng',
                          count: stats.lowStockProducts,
                          totalText: 'Tổng ${stats.totalProducts} sản phẩm',
                          icon: Icons.inventory_2_outlined,
                          alert: stats.lowStockProducts > 0,
                          alertColor: AppColors.statusCancelled,
                          onTap: widget.onNavigateToProducts,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'THAO TÁC NHANH',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick Action Buttons
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add_business, color: AppColors.primary),
                          ),
                          title: Text(
                            'Quản lý sản phẩm hoa & chậu',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text('Thêm sản phẩm, chỉnh sửa giá, kiểm kho'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: widget.onNavigateToProducts,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.accent),
                          ),
                          title: Text(
                            'Xử lý đơn hàng khách đặt',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text('Duyệt đơn mới, cập nhật vận chuyển SePay/COD'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: widget.onNavigateToOrders,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.account_balance_outlined, color: AppColors.primary),
                          ),
                          title: Text(
                            'Đối soát SePay & Xem Hóa đơn VAT',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text('Quản lý hóa đơn điện tử, đối chiếu dòng tiền SePay'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const FinanceManagementScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalCard({
    required String title,
    required int count,
    required String totalText,
    required IconData icon,
    required bool alert,
    required Color alertColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: alert ? alertColor.withValues(alpha: 0.5) : AppColors.border,
            width: alert ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: alert ? alertColor : AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: alert ? alertColor : AppColors.textHeading,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$count',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: alert ? alertColor : AppColors.textHeading,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              totalText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
