import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';
import '../widgets/invoice_detail_dialog.dart';
import '../widgets/manual_match_dialog.dart';

class FinanceManagementScreen extends StatefulWidget {
  const FinanceManagementScreen({super.key});

  @override
  State<FinanceManagementScreen> createState() => _FinanceManagementScreenState();
}

class _FinanceManagementScreenState extends State<FinanceManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _invoiceSearchController = TextEditingController();
  final _sepaySearchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  final _dateFormat = DateFormat('HH:mm - dd/MM/yyyy');

  InvoiceStatus? _selectedInvoiceStatus;
  bool? _selectedMatchedFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<FinanceBloc>().add(const FetchAllFinanceDataEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _invoiceSearchController.dispose();
    _sepaySearchController.dispose();
    super.dispose();
  }

  void _onSearchInvoices() {
    context.read<FinanceBloc>().add(
          FetchInvoicesEvent(
            search: _invoiceSearchController.text.trim(),
            status: _selectedInvoiceStatus,
          ),
        );
  }

  void _onSearchSepay() {
    context.read<FinanceBloc>().add(
          FetchSepayTransactionsEvent(
            search: _sepaySearchController.text.trim(),
            isMatched: _selectedMatchedFilter,
          ),
        );
  }

  Color _getInvoiceStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return AppColors.statusDelivered;
      case InvoiceStatus.issued:
        return AppColors.statusProcessing;
      case InvoiceStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Tài Chính & Hóa Đơn',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textLight,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelColor: AppColors.textLight,
          unselectedLabelColor: AppColors.textLight.withValues(alpha: 0.7),
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long, size: 20), text: 'Hóa đơn điện tử (VAT)'),
            Tab(icon: Icon(Icons.account_balance, size: 20), text: 'Đối soát SePay QR'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới dữ liệu',
            onPressed: () {
              context.read<FinanceBloc>().add(const FetchAllFinanceDataEvent());
            },
          ),
        ],
      ),
      body: BlocConsumer<FinanceBloc, FinanceState>(
        listener: (context, state) {
          if (state is FinanceActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.statusDelivered,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is FinanceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.statusCancelled,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is FinanceLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is FinanceLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildInvoicesTab(state),
                _buildSepayTransactionsTab(state),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildInvoicesTab(FinanceLoaded state) {
    return Column(
      children: [
        // Summary Header Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DOANH THU ĐÃ XUẤT',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(state.totalRevenue),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THUẾ GTGT (VAT)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(state.totalTax),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Search & Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _invoiceSearchController,
            decoration: InputDecoration(
              hintText: 'Tìm theo mã hóa đơn, mã đơn, tên khách...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _invoiceSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _invoiceSearchController.clear();
                        _onSearchInvoices();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            onChanged: (_) => _onSearchInvoices(),
          ),
        ),
        const SizedBox(height: 10),

        // Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Tất cả'),
                selected: _selectedInvoiceStatus == null,
                onSelected: (selected) {
                  setState(() => _selectedInvoiceStatus = null);
                  _onSearchInvoices();
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Đã thanh toán'),
                selected: _selectedInvoiceStatus == InvoiceStatus.paid,
                onSelected: (selected) {
                  setState(() => _selectedInvoiceStatus = selected ? InvoiceStatus.paid : null);
                  _onSearchInvoices();
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Đã xuất'),
                selected: _selectedInvoiceStatus == InvoiceStatus.issued,
                onSelected: (selected) {
                  setState(() => _selectedInvoiceStatus = selected ? InvoiceStatus.issued : null);
                  _onSearchInvoices();
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Đã hủy'),
                selected: _selectedInvoiceStatus == InvoiceStatus.cancelled,
                onSelected: (selected) {
                  setState(() => _selectedInvoiceStatus = selected ? InvoiceStatus.cancelled : null);
                  _onSearchInvoices();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Invoice List
        Expanded(
          child: state.invoices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_outlined, size: 56, color: AppColors.textMuted),
                      const SizedBox(height: 8),
                      Text(
                        'Không tìm thấy hóa đơn nào',
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: state.invoices.length,
                  itemBuilder: (context, index) {
                    final inv = state.invoices[index];
                    final color = _getInvoiceStatusColor(inv.status);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => InvoiceDetailDialog(invoice: inv),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.receipt, color: AppColors.primary, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        inv.invoiceNumber,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textHeading,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: color.withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      inv.status.label,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${inv.customerName} • Đơn: ${inv.orderCode}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                  Text(
                                    _dateFormat.format(inv.issuedAt),
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'VAT (${(inv.taxRate * 100).toInt()}%): ${_currencyFormat.format(inv.taxAmount)}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textBody),
                                  ),
                                  Text(
                                    _currencyFormat.format(inv.totalAmount),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSepayTransactionsTab(FinanceLoaded state) {
    return Column(
      children: [
        // Match Overview Cards
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.statusDelivered.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.check_circle_outline, color: AppColors.statusDelivered, size: 24),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ĐÃ KHỚP ĐƠN',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          '${state.matchedCount} Giao dịch',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.statusDelivered,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.statusCancelled.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: AppColors.statusCancelled, size: 24),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CHƯA KHỚP',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          '${state.unmatchedCount} Giao dịch',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.statusCancelled,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Search & Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _sepaySearchController,
            decoration: InputDecoration(
              hintText: 'Tìm theo mã GD, nội dung chuyển khoản, mã đơn...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _sepaySearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _sepaySearchController.clear();
                        _onSearchSepay();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            onChanged: (_) => _onSearchSepay(),
          ),
        ),
        const SizedBox(height: 10),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Tất cả'),
                selected: _selectedMatchedFilter == null,
                onSelected: (selected) {
                  setState(() => _selectedMatchedFilter = null);
                  _onSearchSepay();
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Đã khớp đơn (Matched)'),
                selected: _selectedMatchedFilter == true,
                onSelected: (selected) {
                  setState(() => _selectedMatchedFilter = selected ? true : null);
                  _onSearchSepay();
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Chưa khớp (Chờ đối soát)'),
                selected: _selectedMatchedFilter == false,
                onSelected: (selected) {
                  setState(() => _selectedMatchedFilter = selected ? false : null);
                  _onSearchSepay();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Transactions list
        Expanded(
          child: state.transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined, size: 56, color: AppColors.textMuted),
                      const SizedBox(height: 8),
                      Text(
                        'Không có giao dịch SePay nào',
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: state.transactions.length,
                  itemBuilder: (context, index) {
                    final txn = state.transactions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        txn.bankName,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      txn.referenceCode,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textHeading,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '+${_currencyFormat.format(txn.amountIn)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.statusDelivered,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Content transfer
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surfacePastel,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Nội dung: ${txn.content}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textBody,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Bottom info & matching action
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _dateFormat.format(txn.transactionDate),
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                                ),
                                if (txn.isMatched)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.statusDelivered.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.statusDelivered.withValues(alpha: 0.4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check, size: 14, color: AppColors.statusDelivered),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Khớp đơn: ${txn.matchedOrderCode}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.statusDelivered,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => ManualMatchDialog(
                                          transaction: txn,
                                          onMatchConfirmed: (orderCode) {
                                            context.read<FinanceBloc>().add(
                                                  ManualMatchTransactionEvent(
                                                    transactionId: txn.id,
                                                    orderCode: orderCode,
                                                  ),
                                                );
                                          },
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.link, size: 14),
                                    label: const Text('Đối soát tay'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accent,
                                      foregroundColor: AppColors.textLight,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      textStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
