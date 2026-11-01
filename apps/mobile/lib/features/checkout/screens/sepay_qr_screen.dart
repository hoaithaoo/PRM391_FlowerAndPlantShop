import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/checkout_repository.dart';
import '../models/placed_order.dart';
import '../utils/checkout_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/checkout_common.dart';
import 'payment_failure_screen.dart';
import 'payment_success_screen.dart';

/// Hiển thị QR SePay thật và hỏi trạng thái mỗi 3 giây cho tới khi có kết quả.
class SepayQrScreen extends StatefulWidget {
  const SepayQrScreen({
    super.key,
    required this.order,
    required this.repository,
  });

  final PlacedOrder order;
  final CheckoutRepository repository;

  @override
  State<SepayQrScreen> createState() => _SepayQrScreenState();
}

class _SepayQrScreenState extends State<SepayQrScreen> {
  static const _initialSeconds = 15 * 60;
  static const _pollInterval = Duration(seconds: 3);

  late final Timer _countdown;
  Timer? _poll;
  int _remainingSeconds = _initialSeconds;
  bool _checking = false;
  bool _underReview = false;

  String get _paymentId => widget.order.result.payment!.id;

  @override
  void initState() {
    super.initState();
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _remainingSeconds == 0) return;
      setState(() => _remainingSeconds--);
    });
    _startPolling();
  }

  @override
  void dispose() {
    _countdown.cancel();
    _poll?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(_pollInterval, (_) => _checkStatus());
  }

  /// Trả về trạng thái server, `null` nếu lần gọi lỗi hoặc đang có lần gọi khác.
  Future<String?> _checkStatus() async {
    if (_checking) return null;
    _checking = true;
    try {
      final status = await widget.repository.getPaymentStatus(_paymentId);
      if (mounted) _applyStatus(status);
      return status;
    } catch (_) {
      // Lỗi mạng tạm thời: lần poll sau thử lại.
      return null;
    } finally {
      _checking = false;
    }
  }

  void _applyStatus(String status) {
    switch (status) {
      case 'PAID':
        _poll?.cancel();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => PaymentSuccessScreen(order: widget.order),
          ),
        );
      case 'EXPIRED' || 'FAILED':
        _poll?.cancel();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => PaymentFailureScreen(
              order: widget.order,
              repository: widget.repository,
              // Đơn đã tự hủy phía server, gọi hủy nữa sẽ nhận ORDER_CANNOT_CANCEL.
              canCancel: false,
              isExpired: status == 'EXPIRED',
            ),
          ),
        );
      case 'REVIEW':
        _poll?.cancel();
        setState(() => _underReview = true);
    }
  }

  Future<void> _confirmTransfer() async {
    final messenger = ScaffoldMessenger.of(context);
    final status = await _checkStatus();
    if (!mounted || (status != 'PENDING' && status != null)) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Chưa nhận được giao dịch. Vui lòng chờ thêm ít phút.'),
      ),
    );
  }

  Future<void> _showFailure() async {
    // Dừng poll để PAID không thay route của màn đang nằm trên.
    _poll?.cancel();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PaymentFailureScreen(
          order: widget.order,
          repository: widget.repository,
          canCancel: true,
          canRetry: true,
        ),
      ),
    );
    if (mounted) _startPolling();
  }

  Future<void> _copy(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đã sao chép $label.')));
  }

  String get _timeLabel {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.order.result;
    final payment = result.payment!;
    final total = result.invoice.grandTotal;
    final paymentCode = payment.paymentCode;
    final qrUrl = payment.qrUrl;
    final expired = _remainingSeconds == 0;
    return CheckoutTheme(
      child: Scaffold(
        appBar: const FleureAppBar(title: 'Thanh toán SePay QR'),
        body: CheckoutContent(
          children: <Widget>[
            CheckoutInfoBanner(
              key: const Key('sepay-status-banner'),
              icon: _underReview
                  ? Icons.manage_search_rounded
                  : expired
                  ? Icons.timer_off_outlined
                  : Icons.wifi_rounded,
              title: _underReview
                  ? 'Thanh toán đang được cửa hàng kiểm tra'
                  : expired
                  ? 'Phiên thanh toán đã hết hạn'
                  : 'Đang chờ xác nhận tự động',
              message: _underReview
                  ? 'Đã nhận giao dịch nhưng số tiền hoặc thời gian chưa khớp. Cửa hàng sẽ liên hệ với bạn.'
                  : expired
                  ? 'Đang cập nhật trạng thái từ máy chủ.'
                  : 'Giữ màn hình này mở. Fleuré sẽ nhận tín hiệu ngay khi giao dịch hoàn tất.',
              color: expired || _underReview
                  ? CheckoutPalette.errorSurface
                  : CheckoutPalette.forest50,
              iconColor: expired || _underReview
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
                    formatVnd(total),
                    style: CheckoutTypography.hero.copyWith(
                      color: CheckoutPalette.forest900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Mã đơn ${result.order.orderCode}',
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
                  if (qrUrl != null)
                    Image.network(
                      qrUrl,
                      key: const Key('sepay-qr-image'),
                      width: 240,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const _NoQrNotice(),
                    )
                  else
                    const _NoQrNotice(),
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
              subtitle:
                  'Chuyển đúng số tiền và ghi đúng nội dung để được xác nhận tự động.',
            ),
            const SizedBox(height: 12),
            CheckoutSurfaceCard(
              child: Column(
                children: <Widget>[
                  CheckoutDetailRow(
                    label: 'Số tiền',
                    value: formatVnd(total),
                    icon: Icons.payments_outlined,
                    trailing: IconButton(
                      tooltip: 'Sao chép số tiền',
                      onPressed: () => _copy('$total', 'số tiền'),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                    ),
                  ),
                  if (paymentCode != null) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 13),
                      child: Divider(),
                    ),
                    CheckoutDetailRow(
                      label: 'Nội dung chuyển khoản',
                      value: paymentCode,
                      icon: Icons.tag_rounded,
                      trailing: IconButton(
                        tooltip: 'Sao chép nội dung',
                        onPressed: () =>
                            _copy(paymentCode, 'nội dung chuyển khoản'),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_underReview)
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Về trang chủ'),
              )
            else ...[
              FilledButton.icon(
                key: const Key('sepay-confirm-transfer'),
                onPressed: _confirmTransfer,
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Tôi đã chuyển khoản'),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const Key('sepay-cannot-complete'),
                onPressed: _showFailure,
                child: const Text('Không thể hoàn tất thanh toán?'),
              ),
            ],
            const SizedBox(height: 10),
            const CheckoutInfoBanner(
              icon: Icons.shield_outlined,
              title: 'Thanh toán được bảo vệ',
              message:
                  'SePay chỉ đối soát giao dịch, không lưu mật khẩu hay thông tin đăng nhập ngân hàng của bạn.',
            ),
          ],
        ),
      ),
    );
  }
}

class _NoQrNotice extends StatelessWidget {
  const _NoQrNotice();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Text(
        'Chưa tải được mã QR. Vui lòng chuyển khoản theo thông tin bên dưới.',
        textAlign: TextAlign.center,
        style: TextStyle(color: CheckoutPalette.charcoal500, fontSize: 12),
      ),
    );
  }
}
