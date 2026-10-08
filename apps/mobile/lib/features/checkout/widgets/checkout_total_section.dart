import 'package:flutter/material.dart';

import '../utils/checkout_theme.dart';
import '../utils/currency_formatter.dart';

class CheckoutTotalSection extends StatelessWidget {
  const CheckoutTotalSection({
    super.key,
    required this.subtotal,
    required this.tax,
    required this.shippingFee,
    required this.grandTotal,
  });

  final num subtotal;
  final num tax;
  final num shippingFee;
  final num grandTotal;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _TotalRow(label: 'Tạm tính', value: formatVnd(subtotal)),
        const SizedBox(height: 10),
        _TotalRow(label: 'Thuế', value: formatVnd(tax)),
        const SizedBox(height: 10),
        _TotalRow(label: 'Phí vận chuyển', value: formatVnd(shippingFee)),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Divider(),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: CheckoutPalette.sage,
            borderRadius: BorderRadius.circular(14),
          ),
          child: _TotalRow(
            label: 'Tổng thanh toán',
            value: formatVnd(grandTotal),
            emphasized: true,
          ),
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = emphasized
        ? theme.textTheme.titleMedium?.copyWith(
            color: CheckoutPalette.forest,
            fontWeight: FontWeight.w700,
          )
        : theme.textTheme.bodyMedium?.copyWith(
            color: CheckoutPalette.mutedText,
          );
    final valueStyle = emphasized
        ? theme.textTheme.titleMedium?.copyWith(
            color: CheckoutPalette.forest,
            fontWeight: FontWeight.w800,
          )
        : theme.textTheme.bodyMedium?.copyWith(
            color: CheckoutPalette.text,
            fontWeight: FontWeight.w600,
          );

    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: labelStyle)),
        const SizedBox(width: 16),
        Text(value, style: valueStyle),
      ],
    );
  }
}
