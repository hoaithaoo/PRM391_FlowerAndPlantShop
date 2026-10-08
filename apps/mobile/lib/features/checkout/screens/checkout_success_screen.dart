import 'package:flutter/material.dart';

import '../models/checkout_result.dart';
import '../utils/checkout_theme.dart';
import '../widgets/checkout_detail_row.dart';
import '../widgets/checkout_payment_details.dart';
import '../widgets/checkout_section_card.dart';
import '../widgets/checkout_success_hero.dart';
import '../widgets/checkout_total_section.dart';

class CheckoutSuccessScreen extends StatelessWidget {
  const CheckoutSuccessScreen({super.key, required this.result, this.onDone});

  final CheckoutResult result;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final payment = result.payment;

    return CheckoutTheme(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: onDone ?? () => Navigator.of(context).maybePop(),
            tooltip: 'Đóng',
            icon: const Icon(Icons.close_rounded),
          ),
          title: const Text('Xác nhận đơn hàng'),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 28, 18, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    CheckoutSuccessHero(orderCode: result.order.orderCode),
                    const SizedBox(height: 18),
                    CheckoutSectionCard(
                      title: 'Thông tin đơn hàng',
                      subtitle: 'Đơn hàng đã được ghi nhận trên hệ thống',
                      icon: Icons.receipt_long_outlined,
                      trailing: CheckoutStatusPill(status: result.order.status),
                      child: Column(
                        children: <Widget>[
                          CheckoutDetailRow(
                            label: 'Mã hóa đơn',
                            value: result.invoice.invoiceNumber,
                          ),
                          const SizedBox(height: 12),
                          CheckoutDetailRow(
                            label: 'Trạng thái đơn hàng',
                            value: formatCheckoutStatus(result.order.status),
                          ),
                          const SizedBox(height: 12),
                          CheckoutDetailRow(
                            label: 'Phương thức thanh toán',
                            value: payment == null
                                ? 'Thanh toán khi nhận hàng'
                                : 'Chuyển khoản SePay',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    CheckoutSectionCard(
                      title: 'Tổng thanh toán',
                      subtitle: 'Số tiền cuối cùng được máy chủ xác nhận',
                      icon: Icons.account_balance_wallet_outlined,
                      child: CheckoutTotalSection(
                        subtotal: result.invoice.subtotalAmount,
                        tax: result.invoice.taxAmount,
                        shippingFee: result.invoice.shippingFee,
                        grandTotal: result.invoice.grandTotal,
                      ),
                    ),
                    if (payment != null) ...[
                      const SizedBox(height: 18),
                      CheckoutPaymentDetails(
                        payment: payment,
                        grandTotal: result.invoice.grandTotal,
                      ),
                    ],
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed:
                          onDone ?? () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.local_florist_outlined),
                      label: const Text('Hoàn tất'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bạn có thể xem lại thông tin trong lịch sử đơn hàng.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: CheckoutPalette.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
