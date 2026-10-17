import 'package:flutter/material.dart';

import '../data/checkout_mock_data.dart';
import '../models/checkout_summary.dart';
import '../utils/checkout_assets.dart';
import '../utils/checkout_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/checkout_common.dart';

class PaymentFailureScreen extends StatelessWidget {
  const PaymentFailureScreen({
    super.key,
    required this.summary,
    required this.onRetry,
  });

  final CheckoutSummary summary;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return CheckoutTheme(
      child: Scaffold(
        appBar: FleureAppBar(
          title: 'Thanh toán chưa hoàn tất',
          closeButton: true,
          showProfile: false,
          onLeadingPressed: () => Navigator.of(context).maybePop(),
        ),
        body: CheckoutContent(
          children: <Widget>[
            const SizedBox(height: 8),
            const Center(
              child: CheckoutHeroMark(
                icon: Icons.close_rounded,
                background: CheckoutPalette.petal100,
                foreground: CheckoutPalette.petal500,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'GIAO DỊCH CHƯA HOÀN TẤT',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CheckoutPalette.petal500,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.7,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Thanh toán gặp gián đoạn',
              textAlign: TextAlign.center,
              style: CheckoutTypography.hero,
            ),
            const SizedBox(height: 8),
            const Text(
              'Đừng lo, đơn hoa của bạn vẫn được giữ trong 14 phút nữa.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CheckoutPalette.charcoal500,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: CheckoutPalette.forest950,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.timer_outlined, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Thời gian giữ đơn  13:42',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CheckoutSurfaceCard(
              color: CheckoutPalette.petal50,
              borderColor: CheckoutPalette.petal200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'ĐƠN HOA ĐANG ĐƯỢC GIỮ',
                        style: TextStyle(
                          color: CheckoutPalette.petal500,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      CheckoutStatusBadge(
                        text: CheckoutMockData.orderCode,
                        color: CheckoutPalette.cream100,
                        textColor: CheckoutPalette.charcoal700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      const CheckoutAssetImage(
                        asset: CheckoutAssets.paymentFailureProduct,
                        width: 92,
                        height: 92,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              summary.items.first.name,
                              style: const TextStyle(
                                color: CheckoutPalette.charcoal900,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              summary.items.first.variant ?? '',
                              style: const TextStyle(
                                color: CheckoutPalette.charcoal500,
                                fontSize: 10.5,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              formatVnd(summary.grandTotal),
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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(),
                  ),
                  const Text(
                    'Có thể giao dịch bị gián đoạn vì:',
                    style: TextStyle(
                      color: CheckoutPalette.charcoal900,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 9),
                  const _Reason(
                    text: 'Ứng dụng ngân hàng đóng trước khi xác nhận.',
                  ),
                  const _Reason(text: 'Số dư hoặc hạn mức giao dịch chưa đủ.'),
                  const _Reason(
                    text: 'Kết nối mạng bị gián đoạn trong lúc đối soát.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const CheckoutInfoBanner(
              icon: Icons.spa_outlined,
              title: 'Hoa của bạn vẫn an toàn',
              message:
                  'Giỏ hoa và khung giờ đã chọn chưa bị hủy. Bạn có thể thử lại ngay mà không cần nhập lại thông tin.',
              color: CheckoutPalette.forest50,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử thanh toán lại'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Đổi phương thức thanh toán'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: CheckoutPalette.forest800,
                side: const BorderSide(color: CheckoutPalette.forest100),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Quay lại'),
            ),
            const SizedBox(height: 16),
            const CheckoutInfoBanner(
              icon: Icons.support_agent_rounded,
              title: 'Đội chăm sóc Fleuré luôn sẵn sàng',
              message:
                  'Gọi 1900 6868 hoặc trò chuyện với chúng tôi để được hỗ trợ.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Reason extends StatelessWidget {
  const _Reason({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.circle, size: 5, color: CheckoutPalette.petal500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: CheckoutPalette.charcoal500,
                fontSize: 10.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
