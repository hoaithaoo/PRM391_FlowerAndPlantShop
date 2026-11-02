import 'package:flutter/material.dart';

import '../models/checkout_result.dart';
import '../utils/checkout_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/checkout_common.dart';

/// Màn hình tương thích cho các điểm gọi cũ chỉ có kết quả checkout.
class CheckoutSuccessScreen extends StatelessWidget {
  const CheckoutSuccessScreen({super.key, required this.result, this.onDone});

  final CheckoutResult result;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    return CheckoutTheme(
      child: Scaffold(
        appBar: const FleureAppBar(title: 'Đặt hàng thành công'),
        body: CheckoutContent(
          children: <Widget>[
            const SizedBox(height: 32),
            const Center(
              child: CheckoutHeroMark(
                icon: Icons.check_rounded,
                background: CheckoutPalette.forest100,
                foreground: CheckoutPalette.forest800,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Đặt hàng thành công!',
              textAlign: TextAlign.center,
              style: CheckoutTypography.hero,
            ),
            const SizedBox(height: 20),
            CheckoutSurfaceCard(
              child: Column(
                children: <Widget>[
                  CheckoutDetailRow(
                    label: 'Mã đơn hàng',
                    value: result.order.orderCode,
                  ),
                  const Divider(height: 28),
                  CheckoutDetailRow(
                    label: 'Tổng đơn hàng',
                    value: formatVnd(result.invoice.grandTotal),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onDone ??
                  () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Hoàn tất'),
            ),
          ],
        ),
      ),
    );
  }
}
