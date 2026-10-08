class DashboardStatsModel {
  final double revenueToday;
  final double revenueMonth;
  final int totalOrders;
  final int pendingOrders;
  final int totalProducts;
  final int lowStockProducts;
  final int totalUsers;
  final double paidRevenue;
  final String? dateRangeLabel;
  final DateTime? from;
  final DateTime? to;

  const DashboardStatsModel({
    required this.revenueToday,
    required this.revenueMonth,
    required this.totalOrders,
    required this.pendingOrders,
    required this.totalProducts,
    required this.lowStockProducts,
    this.totalUsers = 0,
    this.paidRevenue = 0.0,
    this.dateRangeLabel,
    this.from,
    this.to,
  });

  DashboardStatsModel copyWith({
    double? revenueToday,
    double? revenueMonth,
    int? totalOrders,
    int? pendingOrders,
    int? totalProducts,
    int? lowStockProducts,
    int? totalUsers,
    double? paidRevenue,
    String? dateRangeLabel,
    DateTime? from,
    DateTime? to,
  }) {
    return DashboardStatsModel(
      revenueToday: revenueToday ?? this.revenueToday,
      revenueMonth: revenueMonth ?? this.revenueMonth,
      totalOrders: totalOrders ?? this.totalOrders,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      totalProducts: totalProducts ?? this.totalProducts,
      lowStockProducts: lowStockProducts ?? this.lowStockProducts,
      totalUsers: totalUsers ?? this.totalUsers,
      paidRevenue: paidRevenue ?? this.paidRevenue,
      dateRangeLabel: dateRangeLabel ?? this.dateRangeLabel,
      from: from ?? this.from,
      to: to ?? this.to,
    );
  }

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      revenueToday: (json['revenueToday'] as num?)?.toDouble() ?? 0.0,
      revenueMonth: (json['revenueMonth'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['totalOrders'] as int? ?? json['ordersCount'] as int? ?? 0,
      pendingOrders: json['pendingOrders'] as int? ?? json['pendingOrdersCount'] as int? ?? 0,
      totalProducts: json['totalProducts'] as int? ?? json['productsCount'] as int? ?? 0,
      lowStockProducts: json['lowStockProducts'] as int? ?? json['lowStockCount'] as int? ?? 0,
      totalUsers: json['totalUsers'] as int? ?? json['usersCount'] as int? ?? 0,
      paidRevenue: (json['paidRevenue'] as num?)?.toDouble() ?? 0.0,
      dateRangeLabel: json['dateRangeLabel'] as String?,
      from: json['from'] != null ? DateTime.tryParse(json['from'] as String) : null,
      to: json['to'] != null ? DateTime.tryParse(json['to'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'revenueToday': revenueToday,
    'revenueMonth': revenueMonth,
    'totalOrders': totalOrders,
    'pendingOrders': pendingOrders,
    'totalProducts': totalProducts,
    'lowStockProducts': lowStockProducts,
    'totalUsers': totalUsers,
    'paidRevenue': paidRevenue,
    if (dateRangeLabel != null) 'dateRangeLabel': dateRangeLabel,
    if (from != null) 'from': from!.toIso8601String(),
    if (to != null) 'to': to!.toIso8601String(),
  };
}
