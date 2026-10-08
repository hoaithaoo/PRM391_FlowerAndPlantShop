import 'package:flutter/material.dart';

import '../utils/checkout_theme.dart';

class CheckoutSubmitButton extends StatelessWidget {
  const CheckoutSubmitButton({
    super.key,
    required this.isSubmitting,
    required this.onPressed,
    this.totalLabel,
  });

  final bool isSubmitting;
  final VoidCallback? onPressed;
  final String? totalLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isSubmitting ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: CheckoutPalette.forest,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isSubmitting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox.square(
                    dimension: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Đang xử lý…'),
                ],
              )
            : Row(
                children: <Widget>[
                  const Icon(Icons.lock_outline, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Đặt hàng')),
                  if (totalLabel != null) ...[
                    Text(
                      totalLabel!,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Icon(Icons.arrow_forward, size: 19),
                ],
              ),
      ),
    );
  }
}
