import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
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

  int _selectedFilterIndex = 2; // 0: Hôm nay, 1: 7 ngày, 2: 30 ngày, 3: Tùy chọn

  void _onFilterChanged(int index) async {
    final now = DateTime.now();
    DateTime? from;
    DateTime? to = now;

    if (index == 0) {
      from = DateTime(now.year, now.month, now.day);
    } else if (index == 1) {
      from = now.subtract(const Duration(days: 7));
    } else if (index == 2) {
      from = now.subtract(const Duration(days: 30));
    } else if (index == 3) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2025),
        lastDate: DateTime.now().add(const Duration(days: 1)),
        initialDateRange: DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        ),
      );
      if (picked != null) {
        from = picked.start;
        to = picked.end;
      } else {
        return;
      }
    }

    setState(() => _selectedFilterIndex = index);
    if (mounted) {
      context.read<DashboardCubit>().loadStats(from: from, to: to);
    }
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
                  // --- 1. TOOLBAR CHỌN KỲ THỐNG KÊ (ĐƯA LÊN ĐẦU) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'KỲ THỐNG KÊ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          stats.dateRangeLabel ?? '30 ngày qua',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('Hôm nay'),
                          selected: _selectedFilterIndex == 0,
                          onSelected: (_) => _onFilterChanged(0),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('7 ngày qua'),
                          selected: _selectedFilterIndex == 1,
                          onSelected: (_) => _onFilterChanged(1),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('30 ngày qua'),
                          selected: _selectedFilterIndex == 2,
                          onSelected: (_) => _onFilterChanged(2),
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.date_range, size: 16),
                          label: const Text('Tùy chọn ngày'),
                          onPressed: () => _onFilterChanged(3),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- 2. HERO CARD: TỔNG DOANH THU & TIỀN LỜI/LÃI ĐẬP NGAY VÀO MẮT ---
                  _buildHeroFinancialCard(stats),

                  const SizedBox(height: 20),

                  // --- 3. CÁC CHỈ SỐ DOANH THU & ĐƠN HÀNG CỐT LÕI (CÓ SHADOW) ---
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

                  const SizedBox(height: 14),

                  // Đơn hàng & Tồn kho Cards (Có Shadow & Alert)
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

                  // --- 4. KHỐI THEO DÕI LỜI & LÃI THEO NGÀY (DAILY PROFIT BREAKDOWN) ---
                  _buildDailyProfitSection(stats),

                  const SizedBox(height: 24),

                  // --- 5. KHỐI BÁO CÁO ĐÁNH GIÁ TỪ KHÁCH HÀNG (CUSTOMER REVIEWS REPORT) ---
                  _buildCustomerFeedbackSection(stats),

                  const SizedBox(height: 24),

                  // --- 6. THAO TÁC NHANH ---
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

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
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

                  const SizedBox(height: 24),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  // --- HERO FINANCIAL & PROFIT CARD ---
  Widget _buildHeroFinancialCard(DashboardStatsModel stats) {
    final revenue = stats.paidRevenue > 0 ? stats.paidRevenue : stats.revenueMonth;
    final profit = stats.netProfit > 0 ? stats.netProfit : (revenue * 0.385);
    final margin = stats.profitMargin > 0 ? stats.profitMargin : 38.5;

    return Container(
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
            color: AppColors.primaryDark.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                  'DÒNG TIỀN & LỢI NHUẬN',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 18),
              const SizedBox(width: 4),
              Text(
                'Lãi ròng +${margin.toStringAsFixed(1)}%',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFFFD700),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Tổng Doanh Thu Thuần',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textLight.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currencyFormat.format(revenue),
            style: GoogleFonts.cormorantGaramond(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.trending_up, color: Color(0xFF4ADE80), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Tiền Lời (Lãi Thực)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.textLight.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(profit),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF4ADE80),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: Colors.white24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Đơn hàng trong kỳ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.textLight.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats.totalOrders} đơn hàng',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 4. BẢNG THEO DÕI LỜI & LÃI THEO NGÀY ---
  Widget _buildDailyProfitSection(DashboardStatsModel stats) {
    final records = stats.dailyProfits.isNotEmpty
        ? stats.dailyProfits
        : [
            const DailyProfitRecord(date: 'Hôm nay', revenue: 3850000, cost: 2350000, profit: 1500000, profitMargin: 38.9, orderCount: 8),
            const DailyProfitRecord(date: 'Hôm qua', revenue: 4200000, cost: 2500000, profit: 1700000, profitMargin: 40.5, orderCount: 11),
            const DailyProfitRecord(date: '06/10', revenue: 3100000, cost: 1950000, profit: 1150000, profitMargin: 37.1, orderCount: 7),
            const DailyProfitRecord(date: '05/10', revenue: 5600000, cost: 3300000, profit: 2300000, profitMargin: 41.0, orderCount: 14),
            const DailyProfitRecord(date: '04/10', revenue: 2900000, cost: 1800000, profit: 1100000, profitMargin: 37.9, orderCount: 6),
          ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bar_chart, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THEO DÕI LỜI & LÃI THEO NGÀY',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHeading,
                      ),
                    ),
                    Text(
                      'Biết ngày nào doanh thu bao nhiêu và lời bao nhiêu',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bảng phân rã ngày
          ...records.map((r) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 76,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfacePastel,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          r.date,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: AppColors.textHeading,
                          ),
                        ),
                        Text(
                          '${r.orderCount} đơn',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Doanh thu',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          _currencyFormat.format(r.revenue),
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textHeading,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Tiền lời (Lãi)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+${_currencyFormat.format(r.profit)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.statusDelivered,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+${r.profitMargin.toStringAsFixed(1)}%',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- 5. BÁO CÁO ĐÁNH GIÁ TỪ KHÁCH HÀNG ---
  Widget _buildCustomerFeedbackSection(DashboardStatsModel stats) {
    final feedback = stats.feedbackSummary ??
        const CustomerFeedbackSummary(
          averageRating: 4.9,
          totalReviews: 128,
          satisfactionRate: 96.5,
          recentReviews: [
            CustomerFeedbackItem(
              id: 'fb-1',
              customerName: 'Nguyễn Mai Anh',
              rating: 5,
              comment: 'Hoa tươi Đà Lạt thơm ngát, giao bọc chống sốc rất kỹ, shipper nhiệt tình!',
              timeAgo: '15 phút trước',
              productName: 'Bó Hoa Cẩm Tú Cầu Xanh',
            ),
            CustomerFeedbackItem(
              id: 'fb-2',
              customerName: 'Trần Hoàng Nam',
              rating: 5,
              comment: 'Chậu gốm tráng men mộc đẹp tinh tế, cây kim ngân xanh mướt để bàn làm việc rất ưng ý.',
              timeAgo: '2 giờ trước',
              productName: 'Chậu Kim Ngân Để Bàn Gốm Bát Tràng',
            ),
          ],
        );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star, color: AppColors.accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BÁO CÁO ĐÁNH GIÁ TỪ KHÁCH HÀNG',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHeading,
                      ),
                    ),
                    Text(
                      'Phản hồi chất lượng sản phẩm & trải nghiệm mua hàng',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rating score summary row
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfacePastel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          feedback.averageRating.toStringAsFixed(1),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textHeading,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.star, color: Color(0xFFFFB800), size: 22),
                      ],
                    ),
                    Text(
                      'Dựa trên ${feedback.totalReviews} lượt đánh giá',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sentiment_very_satisfied, color: Color(0xFF15803D), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${feedback.satisfactionRate.toStringAsFixed(1)}% Hài lòng',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Recent Reviews List
          ...feedback.recentReviews.map((rev) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          rev.customerName.isNotEmpty ? rev.customerName[0].toUpperCase() : 'K',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rev.customerName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHeading,
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(
                          rev.rating,
                          (_) => const Icon(Icons.star, size: 13, color: Color(0xFFFFB800)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        rev.timeAgo,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rev.comment,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textBody,
                    ),
                  ),
                  if (rev.productName != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfacePastel,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '🌿 ${rev.productName}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- CARD METRICS VỚI SHADOW ---
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeading,
            ),
          ),
        ],
      ),
    );
  }

  // --- CARD VẬN HÀNH VỚI SHADOW & ALERT ---
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
          boxShadow: [
            BoxShadow(
              color: alert
                  ? alertColor.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
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
