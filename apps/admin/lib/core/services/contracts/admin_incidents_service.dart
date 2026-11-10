/// Khớp enum IncidentCategory của backend.
const incidentCategoryLabels = <String, String>{
  'DAMAGED_PRODUCT': 'Hàng hư hỏng, dập, héo',
  'WRONG_ITEM': 'Giao sai / thiếu hàng',
  'DELIVERY': 'Giao trễ / chưa nhận',
  'PAYMENT': 'Lỗi thanh toán',
  'QUALITY': 'Không giống mô tả',
  'SERVICE': 'Thái độ phục vụ',
  'OTHER': 'Khác',
};

/// Khớp enum IncidentStatus của backend.
const incidentStatusLabels = <String, String>{
  'OPEN': 'Mới tiếp nhận',
  'IN_PROGRESS': 'Đang xử lý',
  'RESOLVED': 'Đã giải quyết',
  'REJECTED': 'Từ chối',
};

class IncidentModel {
  const IncidentModel({
    required this.id,
    required this.code,
    required this.category,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.adminNote,
    this.orderCode,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    final order = json['order'] as Map<String, dynamic>?;
    final user = json['user'] as Map<String, dynamic>?;
    return IncidentModel(
      id: json['id'] as String,
      code: json['code'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      adminNote: json['adminNote'] as String?,
      orderCode: order?['orderNumber'] as String?,
      customerName: user?['fullName'] as String?,
      customerEmail: user?['email'] as String?,
      customerPhone: user?['phone'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }

  final String id;
  final String code;
  final String category;
  final String title;
  final String description;
  final String status;
  final String? adminNote;
  final String? orderCode;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final DateTime createdAt;

  String get categoryLabel => incidentCategoryLabels[category] ?? category;
  String get statusLabel => incidentStatusLabels[status] ?? status;
}

abstract class AdminIncidentsService {
  Future<List<IncidentModel>> getIncidents({
    String? status,
    String? category,
    String? search,
  });

  Future<IncidentModel> updateIncident(
    String id, {
    required String status,
    String? adminNote,
  });
}
