import 'package:flutter/material.dart';

import '../data/checkout_repository.dart';
import '../models/placed_order.dart';
import '../utils/checkout_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/checkout_common.dart';

/// Backend tự hủy đơn hết hạn và hoàn kho, nên không cần nút hủy khi hết hạn.
class PaymentFailureScreen extends StatefulWidget {
  const PaymentFailureScreen({
    super.key,
    required this.order,
    required this.repository,
    this.canCancel = false,
    this.canRetry = false,
    this.isExpired = false,
  });

  final PlacedOrder order;
  final CheckoutRepository repository;
  final bool canCancel;

  /// Mã thanh toán còn hiệu lực, có thể quay lại màn QR.
  final bool canRetry;

  /// Mã thanh toán đã hết hạn.
  final bool isExpired;

  @override
  State<PaymentFailureScreen> createState() => _PaymentFailureScreenState();
}

class _PaymentFailureScreenState extends State<PaymentFailureScreen> {
  bool _cancelling = false;

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đơn hàng này?'),
        content: const Text('Đơn sẽ bị hủy và không khôi phục được.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Giữ đơn'),
          ),
          FilledButton(
            key: const Key('payment-confirm-cancel'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _cancelling = true);
    try {
      await widget.repository.cancelOrder(
        widget.order.result.order.id,
        reason: 'Khách không hoàn tất thanh toán',
      );
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Đã hủy đơn hàng.')));
      _goHome();
    } catch (_) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Không hủy được đơn hàng. Vui lòng thử lại.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.order.result;
    return CheckoutTheme(
      child: Scaffold(
        appBar: FleureAppBar(
          title: 'Thanh toán chưa hoàn tất',
          closeButton: true,
          showProfile: false,
          onLeadingPressed: () =>
              widget.canRetry ? Navigator.of(context).maybePop() : _goHome(),
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
            Text(
              widget.canRetry
                  ? 'Mã thanh toán vẫn còn hiệu lực, bạn có thể quay lại để chuyển khoản.'
                  : (widget.isExpired || widget.canCancel)
                  ? 'Mã thanh toán đã hết hạn. Đơn hàng đã tự hủy, hàng và voucher đã được trả lại.'
                  : 'Đơn hàng này đã bị hủy.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CheckoutPalette.charcoal500,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            CheckoutSurfaceCard(
              color: CheckoutPalette.petal50,
              borderColor: CheckoutPalette.petal200,
              child: Column(
                children: <Widget>[
                  CheckoutDetailRow(
                    label: 'Mã đơn hàng',
                    value: result.order.orderCode,
                    icon: Icons.receipt_long_outlined,
                  ),
                  const SizedBox(height: 14),
                  CheckoutDetailRow(
                    label: 'Tổng thanh toán',
                    value: formatVnd(result.invoice.grandTotal),
                    icon: Icons.payments_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            if (widget.canRetry) ...[
              FilledButton.icon(
                key: const Key('payment-retry'),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Quay lại thanh toán'),
              ),
              const SizedBox(height: 10),
            ],
            if (widget.canCancel) ...[
              OutlinedButton.icon(
                key: const Key('payment-cancel-order'),
                onPressed: _cancelling ? null : _cancelOrder,
                icon: const Icon(Icons.cancel_outlined),
                label: Text(_cancelling ? 'Đang hủy đơn...' : 'Hủy đơn'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: CheckoutPalette.error,
                  side: const BorderSide(color: CheckoutPalette.petal200),
                ),
              ),
              const SizedBox(height: 6),
            ],
            TextButton(onPressed: _goHome, child: const Text('Về trang chủ')),
          ],
        ),
      ),
    );
  }
}
