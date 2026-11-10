import '../../services/contracts/admin_incidents_service.dart';

class MockIncidentsService implements AdminIncidentsService {
  final List<IncidentModel> _items = [
    IncidentModel(
      id: 'inc_001',
      code: 'SC-20261110-A1B2C3',
      category: 'DAMAGED_PRODUCT',
      title: 'Hoa hồng bị dập cánh',
      description: 'Bó hoa nhận được bị dập nhiều cánh, giấy gói bị rách.',
      status: 'OPEN',
      orderCode: 'NCH-2026-001',
      customerName: 'Nguyễn Phương Hà',
      customerEmail: 'phuongha@gmail.com',
      customerPhone: '0901234567',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    IncidentModel(
      id: 'inc_002',
      code: 'SC-20261109-D4E5F6',
      category: 'PAYMENT',
      title: 'Đã chuyển khoản nhưng đơn chưa xác nhận',
      description: 'Tôi đã chuyển khoản qua QR từ hôm qua nhưng đơn vẫn chờ thanh toán.',
      status: 'IN_PROGRESS',
      adminNote: 'Đang đối soát giao dịch SePay.',
      customerName: 'Trần Minh Khoa',
      customerEmail: 'khoa@gmail.com',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Future<List<IncidentModel>> getIncidents({
    String? status,
    String? category,
    String? search,
  }) async {
    final query = search?.toLowerCase() ?? '';
    return _items
        .where((e) => status == null || e.status == status)
        .where((e) => category == null || e.category == category)
        .where((e) =>
            query.isEmpty ||
            e.code.toLowerCase().contains(query) ||
            e.title.toLowerCase().contains(query))
        .toList();
  }

  @override
  Future<IncidentModel> updateIncident(
    String id, {
    required String status,
    String? adminNote,
  }) async {
    final index = _items.indexWhere((e) => e.id == id);
    final old = _items[index];
    final updated = IncidentModel(
      id: old.id,
      code: old.code,
      category: old.category,
      title: old.title,
      description: old.description,
      status: status,
      adminNote: adminNote,
      orderCode: old.orderCode,
      customerName: old.customerName,
      customerEmail: old.customerEmail,
      customerPhone: old.customerPhone,
      createdAt: old.createdAt,
    );
    _items[index] = updated;
    return updated;
  }
}
