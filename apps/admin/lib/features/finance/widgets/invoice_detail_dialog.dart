import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

class InvoiceDetailDialog extends StatelessWidget {
  final InvoiceModel invoice;

  const InvoiceDetailDialog({super.key, required this.invoice});

  Color _getStatusColor(InvoiceStatus status) {
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
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormat = DateFormat('HH:mm - dd/MM/yyyy');
    final statusColor = _getStatusColor(invoice.status);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HÓA ĐƠN BÁN LẺ (VAT)',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        invoice.invoiceNumber,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textHeading,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Status and Order Code Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      invoice.status.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfacePastel,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'Đơn: ${invoice.orderCode}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Scrollable Details
              Expanded(
                child: ListView(
                  children: [
                    // Customer & Time Info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfacePastel,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Khách hàng: ${invoice.customerName}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (invoice.customerEmail != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.email_outlined, size: 16, color: AppColors.textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  invoice.customerEmail!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16, color: AppColors.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                'Thời gian xuất: ${dateFormat.format(invoice.issuedAt)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Items Table
                    Text(
                      'CHI TIẾT MẶT HÀNG',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...invoice.items.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${currencyFormat.format(item.unitPrice)} x ${item.quantity}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              currencyFormat.format(item.totalPrice),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textHeading,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Tax and Total breakdown
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Cộng tiền hàng (Chưa thuế):',
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textBody),
                              ),
                              Text(
                                currencyFormat.format(invoice.subtotal),
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Thuế GTGT (VAT ${(invoice.taxRate * 100).toInt()}%):',
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textBody),
                              ),
                              Text(
                                currencyFormat.format(invoice.taxAmount),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tổng thanh toán:',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textHeading,
                                ),
                              ),
                              Text(
                                currencyFormat.format(invoice.totalAmount),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accent,
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
              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đang chuẩn bị bản in hóa đơn VAT PDF...'),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.print_outlined, size: 18),
                      label: const Text('In hóa đơn'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Đóng'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textLight,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
