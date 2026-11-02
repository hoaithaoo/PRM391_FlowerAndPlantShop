import 'dart:async';

import 'package:flutter/material.dart';

import '../../cart/state/cart_controller.dart';
import '../data/checkout_api.dart';
import '../data/checkout_failure.dart';
import '../data/checkout_repository.dart';
import '../models/checkout_flow_models.dart';
import '../models/checkout_summary.dart';
import '../state/checkout_flow_controller.dart';
import '../utils/checkout_theme.dart';
import 'checkout_screen.dart';

/// Tải dữ liệu thật cần thiết trước khi dựng màn checkout hiện có.
class CheckoutEntryScreen extends StatefulWidget {
  const CheckoutEntryScreen({
    super.key,
    required this.cartController,
    required this.checkoutRepository,
    required this.api,
  });

  final CartController cartController;
  final CheckoutRepository checkoutRepository;
  final CheckoutApi api;

  @override
  State<CheckoutEntryScreen> createState() => _CheckoutEntryScreenState();
}

class _CheckoutEntryScreenState extends State<CheckoutEntryScreen> {
  CheckoutFlowController? _flowController;
  CheckoutUserProfile? _profile;
  CheckoutSummary? _summary;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _flowController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _errorMessage = null;
      _summary = null;
    });
    try {
      await widget.cartController.initialize();
      if (widget.cartController.status == CartStatus.error) {
        throw CheckoutFailure(
          code: CheckoutErrorCode.network,
          message: widget.cartController.errorMessage,
        );
      }
      if (widget.cartController.isEmpty) {
        throw const CheckoutFailure(
          code: CheckoutErrorCode.cartEmpty,
          message: 'Giỏ hàng của bạn đang trống.',
        );
      }

      final results = await Future.wait<Object>([
        widget.api.listAddresses(),
        widget.api.getProfile(),
      ]);
      final addresses = results[0] as List<CheckoutAddress>;
      final profile = results[1] as CheckoutUserProfile;
      final items = [
        for (final item in widget.cartController.items)
          CheckoutSummaryItem(
            productId: item.productId,
            name: item.name,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            subtotal: item.subtotal,
            imageUrl: item.imageUrl,
            variant: item.variant.isEmpty ? null : item.variant,
          ),
      ];
      final subtotal = widget.cartController.subtotal;
      _flowController?.dispose();
      final flowController = CheckoutFlowController(addresses: addresses);
      if (!mounted) {
        flowController.dispose();
        return;
      }
      setState(() {
        _flowController = flowController;
        _profile = profile;
        _summary = CheckoutSummary(
          items: items,
          subtotal: subtotal,
          tax: 0,
          shippingFee: 0,
          grandTotal: subtotal,
        );
      });
    } on CheckoutFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _errorMessage = failure.message ??
            'Không thể tải thông tin thanh toán. Vui lòng thử lại.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Không thể tải thông tin thanh toán. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final flowController = _flowController;
    if (summary != null && flowController != null) {
      return CheckoutScreen(
        repository: widget.checkoutRepository,
        api: widget.api,
        profile: _profile,
        summary: summary,
        flowController: flowController,
        onCheckoutCreated: () => unawaited(widget.cartController.initialize()),
      );
    }

    return CheckoutTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('Thanh toán')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _errorMessage == null
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 14),
                      Text('Đang tải thông tin đơn hàng...'),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 42),
                      const SizedBox(height: 12),
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _load,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
