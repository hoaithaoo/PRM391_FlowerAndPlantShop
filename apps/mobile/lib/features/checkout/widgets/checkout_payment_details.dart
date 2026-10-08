import 'package:flutter/material.dart';

import '../models/checkout_payment.dart';
import '../utils/checkout_theme.dart';
import '../utils/currency_formatter.dart';
import 'checkout_detail_row.dart';
import 'checkout_section_card.dart';

class CheckoutPaymentDetails extends StatelessWidget {
  const CheckoutPaymentDetails({
    super.key,
    required this.payment,
    required this.grandTotal,
  });

  final CheckoutPayment payment;
  final num grandTotal;

  @override
  Widget build(BuildContext context) {
    return CheckoutSectionCard(
      title: 'Thanh toán SePay',
      subtitle: 'Sử dụng thông tin bên dưới để hoàn tất thanh toán',
      icon: Icons.qr_code_2_outlined,
      trailing: CheckoutStatusPill(status: payment.status),
      child: Column(
        children: <Widget>[
          CheckoutDetailRow(
            label: 'Mã thanh toán',
            value: payment.paymentCode ?? 'Đang chờ',
            selectable: true,
          ),
          const SizedBox(height: 12),
          CheckoutDetailRow(
            label: 'Trạng thái thanh toán',
            value: formatCheckoutStatus(payment.status),
          ),
          const SizedBox(height: 12),
          CheckoutDetailRow(label: 'Số tiền', value: formatVnd(grandTotal)),
          const SizedBox(height: 16),
          _PaymentQrPlaceholder(qrUrl: payment.qrUrl),
        ],
      ),
    );
  }
}

class _PaymentQrPlaceholder extends StatelessWidget {
  const _PaymentQrPlaceholder({required this.qrUrl});

  final String? qrUrl;

  @override
  Widget build(BuildContext context) {
    // TODO: Hiển thị QR thật sau khi project tích hợp thư viện QR
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CheckoutPalette.field,
        border: Border.all(color: CheckoutPalette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CheckoutPalette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CheckoutPalette.border),
            ),
            child: const Icon(
              Icons.qr_code_2,
              size: 48,
              color: CheckoutPalette.forest,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            qrUrl == null
                ? 'Thông tin QR đang được chuẩn bị.'
                : 'Liên kết QR đã sẵn sàng để thanh toán.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: CheckoutPalette.mutedText,
              height: 1.4,
            ),
          ),
          if (qrUrl != null) ...[
            const SizedBox(height: 6),
            SelectableText(
              qrUrl!,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: CheckoutPalette.forest),
            ),
          ],
        ],
      ),
    );
  }
}
