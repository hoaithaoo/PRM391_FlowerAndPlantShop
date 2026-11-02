import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/checkout_api.dart';
import '../data/checkout_failure.dart';
import '../models/checkout_result.dart';
import '../models/checkout_summary.dart';
import '../state/checkout_flow_controller.dart';
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
    required this.result,
    required this.api,
    this.pollInterval = const Duration(seconds: 5),
  });

  final CheckoutFlowController controller;
  final CheckoutSummary summary;
  final CheckoutResult result;
  final CheckoutApi api;
  final Duration pollInterval;

  @override
  State<SepayQrScreen> createState() => _SepayQrScreenState();
}

class _SepayQrScreenState extends State<SepayQrScreen>
    with WidgetsBindingObserver {
  Timer? _pollTimer;
  bool _pollInFlight = false;
  bool _terminalHandled = false;
  bool _appActive = true;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    if (_appActive) {
      _startPolling(checkImmediately: true);
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling({bool checkImmediately = true}) {
    if (!_appActive || _terminalHandled || widget.result.payment == null) return;
    _pollTimer?.cancel();
    if (checkImmediately) unawaited(_checkStatus());
    _pollTimer = Timer.periodic(widget.pollInterval, (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    final payment = widget.result.payment;
    if (payment == null || _pollInFlight || _terminalHandled || !_appActive) {
      return;
    }
    _pollInFlight = true;
    if (mounted) setState(() {});
    try {
      final status = await widget.api.getPaymentStatus(payment.id);
      if (!mounted || _terminalHandled) return;
      switch (status.status) {
        case CheckoutPaymentStatus.pending:
          setState(() => _statusMessage = null);
        case CheckoutPaymentStatus.paid:
          _terminalHandled = true;
          _pollTimer?.cancel();
          await Navigator.of(context).pushReplacement<void, void>(
            MaterialPageRoute<void>(
              builder: (_) => PaymentSuccessScreen(
                controller: widget.controller,
                summary: widget.summary,
                result: widget.result,
                paymentStatus: status,
              ),
            ),
          );
        case CheckoutPaymentStatus.failed:
        case CheckoutPaymentStatus.expired:
          _terminalHandled = true;
          _pollTimer?.cancel();
          await Navigator.of(context).pushReplacement<void, void>(
            MaterialPageRoute<void>(
              builder: (_) => PaymentFailureScreen(
                summary: widget.summary,
                orderCode: widget.result.order.orderCode,
                message: status.status == CheckoutPaymentStatus.expired
                    ? 'Giao dịch đã hết hạn. Vui lòng kiểm tra đơn hàng hoặc liên hệ hỗ trợ.'
                    : 'Thanh toán chưa thành công. Vui lòng kiểm tra lại giao dịch.',
                retryLabel: 'Quay về giỏ hàng',
                onRetry: () => Navigator.of(
                  context,
                ).popUntil((route) => route.isFirst),
              ),
            ),
          );
        case CheckoutPaymentStatus.review:
          _terminalHandled = true;
          _pollTimer?.cancel();
          setState(() {
            _statusMessage =
                'Giao dịch đang cần đối soát thủ công. Vui lòng chờ hệ thống xác nhận.';
          });
      }
    } on CheckoutFailure catch (error) {
      if (!mounted || _terminalHandled) return;
      setState(() => _statusMessage = _failureMessage(error));
    } catch (_) {
      if (!mounted || _terminalHandled) return;
      setState(() {
        _statusMessage =
            'Chưa thể kiểm tra giao dịch. Hệ thống sẽ tự động thử lại.';
      });
    } finally {
      _pollInFlight = false;
      if (mounted && !_terminalHandled) setState(() {});
    }
  }

  String _failureMessage(CheckoutFailure failure) {
    return switch (failure.statusCode) {
      401 => 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      403 => 'Tài khoản của bạn không có quyền thực hiện thao tác này.',
      404 => 'Không tìm thấy thông tin thanh toán.',
      _ => 'Chưa thể kiểm tra giao dịch. Hệ thống sẽ tự động thử lại.',
    };
  }

  Future<void> _copyPaymentCode() async {
    final code = widget.result.payment?.paymentCode;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép nội dung chuyển khoản.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.result.payment;
    final qrUrl = payment?.qrUrl;
    final paymentCode = payment?.paymentCode;
    final invoice = widget.result.invoice;
    return CheckoutTheme(
      child: Scaffold(
        appBar: const FleureAppBar(title: 'Thanh toán SePay QR'),
        body: CheckoutContent(
          children: <Widget>[
            CheckoutInfoBanner(
              icon: Icons.wifi_rounded,
              title: 'Đang chờ ngân hàng xác nhận',
              message: _statusMessage ??
                  'Giữ màn hình này mở. Fleuré sẽ cập nhật ngay khi giao dịch được xác nhận.',
              color: _statusMessage == null
                  ? CheckoutPalette.forest50
                  : CheckoutPalette.cream100,
            ),
            const SizedBox(height: 18),
            const Center(
              child: Text(
                'SỐ TIỀN CẦN THANH TOÁN',
                style: TextStyle(
                  color: CheckoutPalette.charcoal500,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.25,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              formatVnd(invoice.grandTotal),
              textAlign: TextAlign.center,
              style: CheckoutTypography.hero.copyWith(
                color: CheckoutPalette.forest900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Mã đơn ${widget.result.order.orderCode}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CheckoutPalette.charcoal500,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 20),
            CheckoutSurfaceCard(
              padding: const EdgeInsets.all(18),
              borderColor: CheckoutPalette.forest100,
              child: Column(
                children: <Widget>[
                  if (qrUrl != null && qrUrl.isNotEmpty)
                    Image.network(
                      qrUrl,
                      width: 240,
                      height: 240,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const _QrUnavailable(),
                    )
                  else
                    const _QrUnavailable(),
                  const SizedBox(height: 14),
                  const Text(
                    'Vui lòng quét mã QR bằng ứng dụng ngân hàng để thanh toán.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: CheckoutPalette.charcoal700,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const CheckoutSectionHeader(
              title: 'Thông tin chuyển khoản',
              subtitle:
                  'Vui lòng giữ nguyên nội dung để hệ thống xác nhận tự động.',
            ),
            const SizedBox(height: 12),
            CheckoutSurfaceCard(
              child: Column(
                children: <Widget>[
                  CheckoutDetailRow(
                    label: 'Nội dung chuyển khoản',
                    value: paymentCode ?? 'Backend chưa cung cấp',
                    icon: Icons.tag_rounded,
                    trailing: paymentCode == null
                        ? null
                        : IconButton(
                            tooltip: 'Sao chép nội dung',
                            onPressed: _copyPaymentCode,
                            icon: const Icon(Icons.copy_rounded, size: 18),
                          ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 13),
                    child: Divider(),
                  ),
                  CheckoutDetailRow(
                    label: 'Mã hóa đơn',
                    value: invoice.invoiceNumber,
                    icon: Icons.receipt_long_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _pollInFlight || _terminalHandled
                  ? null
                  : _checkStatus,
              icon: _pollInFlight
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: const Text('Kiểm tra trạng thái thanh toán'),
            ),
            const SizedBox(height: 14),
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

class _QrUnavailable extends StatelessWidget {
  const _QrUnavailable();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 240,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CheckoutPalette.cream100,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.qr_code_2_rounded,
            size: 56,
            color: CheckoutPalette.charcoal400,
          ),
          SizedBox(height: 12),
          Text(
            'Mã QR chưa khả dụng. Vui lòng thử kiểm tra lại hoặc liên hệ hỗ trợ.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CheckoutPalette.charcoal500,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
