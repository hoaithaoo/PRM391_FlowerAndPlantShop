import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plant_flower_admin/core/network/admin_api_client.dart';
import 'package:plant_flower_admin/features/finance/bloc/finance_bloc.dart';
import 'package:plant_flower_admin/features/finance/bloc/finance_event.dart';
import 'package:plant_flower_admin/features/finance/bloc/finance_state.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

class MockAdminApiClient extends Mock implements AdminApiClient {}

void main() {
  group('FinanceBloc Unit Tests (Spec 9.13 - 9.15 & Phase 3)', () {
    late MockAdminApiClient mockApiClient;
    late FinanceBloc financeBloc;

    final testInvoice = InvoiceModel(
      id: 'inv_001',
      invoiceNumber: 'INV-2026-001',
      orderId: 'ord_101',
      orderCode: 'NCH-2026-001',
      customerName: 'Nguyễn Phương Hà',
      subtotal: 361111,
      taxRate: 0.08,
      taxAmount: 28889,
      totalAmount: 390000,
      status: InvoiceStatus.paid,
      issuedAt: DateTime.now(),
      items: const [
        InvoiceItemModel(
          productName: 'Sen Hồng Tháp Mười',
          quantity: 1,
          unitPrice: 350000,
          totalPrice: 350000,
        ),
      ],
    );

    final testTransaction = SepayTransactionModel(
      id: 'sepay_txn_01',
      referenceCode: 'MB-20260308-88201',
      bankName: 'MBBank',
      accountNumber: '090123456789',
      amountIn: 390000,
      content: 'SEPAY NCH-2026-001 THANH TOAN HOA SEN',
      transactionDate: DateTime.now(),
      isMatched: true,
      matchedOrderCode: 'NCH-2026-001',
    );

    setUp(() {
      mockApiClient = MockAdminApiClient();
      financeBloc = FinanceBloc(apiClient: mockApiClient);
    });

    tearDown(() {
      financeBloc.close();
    });

    test('Trạng thái ban đầu phải là FinanceInitial', () {
      expect(financeBloc.state, equals(FinanceInitial()));
    });

    blocTest<FinanceBloc, FinanceState>(
      'FetchAllFinanceDataEvent tải thành công hóa đơn và giao dịch SePay',
      build: () {
        when(() => mockApiClient.getInvoices())
            .thenAnswer((_) async => [testInvoice]);
        when(() => mockApiClient.getSepayTransactions())
            .thenAnswer((_) async => [testTransaction]);
        return financeBloc;
      },
      act: (bloc) => bloc.add(const FetchAllFinanceDataEvent()),
      expect: () => [
        isA<FinanceLoading>(),
        isA<FinanceLoaded>()
            .having((s) => s.invoices.length, 'invoices length', 1)
            .having((s) => s.transactions.length, 'transactions length', 1)
            .having((s) => s.totalRevenue, 'totalRevenue', 390000)
            .having((s) => s.matchedCount, 'matchedCount', 1),
      ],
    );

    blocTest<FinanceBloc, FinanceState>(
      'FetchInvoicesEvent lọc hóa đơn theo status thành công',
      build: () {
        when(() => mockApiClient.getInvoices(status: InvoiceStatus.paid))
            .thenAnswer((_) async => [testInvoice]);
        return financeBloc;
      },
      act: (bloc) => bloc.add(const FetchInvoicesEvent(status: InvoiceStatus.paid)),
      expect: () => [
        isA<FinanceLoading>(),
        isA<FinanceLoaded>()
            .having((s) => s.invoices.length, 'invoices length', 1)
            .having((s) => s.currentInvoiceFilter, 'filter', InvoiceStatus.paid),
      ],
    );

    blocTest<FinanceBloc, FinanceState>(
      'FetchSepayTransactionsEvent lọc giao dịch theo matched status',
      build: () {
        when(() => mockApiClient.getSepayTransactions(isMatched: true))
            .thenAnswer((_) async => [testTransaction]);
        return financeBloc;
      },
      act: (bloc) => bloc.add(const FetchSepayTransactionsEvent(isMatched: true)),
      expect: () => [
        isA<FinanceLoading>(),
        isA<FinanceLoaded>()
            .having((s) => s.transactions.length, 'transactions length', 1)
            .having((s) => s.currentMatchedFilter, 'filter', true),
      ],
    );

    blocTest<FinanceBloc, FinanceState>(
      'ManualMatchTransactionEvent ghép đơn thành công phát ra FinanceActionSuccess',
      build: () {
        when(() => mockApiClient.manualMatchTransaction(
              transactionId: 'sepay_txn_04',
              orderCode: 'NCH-2026-003',
            )).thenAnswer(
          (_) async => testTransaction.copyWith(
            id: 'sepay_txn_04',
            matchedOrderCode: 'NCH-2026-003',
            isMatched: true,
          ),
        );
        when(() => mockApiClient.getInvoices())
            .thenAnswer((_) async => [testInvoice]);
        when(() => mockApiClient.getSepayTransactions())
            .thenAnswer((_) async => [testTransaction]);
        return financeBloc;
      },
      act: (bloc) => bloc.add(const ManualMatchTransactionEvent(
        transactionId: 'sepay_txn_04',
        orderCode: 'NCH-2026-003',
      )),
      expect: () => [
        isA<FinanceActionSuccess>(),
        isA<FinanceLoading>(),
        isA<FinanceLoaded>(),
      ],
    );

    blocTest<FinanceBloc, FinanceState>(
      'FetchAllFinanceDataEvent phát ra FinanceError khi API gặp sự cố',
      build: () {
        when(() => mockApiClient.getInvoices())
            .thenThrow(Exception('Server connection failed'));
        return financeBloc;
      },
      act: (bloc) => bloc.add(const FetchAllFinanceDataEvent()),
      expect: () => [
        isA<FinanceLoading>(),
        isA<FinanceError>(),
      ],
    );
  });
}
