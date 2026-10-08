class DailyProfitRecord {
  final String date;
  final double revenue;
  final double cost;
  final double profit;
  final double profitMargin;
  final int orderCount;

  const DailyProfitRecord({
    required this.date,
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.profitMargin,
    this.orderCount = 0,
  });

  factory DailyProfitRecord.fromJson(Map<String, dynamic> json) {
    return DailyProfitRecord(
      date: json['date'] as String? ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
      profitMargin: (json['profitMargin'] as num?)?.toDouble() ?? 0.0,
      orderCount: json['orderCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'revenue': revenue,
    'cost': cost,
    'profit': profit,
    'profitMargin': profitMargin,
    'orderCount': orderCount,
  };
}

class CustomerFeedbackItem {
  final String id;
  final String customerName;
  final int rating;
  final String comment;
  final String timeAgo;
  final String? productName;

  const CustomerFeedbackItem({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.timeAgo,
    this.productName,
  });

  factory CustomerFeedbackItem.fromJson(Map<String, dynamic> json) {
    return CustomerFeedbackItem(
      id: json['id'] as String? ?? '',
      customerName: json['customerName'] as String? ?? 'Khách hàng',
      rating: json['rating'] as int? ?? 5,
      comment: json['comment'] as String? ?? '',
      timeAgo: json['timeAgo'] as String? ?? 'Vừa xong',
      productName: json['productName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerName': customerName,
    'rating': rating,
    'comment': comment,
    'timeAgo': timeAgo,
    if (productName != null) 'productName': productName,
  };
}

class CustomerFeedbackSummary {
  final double averageRating;
  final int totalReviews;
  final double satisfactionRate;
  final List<CustomerFeedbackItem> recentReviews;

  const CustomerFeedbackSummary({
    this.averageRating = 4.9,
    this.totalReviews = 128,
    this.satisfactionRate = 96.0,
    this.recentReviews = const [],
  });

  factory CustomerFeedbackSummary.fromJson(Map<String, dynamic> json) {
    return CustomerFeedbackSummary(
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 4.9,
      totalReviews: json['totalReviews'] as int? ?? 128,
      satisfactionRate: (json['satisfactionRate'] as num?)?.toDouble() ?? 96.0,
      recentReviews: (json['recentReviews'] as List<dynamic>?)
              ?.map((e) => CustomerFeedbackItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'averageRating': averageRating,
    'totalReviews': totalReviews,
    'satisfactionRate': satisfactionRate,
    'recentReviews': recentReviews.map((e) => e.toJson()).toList(),
  };
}

class DashboardStatsModel {
  final double revenueToday;
  final double revenueMonth;
  final int totalOrders;
  final int pendingOrders;
  final int totalProducts;
  final int lowStockProducts;
  final int totalUsers;
  final double paidRevenue;
  final double netProfit;
  final double profitMargin;
  final List<DailyProfitRecord> dailyProfits;
  final CustomerFeedbackSummary? feedbackSummary;
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
    this.netProfit = 0.0,
    this.profitMargin = 0.0,
    this.dailyProfits = const [],
    this.feedbackSummary,
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
    double? netProfit,
    double? profitMargin,
    List<DailyProfitRecord>? dailyProfits,
    CustomerFeedbackSummary? feedbackSummary,
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
      netProfit: netProfit ?? this.netProfit,
      profitMargin: profitMargin ?? this.profitMargin,
      dailyProfits: dailyProfits ?? this.dailyProfits,
      feedbackSummary: feedbackSummary ?? this.feedbackSummary,
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
      netProfit: (json['netProfit'] as num?)?.toDouble() ?? 0.0,
      profitMargin: (json['profitMargin'] as num?)?.toDouble() ?? 0.0,
      dailyProfits: (json['dailyProfits'] as List<dynamic>?)
              ?.map((e) => DailyProfitRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      feedbackSummary: json['feedbackSummary'] != null
          ? CustomerFeedbackSummary.fromJson(json['feedbackSummary'] as Map<String, dynamic>)
          : null,
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
    'netProfit': netProfit,
    'profitMargin': profitMargin,
    'dailyProfits': dailyProfits.map((e) => e.toJson()).toList(),
    if (feedbackSummary != null) 'feedbackSummary': feedbackSummary!.toJson(),
    if (dateRangeLabel != null) 'dateRangeLabel': dateRangeLabel,
    if (from != null) 'from': from!.toIso8601String(),
    if (to != null) 'to': to!.toIso8601String(),
  };
}
