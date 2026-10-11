import 'package:flutter/material.dart';

import '../data/checkout_mock_data.dart';
import '../models/checkout_flow_models.dart';
import '../models/checkout_summary.dart';
import '../state/checkout_flow_controller.dart';
import '../utils/checkout_assets.dart';
import '../utils/checkout_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/checkout_common.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({
    super.key,
    required this.controller,
    required this.summary,
    required this.isPickup,
  });

  final CheckoutFlowController controller;
  final CheckoutSummary summary;
  final bool isPickup;

  void _finish(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final address = controller.selectedAddress;
    final branch = controller.selectedBranch;
    final payment = isPickup
        ? controller.pickupPaymentMethod?.label ?? 'Thanh toán tại cửa hàng'
        : controller.deliveryPaymentMethod?.label ?? 'Thanh toán khi nhận hàng';
    final total = isPickup
        ? summary.grandTotal - summary.shippingFee
        : summary.grandTotal;
    return CheckoutTheme(
      child: Scaffold(
        appBar: FleureAppBar(
          title: 'Chi tiết tác phẩm',
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
              isPickup
                  ? 'Studio đã nhận yêu cầu và sẽ chuẩn bị hoa đúng giờ hẹn.'
                  : 'Fleuré đang chuyển yêu cầu đến xưởng hoa và đội giao nhận.',
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
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: CheckoutDetailRow(
                          label: 'Mã đơn hàng',
                          value: CheckoutMockData.orderCode,
                          icon: Icons.receipt_long_outlined,
                        ),
                      ),
                      CheckoutStatusBadge(
                        text: isPickup ? 'Đang chuẩn bị' : 'Đã tiếp nhận',
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(),
                  ),
                  CheckoutDetailRow(
                    label: 'Thanh toán',
                    value: payment,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  const SizedBox(height: 14),
                  CheckoutDetailRow(
                    label: 'Tổng đơn hàng',
                    value: formatVnd(total),
                    icon: Icons.payments_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            CheckoutSectionHeader(
              title: isPickup ? 'Lịch hẹn nhận hoa' : 'Thông tin giao nhận',
              subtitle: isPickup
                  ? 'Vui lòng đến trong khung giờ đã chọn.'
                  : 'Chúng tôi sẽ liên hệ trước khi trao hoa.',
            ),
            const SizedBox(height: 12),
            CheckoutSurfaceCard(
              child: Column(
                children: <Widget>[
                  CheckoutDetailRow(
                    label: isPickup ? 'Studio nhận hoa' : 'Người nhận',
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
                    label: 'Địa chỉ',
                    value: isPickup ? branch.address : address.fullAddress,
                    icon: Icons.location_on_outlined,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 13),
                    child: Divider(),
                  ),
                  CheckoutDetailRow(
                    label: isPickup ? 'Khung giờ nhận' : 'Dự kiến giao',
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
              title: 'Tác phẩm đã chọn',
              subtitle: 'Mỗi thiết kế được nghệ nhân thực hiện thủ công.',
            ),
            const SizedBox(height: 12),
            CheckoutSurfaceCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const CheckoutAssetImage(
                    asset: CheckoutAssets.orderSuccessProduct,
                    width: 104,
                    height: 116,
                    borderRadius: BorderRadius.all(Radius.circular(13)),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          summary.items.first.name,
                          style: const TextStyle(
                            color: CheckoutPalette.charcoal900,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          summary.items.first.variant ?? '',
                          style: const TextStyle(
                            color: CheckoutPalette.charcoal500,
                            fontSize: 10.5,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 13),
                        Text(
                          formatVnd(summary.items.first.subtotal),
                          style: const TextStyle(
                            color: CheckoutPalette.forest900,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const CheckoutSectionHeader(
              title: 'Lộ trình tác phẩm',
              subtitle: 'Fleuré cập nhật ngay khi trạng thái thay đổi.',
            ),
            const SizedBox(height: 12),
            const CheckoutSurfaceCard(
              child: CheckoutTimeline(
                steps: <CheckoutTimelineStep>[
                  CheckoutTimelineStep(
                    title: 'Đơn hàng đã được ghi nhận',
                    description: 'Thông tin và khung giờ đã được giữ chỗ.',
                    isActive: true,
                  ),
                  CheckoutTimelineStep(
                    title: 'Nghệ nhân đang chọn hoa',
                    description:
                        'Hoa tươi được tuyển lựa theo thiết kế đã đặt.',
                  ),
                  CheckoutTimelineStep(
                    title: 'Tạo hình và viết thiệp',
                    description: 'Tác phẩm được hoàn thiện thủ công tại xưởng.',
                  ),
                  CheckoutTimelineStep(
                    title: 'Sẵn sàng trao tay',
                    description: 'Bạn sẽ nhận thông báo khi hoa đã sẵn sàng.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => _finish(context),
              icon: const Icon(Icons.route_outlined),
              label: const Text('Theo dõi đơn hoa'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _finish(context),
              icon: const Icon(Icons.local_florist_outlined),
              label: const Text('Tiếp tục khám phá'),
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
