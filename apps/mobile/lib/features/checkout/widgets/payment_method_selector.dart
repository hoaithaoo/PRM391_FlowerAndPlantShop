import 'package:flutter/material.dart';

import '../models/payment_method.dart';
import '../utils/checkout_theme.dart';

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
        _PaymentOption(
          title: 'Thanh toán khi nhận hàng',
          subtitle: 'Thanh toán COD khi nhận sản phẩm',
          icon: Icons.payments_outlined,
          selected: value == PaymentMethod.cod,
          enabled: enabled,
          onTap: () => onChanged(PaymentMethod.cod),
        ),
        const SizedBox(height: 12),
        _PaymentOption(
          title: 'Chuyển khoản ngân hàng',
          subtitle: 'Thanh toán qua SePay',
          icon: Icons.qr_code_2_outlined,
          selected: value == PaymentMethod.sepay,
          enabled: enabled,
          onTap: () => onChanged(PaymentMethod.sepay),
        ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? CheckoutPalette.sage : CheckoutPalette.field,
        border: Border.all(
          color: selected ? CheckoutPalette.forest : CheckoutPalette.border,
          width: selected ? 1.4 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? CheckoutPalette.forest
                        : CheckoutPalette.surface,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? Colors.white : CheckoutPalette.mutedText,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: CheckoutPalette.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: CheckoutPalette.mutedText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? CheckoutPalette.forest
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? CheckoutPalette.forest
                          : CheckoutPalette.mutedText,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
