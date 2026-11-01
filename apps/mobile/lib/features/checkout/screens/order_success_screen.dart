import 'package:flutter/material.dart';

import '../models/placed_order.dart';
import '../utils/checkout_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/checkout_common.dart';

/// Kết quả đơn COD: chưa thu tiền, thanh toán khi nhận hàng.
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.order});

  final PlacedOrder order;

  void _finish(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final address = order.address;
    final result = order.result;
    return CheckoutTheme(
      child: Scaffold(
        appBar: FleureAppBar(
          title: 'Đặt hàng thành công',
          closeButton: true,
          onLeadingPressed: () => _finish(context),
        ),
        body: CheckoutContent(
          children: <Widget>[
            const SizedBox(height: 8),
            const Center(
              child: CheckoutHeroMark(
                icon: Icons.local_florist_rounded,
                background: CheckoutPalette.forest100,
                foreground: CheckoutPalette.forest800,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'ĐÃ GHI NHẬN ĐƠN HÀNG',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CheckoutPalette.forest700,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Đặt hàng thành công!',
              textAlign: TextAlign.center,
              style: CheckoutTypography.hero,
            ),
            const SizedBox(height: 8),
            Text(
              order.pickupTime == null
                  ? 'Fleuré đang chuyển yêu cầu đến xưởng hoa và đội giao nhận.'
                  : 'Fleuré sẽ chuẩn bị hoa trước giờ bạn ghé nhận.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CheckoutPalette.charcoal500,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            CheckoutSurfaceCard(
              borderColor: CheckoutPalette.forest100,
              child: Column(
                children: <Widget>[
                  CheckoutDetailRow(
                    label: 'Mã đơn hàng',
                    value: result.order.orderCode,
                    icon: Icons.receipt_long_outlined,
                  ),
                  const SizedBox(height: 14),
                  CheckoutDetailRow(
                    label: 'Thanh toán',
                    value: order.pickupTime == null
                        ? 'Thanh toán khi nhận hàng'
                        : 'Thanh toán tại cửa hàng',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  const SizedBox(height: 14),
                  CheckoutDetailRow(
                    label: 'Tổng đơn hàng',
                    value: formatVnd(result.invoice.grandTotal),
                    icon: Icons.payments_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const CheckoutSectionHeader(
              title: 'Thông tin giao nhận',
              subtitle: 'Chúng tôi sẽ liên hệ trước khi trao hoa.',
            ),
            const SizedBox(height: 12),
            CheckoutSurfaceCard(
              child: Column(
                children: <Widget>[
                  CheckoutDetailRow(
                    label: 'Người nhận',
                    value: '${address.recipientName} · ${address.phone}',
                    icon: Icons.person_outline_rounded,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 13),
                    child: Divider(),
                  ),
                  CheckoutDetailRow(
                    label: order.pickupTime == null ? 'Địa chỉ' : 'Nhận tại',
                    value: address.fullAddress,
                    icon: Icons.location_on_outlined,
                  ),
                  if (order.pickupTime != null) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 13),
                      child: Divider(),
                    ),
                    CheckoutDetailRow(
                      label: 'Thời gian nhận',
                      value: order.pickupTime!,
                      icon: Icons.schedule_outlined,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              key: const Key('checkout-finish'),
              onPressed: () => _finish(context),
              icon: const Icon(Icons.local_florist_outlined),
              label: const Text('Tiếp tục khám phá'),
            ),
          ],
        ),
      ),
    );
  }
}
