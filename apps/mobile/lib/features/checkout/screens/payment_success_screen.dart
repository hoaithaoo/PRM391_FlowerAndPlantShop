import 'package:flutter/material.dart';

import '../data/checkout_mock_data.dart';
import '../models/checkout_flow_models.dart';
import '../models/checkout_summary.dart';
import '../state/checkout_flow_controller.dart';
import '../utils/checkout_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/checkout_common.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({
    super.key,
    required this.controller,
    required this.summary,
    this.isPickup = false,
    this.onDone,
  });

  final CheckoutFlowController controller;
  final CheckoutSummary summary;
  final bool isPickup;
  final VoidCallback? onDone;

  void _finish(BuildContext context) {
    if (onDone != null) {
      onDone!();
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final address = controller.selectedAddress;
    final branch = controller.selectedBranch;
    final total = isPickup
        ? summary.grandTotal - summary.shippingFee
        : summary.grandTotal;
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
              'Cảm ơn bạn đã để Fleuré gửi thay một lời yêu thương.',
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
                  const Text(
                    'TỔNG THANH TOÁN',
                    style: TextStyle(
                      color: CheckoutPalette.charcoal400,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    formatVnd(total),
                    style: CheckoutTypography.heading.copyWith(
                      color: CheckoutPalette.forest900,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Divider(),
                  ),
                  const Row(
                    children: <Widget>[
                      Expanded(
                        child: CheckoutDetailRow(
                          label: 'Mã đơn hàng',
                          value: CheckoutMockData.orderCode,
                        ),
                      ),
                      Expanded(
                        child: CheckoutDetailRow(
                          label: 'Mã giao dịch',
                          value: CheckoutMockData.transactionCode,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    children: <Widget>[
                      Expanded(
                        child: CheckoutDetailRow(
                          label: 'Phương thức',
                          value: 'SePay · QR ngân hàng',
                        ),
                      ),
                      Expanded(
                        child: CheckoutDetailRow(
                          label: 'Thời gian',
                          value: '05/10/2026 · 14:32',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            CheckoutSectionHeader(
              title: isPickup
                  ? 'Thông tin nhận tại quán'
                  : 'Thông tin giao hoa',
              subtitle: isPickup
                  ? 'Studio đã nhận lịch hẹn của bạn.'
                  : 'Tài xế sẽ liên hệ trước khi giao.',
            ),
            const SizedBox(height: 12),
            CheckoutSurfaceCard(
              child: Column(
                children: <Widget>[
                  CheckoutDetailRow(
                    label: isPickup ? 'Studio' : 'Người nhận',
                    value: isPickup
                        ? branch.name
                        : '${address.recipientName} · ${address.phone}',
                    icon: isPickup
                        ? Icons.storefront_outlined
                        : Icons.person_outline_rounded,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 13),
                    child: Divider(),
                  ),
                  CheckoutDetailRow(
                    label: isPickup ? 'Địa chỉ studio' : 'Địa chỉ giao hoa',
                    value: isPickup ? branch.address : address.fullAddress,
                    icon: Icons.location_on_outlined,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 13),
                    child: Divider(),
                  ),
                  CheckoutDetailRow(
                    label: isPickup ? 'Giờ hẹn nhận' : 'Khung giờ dự kiến',
                    value: isPickup
                        ? controller.pickupTime
                        : 'Hôm nay · 16:00 – 18:00',
                    icon: Icons.schedule_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const CheckoutSectionHeader(
              title: 'Tác phẩm đã đặt',
              subtitle: 'Nghệ nhân bắt đầu chuẩn bị ngay sau xác nhận.',
            ),
            const SizedBox(height: 12),
            CheckoutSurfaceCard(
              child: Column(
                children: <Widget>[
                  CheckoutProductTile(item: summary.items.first),
                  if (controller.cardMessage.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(),
                    ),
                    CheckoutDetailRow(
                      label: 'Lời nhắn viết tay',
                      value: '“${controller.cardMessage}”',
                      icon: Icons.edit_note_rounded,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            const CheckoutSectionHeader(
              title: 'Quy trình xưởng hoa',
              subtitle: 'Theo dõi từng bước tác phẩm được hoàn thiện.',
            ),
            const SizedBox(height: 12),
            const CheckoutSurfaceCard(
              child: CheckoutTimeline(
                steps: <CheckoutTimelineStep>[
                  CheckoutTimelineStep(
                    title: 'Đã xác nhận thanh toán',
                    description: 'Giao dịch được đối soát thành công.',
                    isActive: true,
                  ),
                  CheckoutTimelineStep(
                    title: 'Nghệ nhân chọn hoa',
                    description:
                        'Từng cành hoa tươi được tuyển chọn trong ngày.',
                  ),
                  CheckoutTimelineStep(
                    title: 'Hoàn thiện tác phẩm',
                    description: 'Phối hoa, viết thiệp và kiểm tra lần cuối.',
                  ),
                  CheckoutTimelineStep(
                    title: 'Sẵn sàng trao tay',
                    description: 'Thông báo sẽ được gửi khi đơn hoa lên đường.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => _finish(context),
              icon: const Icon(Icons.route_outlined),
              label: Text(
                isPickup ? 'Theo dõi chuẩn bị hoa' : 'Theo dõi giao hoa',
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _finish(context),
              icon: const Icon(Icons.local_florist_outlined),
              label: const Text('Tiếp tục khám phá Fleuré'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: CheckoutPalette.forest800,
                side: const BorderSide(color: CheckoutPalette.forest100),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
