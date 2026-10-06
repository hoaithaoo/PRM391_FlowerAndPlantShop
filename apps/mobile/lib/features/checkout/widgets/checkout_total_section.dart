import 'package:flutter/material.dart';

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
        _TotalRow(label: 'Subtotal', value: formatVnd(subtotal)),
        const SizedBox(height: 8),
        _TotalRow(label: 'Tax', value: formatVnd(tax)),
        const SizedBox(height: 8),
        _TotalRow(label: 'Shipping fee', value: formatVnd(shippingFee)),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1),
        ),
        _TotalRow(
          label: 'Grand total',
          value: formatVnd(grandTotal),
          emphasized: true,
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
    final style = emphasized
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.bodyMedium;

    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: style)),
        const SizedBox(width: 16),
        Text(value, style: style),
      ],
    );
  }
}
