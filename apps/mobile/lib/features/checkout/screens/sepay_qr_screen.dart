import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/checkout_mock_data.dart';
import '../models/checkout_summary.dart';
import '../state/checkout_flow_controller.dart';
import '../utils/checkout_assets.dart';
import '../utils/checkout_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/checkout_common.dart';
import 'payment_failure_screen.dart';
import 'payment_success_screen.dart';

class SepayQrScreen extends StatefulWidget {
  const SepayQrScreen({
    super.key,
    required this.controller,
    required this.summary,
    this.isPickup = false,
  });

  final CheckoutFlowController controller;
  final CheckoutSummary summary;
  final bool isPickup;

  @override
  State<SepayQrScreen> createState() => _SepayQrScreenState();
}

class _SepayQrScreenState extends State<SepayQrScreen> {
  static const _initialSeconds = 15 * 60;
  late Timer _timer;
  int _remainingSeconds = _initialSeconds;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    // TODO: Kết nối API SePay và QR thật sau khi backend payment hoàn tất.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _remainingSeconds == 0) return;
      setState(() => _remainingSeconds--);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _timeLabel {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _copy(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đã sao chép $label.')));
  }

  Future<void> _confirmTransfer() async {
    if (_remainingSeconds == 0) return;
    setState(() => _confirming = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _confirming = false);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PaymentSuccessScreen(
          controller: widget.controller,
          summary: widget.summary,
          isPickup: widget.isPickup,
        ),
      ),
    );
  }

  Future<void> _showFailure() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PaymentFailureScreen(
          summary: widget.summary,
          onRetry: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentTotal = widget.isPickup
        ? widget.summary.grandTotal - widget.summary.shippingFee
        : widget.summary.grandTotal;
    final expired = _remainingSeconds == 0;
    return CheckoutTheme(
      child: Scaffold(
        appBar: const FleureAppBar(title: 'Thanh toán SePay QR'),
        body: CheckoutContent(
          children: <Widget>[
            CheckoutInfoBanner(
              icon: expired ? Icons.timer_off_outlined : Icons.wifi_rounded,
              title: expired
                  ? 'Phiên thanh toán đã hết hạn'
                  : 'Đang kết nối xác nhận tự động',
              message: expired
                  ? 'Vui lòng quay lại để tạo mã thanh toán mới.'
                  : 'Giữ màn hình này mở. Fleuré sẽ nhận tín hiệu ngay khi giao dịch hoàn tất.',
              color: expired
                  ? CheckoutPalette.errorSurface
                  : CheckoutPalette.forest50,
              iconColor: expired
                  ? CheckoutPalette.error
                  : CheckoutPalette.forest700,
            ),
            const SizedBox(height: 18),
            Center(
              child: Column(
                children: <Widget>[
                  const Text(
                    'SỐ TIỀN CẦN THANH TOÁN',
                    style: TextStyle(
                      color: CheckoutPalette.charcoal500,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.25,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    formatVnd(paymentTotal),
                    style: CheckoutTypography.hero.copyWith(
                      color: CheckoutPalette.forest900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Mã đơn ${CheckoutMockData.orderCode}',
                    style: const TextStyle(
                      color: CheckoutPalette.charcoal500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CheckoutSurfaceCard(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              borderColor: CheckoutPalette.forest100,
              child: Column(
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: CheckoutPalette.forest950,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      'MÃ CÒN HIỆU LỰC TRONG  $_timeLabel',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const CheckoutAssetImage(
                    asset: CheckoutAssets.sepayQr,
                    width: 222,
                    height: 310,
                    fit: BoxFit.contain,
                    fallbackIcon: Icons.qr_code_2_rounded,
                  ),
                  const SizedBox(height: 13),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: CheckoutPalette.petal400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'Đang chờ giao dịch từ ngân hàng',
                        style: TextStyle(
                          color: CheckoutPalette.charcoal700,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Mở ứng dụng ngân hàng và quét mã QR phía trên',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: CheckoutPalette.charcoal500,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const CheckoutSectionHeader(
              title: 'Thông tin chuyển khoản',
              subtitle: 'Bạn có thể chuyển khoản thủ công nếu không quét mã.',
            ),
            const SizedBox(height: 12),
            CheckoutSurfaceCard(
              child: Column(
                children: <Widget>[
                  const CheckoutDetailRow(
                    label: 'Ngân hàng',
                    value: 'MB Bank · Ngân hàng Quân đội',
                    icon: Icons.account_balance_outlined,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 13),
                    child: Divider(),
                  ),
                  CheckoutDetailRow(
                    label: 'Số tài khoản',
                    value: CheckoutMockData.bankAccount,
                    icon: Icons.credit_card_outlined,
                    trailing: IconButton(
                      tooltip: 'Sao chép số tài khoản',
                      onPressed: () => _copy(
                        CheckoutMockData.bankAccount.replaceAll(' ', ''),
                        'số tài khoản',
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 13),
                    child: Divider(),
                  ),
                  const CheckoutDetailRow(
                    label: 'Chủ tài khoản',
                    value: CheckoutMockData.bankOwner,
                    icon: Icons.person_outline_rounded,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 13),
                    child: Divider(),
                  ),
                  CheckoutDetailRow(
                    label: 'Nội dung chuyển khoản',
                    value: CheckoutMockData.paymentCode,
                    icon: Icons.tag_rounded,
                    trailing: IconButton(
                      tooltip: 'Sao chép nội dung',
                      onPressed: () => _copy(
                        CheckoutMockData.paymentCode,
                        'nội dung chuyển khoản',
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: expired || _confirming ? null : _confirmTransfer,
              icon: _confirming
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.verified_outlined),
              label: Text(
                _confirming
                    ? 'Đang kiểm tra giao dịch...'
                    : 'Tôi đã chuyển khoản',
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _showFailure,
              child: const Text('Không thể hoàn tất thanh toán?'),
            ),
            const SizedBox(height: 10),
            const CheckoutInfoBanner(
              icon: Icons.shield_outlined,
              title: 'Thanh toán được bảo vệ',
              message:
                  'SePay chỉ đối soát giao dịch, không lưu mật khẩu hay thông tin đăng nhập ngân hàng của bạn.',
            ),
            const SizedBox(height: 14),
            const Center(
              child: Text(
                'Cần hỗ trợ? Gọi Fleuré 1900 6868',
                style: TextStyle(
                  color: CheckoutPalette.charcoal500,
                  fontSize: 10.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
