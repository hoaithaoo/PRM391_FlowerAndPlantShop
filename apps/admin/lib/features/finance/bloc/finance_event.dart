import 'package:equatable/equatable.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

abstract class FinanceEvent extends Equatable {
  const FinanceEvent();

  @override
  List<Object?> get props => [];
}

class FetchInvoicesEvent extends FinanceEvent {
  final String? search;
  final InvoiceStatus? status;

  const FetchInvoicesEvent({this.search, this.status});

  @override
  List<Object?> get props => [search, status];
}

class FetchSepayTransactionsEvent extends FinanceEvent {
  final bool? isMatched;
  final String? search;

  const FetchSepayTransactionsEvent({this.isMatched, this.search});

  @override
  List<Object?> get props => [isMatched, search];
}

class FetchAllFinanceDataEvent extends FinanceEvent {
  const FetchAllFinanceDataEvent();
}

class ManualMatchTransactionEvent extends FinanceEvent {
  final String transactionId;
  final String orderCode;

  const ManualMatchTransactionEvent({
    required this.transactionId,
    required this.orderCode,
  });

  @override
  List<Object?> get props => [transactionId, orderCode];
}
