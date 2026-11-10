import 'package:plant_flower_shared/plant_flower_shared.dart';
import '../../services/contracts/admin_finance_service.dart';

class MockFinanceService implements AdminFinanceService {
  final List<InvoiceModel> _mockInvoices = [
    InvoiceModel(
      id: 'inv_001',
      invoiceNumber: 'INV-2026-001',
      orderId: 'ord_101',
      orderCode: 'NCH-2026-001',
      customerName: 'Nguyễn Phương Hà',
      customerEmail: 'phuongha@gmail.com',
      subtotal: 361111,
      taxRate: 0.08,
      taxAmount: 28889,
      totalAmount: 390000,
      status: InvoiceStatus.paid,
      issuedAt: DateTime.now().subtract(const Duration(days: 1)),
      items: const [
        InvoiceItemModel(
          productName: 'Sen Hồng Tháp Mười (Bình Gốm Đất Nung)',
          quantity: 1,
          unitPrice: 350000,
          totalPrice: 350000,
        ),
      ],
    ),
    InvoiceModel(
      id: 'inv_002',
      invoiceNumber: 'INV-2026-002',
      orderId: 'ord_102',
      orderCode: 'NCH-2026-002',
      customerName: 'Lê Hoàng Nam',
      customerEmail: 'hoangnam@gmail.com',
      subtotal: 231481,
      taxRate: 0.08,
      taxAmount: 18519,
      totalAmount: 250000,
      status: InvoiceStatus.paid,
      issuedAt: DateTime.now().subtract(const Duration(hours: 18)),
      items: const [
        InvoiceItemModel(
          productName: 'Cây Bàng Singapore Mini Để Bàn',
          quantity: 1,
          unitPrice: 220000,
          totalPrice: 220000,
        ),
      ],
    ),
    InvoiceModel(
      id: 'inv_003',
      invoiceNumber: 'INV-2026-003',
      orderId: 'ord_103',
      orderCode: 'NCH-2026-003',
      customerName: 'Trần Thu Thảo',
      customerEmail: 'thuthao@gmail.com',
      subtotal: 574074,
      taxRate: 0.08,
      taxAmount: 45926,
      totalAmount: 620000,
      status: InvoiceStatus.issued,
      issuedAt: DateTime.now().subtract(const Duration(hours: 12)),
      items: const [
        InvoiceItemModel(
          productName: 'Sen Hồng Tháp Mười (Bình Gốm Đất Nung)',
          quantity: 1,
          unitPrice: 350000,
          totalPrice: 350000,
        ),
        InvoiceItemModel(
          productName: 'Cây Bàng Singapore Mini Để Bàn',
          quantity: 1,
          unitPrice: 220000,
          totalPrice: 220000,
        ),
      ],
    ),
    InvoiceModel(
      id: 'inv_004',
      invoiceNumber: 'INV-2026-004',
      orderId: 'ord_104',
      orderCode: 'NCH-2026-004',
      customerName: 'Phạm Quốc Bảo',
      customerEmail: 'quocbao@gmail.com',
      subtotal: 166667,
      taxRate: 0.08,
      taxAmount: 13333,
      totalAmount: 180000,
      status: InvoiceStatus.cancelled,
      issuedAt: DateTime.now().subtract(const Duration(hours: 8)),
      items: const [
        InvoiceItemModel(
          productName: 'Chậu Gốm Men Hoả Biến Dáng Cổ',
          quantity: 1,
          unitPrice: 180000,
          totalPrice: 180000,
        ),
      ],
    ),
    InvoiceModel(
      id: 'inv_005',
      invoiceNumber: 'INV-2026-005',
      orderId: 'ord_105',
      orderCode: 'NCH-2026-005',
      customerName: 'Vũ Minh Anh',
      customerEmail: 'minhanh.vu@gmail.com',
      subtotal: 787037,
      taxRate: 0.08,
      taxAmount: 62963,
      totalAmount: 850000,
      status: InvoiceStatus.issued,
      issuedAt: DateTime.now().subtract(const Duration(hours: 3)),
      items: const [
        InvoiceItemModel(
          productName: 'Sen Hồng Tháp Mười (Bình Gốm Đất Nung)',
          quantity: 2,
          unitPrice: 350000,
          totalPrice: 700000,
        ),
      ],
    ),
  ];

