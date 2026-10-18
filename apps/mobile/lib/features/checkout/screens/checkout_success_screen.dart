import 'package:flutter/material.dart';

import '../data/checkout_mock_data.dart';
import '../models/checkout_result.dart';
import '../models/checkout_summary.dart';
import '../state/checkout_flow_controller.dart';
import 'payment_success_screen.dart';

/// Lớp tương thích cho nơi đang dùng kết quả checkout từ API cũ.
class CheckoutSuccessScreen extends StatefulWidget {
  const CheckoutSuccessScreen({super.key, required this.result, this.onDone});

  final CheckoutResult result;
  final VoidCallback? onDone;

  @override
  State<CheckoutSuccessScreen> createState() => _CheckoutSuccessScreenState();
}

class _CheckoutSuccessScreenState extends State<CheckoutSuccessScreen> {
  late final CheckoutFlowController _controller = CheckoutFlowController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.result.invoice;
    final summary = CheckoutSummary(
      items: CheckoutMockData.summary.items,
      subtotal: invoice.subtotalAmount,
      tax: invoice.taxAmount,
      shippingFee: invoice.shippingFee,
      grandTotal: invoice.grandTotal,
    );
    return PaymentSuccessScreen(
      controller: _controller,
      summary: summary,
      onDone: widget.onDone,
    );
  }
}
