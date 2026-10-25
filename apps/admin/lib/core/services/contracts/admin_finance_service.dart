import 'package:plant_flower_shared/plant_flower_shared.dart';

abstract class AdminFinanceService {
  Future<List<InvoiceModel>> getInvoices({InvoiceStatus? status, String? search, int page = 1});
  Future<InvoiceModel> getInvoiceDetail(String id);
  Future<List<SepayTransactionModel>> getSepayTransactions({bool? isMatched, String? search, int page = 1});
  Future<SepayTransactionModel> manualMatchTransaction({required String transactionId, required String orderCode});
}