  final List<SepayTransactionModel> _mockSepayTransactions = [
    SepayTransactionModel(
      id: 'sepay_txn_01',
      referenceCode: 'MB-20260308-88201',
      bankName: 'MBBank',
      accountNumber: '090123456789',
      amountIn: 390000,
      content: 'SEPAY NCH-2026-001 THANH TOAN HOA SEN',
      transactionDate: DateTime.now().subtract(const Duration(days: 1)),
      isMatched: true,
      matchedOrderCode: 'NCH-2026-001',
      matchedOrderId: 'ord_101',
    ),
    SepayTransactionModel(
      id: 'sepay_txn_02',
      referenceCode: 'MB-20260308-88202',
      bankName: 'MBBank',
      accountNumber: '090123456789',
      amountIn: 250000,
      content: 'NCH 2026 002 LE HOANG NAM CHUYEN TIEN',
      transactionDate: DateTime.now().subtract(const Duration(hours: 18)),
      isMatched: true,
      matchedOrderCode: 'NCH-2026-002',
      matchedOrderId: 'ord_102',
    ),
    SepayTransactionModel(
      id: 'sepay_txn_03',
      referenceCode: 'MB-20260308-88203',
      bankName: 'MBBank',
      accountNumber: '090123456789',
      amountIn: 850000,
      content: 'VU MINH ANH THANH TOAN DON NCH-2026-005',
      transactionDate: DateTime.now().subtract(const Duration(hours: 3)),
      isMatched: true,
      matchedOrderCode: 'NCH-2026-005',
      matchedOrderId: 'ord_105',
    ),
    SepayTransactionModel(
      id: 'sepay_txn_04',
      referenceCode: 'MB-20260308-88204',
      bankName: 'MBBank',
      accountNumber: '090123456789',
      amountIn: 620000,
      content: 'CHUYEN TIEN MUA HOA TUOI NHA CO HOA',
      transactionDate: DateTime.now().subtract(const Duration(hours: 5)),
      isMatched: false,
    ),
    SepayTransactionModel(
      id: 'sepay_txn_05',
      referenceCode: 'MB-20260308-88205',
      bankName: 'MBBank',
      accountNumber: '090123456789',
      amountIn: 150000,
      content: 'DAT COC DON HANG HOA CUOI',
      transactionDate: DateTime.now().subtract(const Duration(hours: 1)),
      isMatched: false,
    ),
  ];

  @override
  Future<List<InvoiceModel>> getInvoices({
    InvoiceStatus? status,
    String? search,
    int page = 1,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var list = List<InvoiceModel>.from(_mockInvoices);
    if (status != null) {
      list = list.where((i) => i.status == status).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      list = list
          .where((i) =>
              i.invoiceNumber.toLowerCase().contains(q) ||
              i.customerName.toLowerCase().contains(q) ||
              i.orderCode.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Future<InvoiceModel> getInvoiceDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final item = _mockInvoices.firstWhere(
      (i) => i.id == id,
      orElse: () => throw Exception('Không tìm thấy hóa đơn (INVOICE_NOT_FOUND)'),
    );
    return item;
  }

  @override
  Future<List<SepayTransactionModel>> getSepayTransactions({
    bool? isMatched,
    String? search,
    int page = 1,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var list = List<SepayTransactionModel>.from(_mockSepayTransactions);
    if (isMatched != null) {
      list = list.where((t) => t.isMatched == isMatched).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      list = list
          .where((t) =>
              t.referenceCode.toLowerCase().contains(q) ||
              t.content.toLowerCase().contains(q) ||
              (t.matchedOrderCode?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return list;
  }

  @override
  Future<SepayTransactionModel> manualMatchTransaction({
    required String transactionId,
    required String orderCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockSepayTransactions.indexWhere((t) => t.id == transactionId);
    if (index != -1) {
      final updated = _mockSepayTransactions[index].copyWith(
        isMatched: true,
        matchedOrderCode: orderCode,
      );
      _mockSepayTransactions[index] = updated;
      return updated;
    }
    throw Exception('Không tìm thấy giao dịch (TRANSACTION_NOT_FOUND)');
  }
}
