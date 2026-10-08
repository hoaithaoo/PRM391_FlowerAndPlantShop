import 'package:flutter/material.dart';

import '../utils/checkout_theme.dart';

class CheckoutSuccessHero extends StatelessWidget {
  const CheckoutSuccessHero({super.key, required this.orderCode});

  final String orderCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const _SuccessMark(),
        const SizedBox(height: 18),
        Text(
          'Đặt hàng thành công',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: CheckoutPalette.text,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cảm ơn bạn đã đặt hàng. Hãy lưu mã đơn để tiện theo dõi.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: CheckoutPalette.mutedText,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: CheckoutPalette.forest,
            borderRadius: BorderRadius.circular(18),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: CheckoutPalette.forest.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              Text(
                'MÃ ĐƠN HÀNG',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 5),
              SelectableText(
                orderCode,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SuccessMark extends StatelessWidget {
  const _SuccessMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: CheckoutPalette.sage,
        shape: BoxShape.circle,
        border: Border.all(color: CheckoutPalette.sageStrong, width: 1.5),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: CheckoutPalette.forest,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 38),
      ),
    );
  }
}
