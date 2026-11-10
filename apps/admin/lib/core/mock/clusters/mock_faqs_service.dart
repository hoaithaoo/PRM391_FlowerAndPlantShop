import '../../services/contracts/admin_faqs_service.dart';

class MockFaqsService implements AdminFaqsService {
  final List<AdminFaq> _items = [
    const AdminFaq(
      id: 'faq_001',
      topic: 'Phí giao hàng',
      answer: 'Trong 2 km là 15.000đ, mỗi km thêm cộng 5.000đ. Nhận tại cửa hàng miễn phí.',
      sortOrder: 10,
    ),
    const AdminFaq(
      id: 'faq_002',
      topic: 'Phương thức thanh toán',
      answer: 'COD hoặc chuyển khoản QR (SePay), chuyển khoản trong 15 phút.',
      sortOrder: 20,
    ),
  ];
  int _nextId = 3;

  @override
  Future<List<AdminFaq>> getFaqs() async => List.of(_items);

  @override
  Future<AdminFaq> createFaq(AdminFaq faq) async {
    final created = AdminFaq(
      id: 'faq_00${_nextId++}',
      topic: faq.topic,
      answer: faq.answer,
      sortOrder: faq.sortOrder,
      isActive: faq.isActive,
    );
    _items.add(created);
    return created;
  }

  @override
  Future<AdminFaq> updateFaq(AdminFaq faq) async {
    _items[_items.indexWhere((e) => e.id == faq.id)] = faq;
    return faq;
  }

  @override
  Future<void> deleteFaq(String id) async => _items.removeWhere((e) => e.id == id);
}
