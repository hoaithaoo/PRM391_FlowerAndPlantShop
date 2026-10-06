class DashboardStatsModel {
  final double revenueToday;
  final double revenueMonth;
  final int totalOrders;
  final int pendingOrders;
  final int totalProducts;
  final int lowStockProducts;

  const DashboardStatsModel({
    required this.revenueToday,
    required this.revenueMonth,
    required this.totalOrders,
    required this.pendingOrders,
    required this.totalProducts,
    required this.lowStockProducts,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      revenueToday: (json['revenueToday'] as num?)?.toDouble() ?? 0.0,
      revenueMonth: (json['revenueMonth'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['totalOrders'] as int? ?? json['ordersCount'] as int? ?? 0,
      pendingOrders: json['pendingOrders'] as int? ?? json['pendingOrdersCount'] as int? ?? 0,
      totalProducts: json['totalProducts'] as int? ?? json['productsCount'] as int? ?? 0,
      lowStockProducts: json['lowStockProducts'] as int? ?? json['lowStockCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'revenueToday': revenueToday,
    'revenueMonth': revenueMonth,
    'totalOrders': totalOrders,
    'pendingOrders': pendingOrders,
    'totalProducts': totalProducts,
    'lowStockProducts': lowStockProducts,
  };
}
