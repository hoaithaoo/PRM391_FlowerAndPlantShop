import 'package:flutter/material.dart';

import '../models/payment_method.dart';

class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final PaymentMethod value;
  final ValueChanged<PaymentMethod> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Payment method', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        SegmentedButton<PaymentMethod>(
          segments: const <ButtonSegment<PaymentMethod>>[
            ButtonSegment<PaymentMethod>(
              value: PaymentMethod.cod,
              icon: Icon(Icons.payments_outlined),
              label: Text('COD'),
            ),
            ButtonSegment<PaymentMethod>(
              value: PaymentMethod.sepay,
              icon: Icon(Icons.qr_code_2_outlined),
              label: Text('SePay'),
            ),
          ],
          selected: <PaymentMethod>{value},
          onSelectionChanged: enabled
              ? (selection) {
                  if (selection.isNotEmpty) {
                    onChanged(selection.first);
                  }
                }
              : null,
          showSelectedIcon: false,
        ),
        const SizedBox(height: 8),
        Text(
          value == PaymentMethod.cod
              ? 'Pay when your order is delivered.'
              : 'Payment details will be shown after placing your order.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
