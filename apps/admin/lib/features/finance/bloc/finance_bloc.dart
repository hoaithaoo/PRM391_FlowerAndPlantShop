import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import '../../../core/network/admin_api_client.dart';
import 'finance_event.dart';
import 'finance_state.dart';

class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  final AdminApiClient apiClient;

  FinanceBloc({required this.apiClient}) : super(FinanceInitial()) {
    on<FetchAllFinanceDataEvent>(_onFetchAllData);
    on<FetchInvoicesEvent>(_onFetchInvoices);
    on<FetchSepayTransactionsEvent>(_onFetchSepayTransactions);
    on<ManualMatchTransactionEvent>(_onManualMatchTransaction);
  }

  Future<void> _onFetchAllData(
    FetchAllFinanceDataEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(FinanceLoading());
    try {
      final invoices = await apiClient.getInvoices();
      final transactions = await apiClient.getSepayTransactions();

      double totalRevenue = 0;
      double totalTax = 0;
      for (final inv in invoices) {
        if (inv.status != InvoiceStatus.cancelled) {
          totalRevenue += inv.totalAmount;
          totalTax += inv.taxAmount;
        }
      }

      final matchedCount = transactions.where((t) => t.isMatched).length;
      final unmatchedCount = transactions.length - matchedCount;

      emit(
        FinanceLoaded(
          invoices: invoices,
          transactions: transactions,
          totalRevenue: totalRevenue,
          totalTax: totalTax,
          matchedCount: matchedCount,
          unmatchedCount: unmatchedCount,
        ),
      );
    } catch (e) {
      emit(FinanceError('Lỗi tải dữ liệu tài chính: ${e.toString()}'));
    }
  }

  Future<void> _onFetchInvoices(
    FetchInvoicesEvent event,
    Emitter<FinanceState> emit,
  ) async {
    final currentState = state;
    List<SepayTransactionModel> existingTransactions = [];
    int matchedCount = 0;
    int unmatchedCount = 0;

    if (currentState is FinanceLoaded) {
      existingTransactions = currentState.transactions;
      matchedCount = currentState.matchedCount;
      unmatchedCount = currentState.unmatchedCount;
    } else {
      emit(FinanceLoading());
    }

    try {
      final invoices = await apiClient.getInvoices(
        search: event.search,
        status: event.status,
      );

      double totalRevenue = 0;
      double totalTax = 0;
      for (final inv in invoices) {
        if (inv.status != InvoiceStatus.cancelled) {
          totalRevenue += inv.totalAmount;
          totalTax += inv.taxAmount;
        }
      }

      emit(
        FinanceLoaded(
          invoices: invoices,
          transactions: existingTransactions,
          totalRevenue: totalRevenue,
          totalTax: totalTax,
          matchedCount: matchedCount,
          unmatchedCount: unmatchedCount,
          currentInvoiceFilter: event.status,
        ),
      );
    } catch (e) {
      emit(FinanceError('Lỗi tra cứu hóa đơn: ${e.toString()}'));
    }
  }

  Future<void> _onFetchSepayTransactions(
    FetchSepayTransactionsEvent event,
    Emitter<FinanceState> emit,
  ) async {
    final currentState = state;
    List<InvoiceModel> existingInvoices = [];
    double totalRevenue = 0;
    double totalTax = 0;

    if (currentState is FinanceLoaded) {
      existingInvoices = currentState.invoices;
      totalRevenue = currentState.totalRevenue;
      totalTax = currentState.totalTax;
    } else {
      emit(FinanceLoading());
    }

    try {
      final transactions = await apiClient.getSepayTransactions(
        isMatched: event.isMatched,
        search: event.search,
      );

      final matchedCount = transactions.where((t) => t.isMatched).length;
      final unmatchedCount = transactions.length - matchedCount;

      emit(
        FinanceLoaded(
          invoices: existingInvoices,
          transactions: transactions,
          totalRevenue: totalRevenue,
          totalTax: totalTax,
          matchedCount: matchedCount,
          unmatchedCount: unmatchedCount,
          currentMatchedFilter: event.isMatched,
        ),
      );
    } catch (e) {
      emit(FinanceError('Lỗi tra cứu giao dịch SePay: ${e.toString()}'));
    }
  }

  Future<void> _onManualMatchTransaction(
    ManualMatchTransactionEvent event,
    Emitter<FinanceState> emit,
  ) async {
    try {
      await apiClient.manualMatchTransaction(
        transactionId: event.transactionId,
        orderCode: event.orderCode,
      );

      emit(FinanceActionSuccess(
        'Đã đối soát thành công giao dịch với đơn hàng ${event.orderCode}',
      ));

      add(const FetchAllFinanceDataEvent());
    } catch (e) {
      emit(FinanceError('Lỗi đối soát giao dịch: ${e.toString()}'));
    }
  }
}
