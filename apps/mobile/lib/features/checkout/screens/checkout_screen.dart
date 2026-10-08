import 'package:flutter/material.dart';

import '../data/checkout_repository.dart';
import '../data/mock_checkout_repository.dart';
import '../models/checkout_request.dart';
import '../models/checkout_result.dart';
import '../models/checkout_summary.dart';
import '../models/payment_method.dart';
import '../state/checkout_controller.dart';
import '../state/checkout_state.dart';
import '../utils/checkout_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/billing_form.dart';
import '../widgets/checkout_section_card.dart';
import '../widgets/checkout_submit_button.dart';
import '../widgets/order_summary.dart';
import '../widgets/payment_method_selector.dart';
import 'checkout_success_screen.dart';

typedef CheckoutSuccessHandler =
    void Function(BuildContext context, CheckoutResult result);

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.repository,
    required this.summary,
    this.onCheckoutSuccess,
  });

  factory CheckoutScreen.withMockData({
    Key? key,
    CheckoutSummary summary = mockCheckoutSummary,
    CheckoutSuccessHandler? onCheckoutSuccess,
  }) {
    return CheckoutScreen(
      key: key,
      repository: MockCheckoutRepository(summary: summary),
      summary: summary,
      onCheckoutSuccess: onCheckoutSuccess,
    );
  }

  final CheckoutRepository repository;
  final CheckoutSummary summary;
  final CheckoutSuccessHandler? onCheckoutSuccess;

  static const CheckoutSummary mockCheckoutSummary = CheckoutSummary(
    items: <CheckoutSummaryItem>[
      CheckoutSummaryItem(
        productId: 'mock-product-rose',
        name: 'Bó hoa hồng đỏ',
        quantity: 1,
        unitPrice: 250000,
        subtotal: 250000,
      ),
      CheckoutSummaryItem(
        productId: 'mock-product-pot',
        name: 'Chậu gốm tối giản',
        quantity: 2,
        unitPrice: 120000,
        subtotal: 240000,
      ),
    ],
    subtotal: 490000,
    tax: 39200,
    shippingFee: 30000,
    grandTotal: 559200,
  );

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _receiverNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _noteController = TextEditingController();

  late CheckoutController _checkoutController;
  PaymentMethod _paymentMethod = PaymentMethod.cod;

  @override
  void initState() {
    super.initState();
    _checkoutController = CheckoutController(repository: widget.repository);
  }

  @override
  void didUpdateWidget(covariant CheckoutScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.repository, widget.repository)) {
      _checkoutController.dispose();
      _checkoutController = CheckoutController(repository: widget.repository);
    }
  }

  @override
  void dispose() {
    _checkoutController.dispose();
    _receiverNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitCheckout() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    FocusScope.of(context).unfocus();
    final normalizedNote = _noteController.text.trim();
    final request = CheckoutRequest(
      receiverName: _receiverNameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      latitude: double.parse(_latitudeController.text.trim()),
      longitude: double.parse(_longitudeController.text.trim()),
      paymentMethod: _paymentMethod,
      note: normalizedNote.isEmpty ? null : normalizedNote,
    );

    // Chuyển sang trạng thái gửi và khóa thao tác cho đến khi có kết quả
    final result = await _checkoutController.submit(request);
    if (!mounted || result == null) {
      return;
    }

    final successHandler = widget.onCheckoutSuccess;
    if (successHandler != null) {
      successHandler(context, result);
      return;
    }

    // TODO: Đăng ký CheckoutScreen vào router sau khi merge foundation
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CheckoutSuccessScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CheckoutTheme(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          title: const Text('Thanh toán'),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(),
          ),
        ),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _checkoutController,
            builder: (context, _) {
              final state = _checkoutController.state;
              final isSubmitting = state.isSubmitting;

              return AutofillGroup(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              'THANH TOÁN AN TOÀN',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: CheckoutPalette.forest,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.25,
                                  ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'Hoàn tất đơn hàng',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: CheckoutPalette.text,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Vui lòng cung cấp thông tin nhận hàng và chọn phương thức thanh toán.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: CheckoutPalette.mutedText,
                                    height: 1.5,
                                  ),
                            ),
                            const SizedBox(height: 22),
                            if (state.status == CheckoutStatus.error ||
                                state.status ==
                                    CheckoutStatus.authenticationRequired) ...[
                              _CheckoutErrorCard(
                                message:
                                    state.errorMessage ??
                                    'Không thể xử lý đơn hàng lúc này.',
                                requiresAuthentication:
                                    state.status ==
                                    CheckoutStatus.authenticationRequired,
                                onDismiss: _checkoutController.resetError,
                              ),
                              const SizedBox(height: 18),
                            ],
                            CheckoutSectionCard(
                              title: 'Thông tin nhận hàng',
                              subtitle: 'Đơn hàng sẽ được giao đến đâu?',
                              icon: Icons.local_shipping_outlined,
                              child: BillingForm(
                                receiverNameController: _receiverNameController,
                                phoneController: _phoneController,
                                addressController: _addressController,
                                latitudeController: _latitudeController,
                                longitudeController: _longitudeController,
                                noteController: _noteController,
                                enabled: !isSubmitting,
                              ),
                            ),
                            const SizedBox(height: 18),
                            CheckoutSectionCard(
                              title: 'Phương thức thanh toán',
                              subtitle: 'Chọn cách bạn muốn thanh toán',
                              icon: Icons.wallet_outlined,
                              child: PaymentMethodSelector(
                                value: _paymentMethod,
                                enabled: !isSubmitting,
                                onChanged: (value) {
                                  setState(() => _paymentMethod = value);
                                },
                              ),
                            ),
                            const SizedBox(height: 18),
                            OrderSummary(summary: widget.summary),
                            const SizedBox(height: 20),
                            CheckoutSubmitButton(
                              isSubmitting: isSubmitting,
                              totalLabel: formatVnd(widget.summary.grandTotal),
                              onPressed: _submitCheckout,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const Icon(
                                  Icons.lock_outline,
                                  size: 15,
                                  color: CheckoutPalette.mutedText,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Thanh toán an toàn · Thông tin luôn được bảo mật',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: CheckoutPalette.mutedText,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CheckoutErrorCard extends StatelessWidget {
  const _CheckoutErrorCard({
    required this.message,
    required this.requiresAuthentication,
    required this.onDismiss,
  });

  final String message;
  final bool requiresAuthentication;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CheckoutPalette.errorSurface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: CheckoutPalette.error.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CheckoutPalette.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                requiresAuthentication
                    ? Icons.lock_clock_outlined
                    : Icons.error_outline,
                size: 20,
                color: CheckoutPalette.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: CheckoutPalette.text,
                  height: 1.35,
                ),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              tooltip: 'Đóng thông báo',
              icon: const Icon(Icons.close),
              color: CheckoutPalette.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}
