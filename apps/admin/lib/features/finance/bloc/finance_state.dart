import 'package:equatable/equatable.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

abstract class FinanceState extends Equatable {
  const FinanceState();

  @override
  List<Object?> get props => [];
}

class FinanceInitial extends FinanceState {}

class FinanceLoading extends FinanceState {}

class FinanceLoaded extends FinanceState {
  final List<InvoiceModel> invoices;
  final List<SepayTransactionModel> transactions;
  final double totalRevenue;
  final double totalTax;
  final int matchedCount;
  final int unmatchedCount;
  final InvoiceStatus? currentInvoiceFilter;
  final bool? currentMatchedFilter;

  const FinanceLoaded({
    required this.invoices,
    required this.transactions,
    required this.totalRevenue,
    required this.totalTax,
    required this.matchedCount,
    required this.unmatchedCount,
    this.currentInvoiceFilter,
    this.currentMatchedFilter,
  });

  FinanceLoaded copyWith({
    List<InvoiceModel>? invoices,
    List<SepayTransactionModel>? transactions,
    double? totalRevenue,
    double? totalTax,
    int? matchedCount,
    int? unmatchedCount,
    InvoiceStatus? currentInvoiceFilter,
    bool? currentMatchedFilter,
  }) {
    return FinanceLoaded(
      invoices: invoices ?? this.invoices,
      transactions: transactions ?? this.transactions,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalTax: totalTax ?? this.totalTax,
      matchedCount: matchedCount ?? this.matchedCount,
      unmatchedCount: unmatchedCount ?? this.unmatchedCount,
      currentInvoiceFilter: currentInvoiceFilter ?? this.currentInvoiceFilter,
      currentMatchedFilter: currentMatchedFilter ?? this.currentMatchedFilter,
    );
  }

  @override
  List<Object?> get props => [
        invoices,
        transactions,
        totalRevenue,
        totalTax,
        matchedCount,
        unmatchedCount,
        currentInvoiceFilter,
        currentMatchedFilter,
      ];
}

class FinanceActionSuccess extends FinanceState {
  final String message;

  const FinanceActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class FinanceError extends FinanceState {
  final String message;

  const FinanceError(this.message);

  @override
  List<Object?> get props => [message];
}
