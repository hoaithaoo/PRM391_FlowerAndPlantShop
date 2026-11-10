import 'package:flutter/material.dart';

import '../models/placed_order.dart';
import '../utils/checkout_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/checkout_common.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key, required this.order});

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
          title: 'Thanh toán thành công',
          closeButton: true,
          onLeadingPressed: () => _finish(context),
        ),
        body: CheckoutContent(
          children: <Widget>[
            const SizedBox(height: 8),
            const Center(
              child: CheckoutHeroMark(
                icon: Icons.check_rounded,
                background: CheckoutPalette.forest100,
                foreground: CheckoutPalette.forest800,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'GIAO DỊCH THÀNH CÔNG',
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
              'Thanh toán hoàn tất',
              textAlign: TextAlign.center,
              style: CheckoutTypography.hero,
            ),
            const SizedBox(height: 8),
            const Text(
              'Cảm ơn bạn đã để Nhà Có Hoa gửi thay một lời yêu thương.',
              textAlign: TextAlign.center,
              style: TextStyle(
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
                    label: 'Tổng thanh toán',
                    value: formatVnd(result.invoice.grandTotal),
                    icon: Icons.payments_outlined,
                  ),
                  const SizedBox(height: 14),
                  CheckoutDetailRow(
                    label: 'Mã đơn hàng',
                    value: result.order.orderCode,
                    icon: Icons.receipt_long_outlined,
                  ),
                  if (result.payment?.paymentCode case final code?) ...[
                    const SizedBox(height: 14),
                    CheckoutDetailRow(
                      label: 'Mã thanh toán',
                      value: code,
                      icon: Icons.tag_rounded,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            CheckoutSectionHeader(
              title: order.pickupTime == null
                  ? 'Thông tin giao hoa'
                  : 'Thông tin nhận hoa',
              subtitle: order.pickupTime == null
                  ? 'Tài xế sẽ liên hệ trước khi giao.'
                  : 'Nhà Có Hoa sẽ chuẩn bị hoa trước giờ bạn ghé nhận.',
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
                    label: order.pickupTime == null
                        ? 'Địa chỉ giao hoa'
                        : 'Nhận tại',
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
                  if (order.cardMessage.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 13),
                      child: Divider(),
                    ),
                    CheckoutDetailRow(
                      label: 'Lời nhắn viết tay',
                      value: '“${order.cardMessage}”',
                      icon: Icons.edit_note_rounded,
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
              label: const Text('Tiếp tục khám phá Nhà Có Hoa'),
            ),
          ],
        ),
      ),
    );
  }
}
