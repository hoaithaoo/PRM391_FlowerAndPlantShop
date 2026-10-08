import 'package:flutter/material.dart';

import '../utils/checkout_theme.dart';

String formatCheckoutStatus(String status) {
  return switch (status.trim().toUpperCase()) {
    'PENDING' => 'Đang chờ xử lý',
    'PROCESSING' => 'Đang xử lý',
    'CONFIRMED' => 'Đã xác nhận',
    'PAID' => 'Đã thanh toán',
    'COMPLETED' => 'Đã hoàn tất',
    'CANCELLED' || 'CANCELED' => 'Đã hủy',
    'FAILED' => 'Thất bại',
    'REFUNDED' => 'Đã hoàn tiền',
    _ => 'Chưa cập nhật',
  };
}

class CheckoutDetailRow extends StatelessWidget {
  const CheckoutDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.selectable = false,
  });

  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: CheckoutPalette.text,
      fontWeight: FontWeight.w700,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: CheckoutPalette.mutedText),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: selectable
              ? SelectableText(
                  value,
                  textAlign: TextAlign.end,
                  style: valueStyle,
                )
              : Text(value, textAlign: TextAlign.end, style: valueStyle),
        ),
      ],
    );
  }
}

class CheckoutStatusPill extends StatelessWidget {
  const CheckoutStatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: CheckoutPalette.sage,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        formatCheckoutStatus(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: CheckoutPalette.forest,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
