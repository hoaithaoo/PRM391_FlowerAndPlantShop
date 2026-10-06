import 'package:flutter/material.dart';

import '../data/checkout_repository.dart';
import '../data/mock_checkout_repository.dart';
import '../models/checkout_request.dart';
import '../models/checkout_result.dart';
import '../models/checkout_summary.dart';
import '../models/payment_method.dart';
import '../state/checkout_controller.dart';
import '../state/checkout_state.dart';
import '../widgets/billing_form.dart';
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
        name: 'Red rose bouquet',
        quantity: 1,
        unitPrice: 250000,
        subtotal: 250000,
      ),
      CheckoutSummaryItem(
        productId: 'mock-product-pot',
        name: 'Minimal ceramic pot',
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
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          if (state.status == CheckoutStatus.error ||
                              state.status ==
                                  CheckoutStatus.authenticationRequired) ...[
                            _CheckoutErrorCard(
                              message:
                                  state.errorMessage ??
                                  'Unable to process checkout.',
                              requiresAuthentication:
                                  state.status ==
                                  CheckoutStatus.authenticationRequired,
                              onDismiss: _checkoutController.resetError,
                            ),
                            const SizedBox(height: 16),
                          ],
                          BillingForm(
                            receiverNameController: _receiverNameController,
                            phoneController: _phoneController,
                            addressController: _addressController,
                            latitudeController: _latitudeController,
                            longitudeController: _longitudeController,
                            noteController: _noteController,
                            enabled: !isSubmitting,
                          ),
                          const SizedBox(height: 24),
                          PaymentMethodSelector(
                            value: _paymentMethod,
                            enabled: !isSubmitting,
                            onChanged: (value) {
                              setState(() => _paymentMethod = value);
                            },
                          ),
                          const SizedBox(height: 24),
                          OrderSummary(summary: widget.summary),
                          const SizedBox(height: 24),
                          CheckoutSubmitButton(
                            isSubmitting: isSubmitting,
                            onPressed: _submitCheckout,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: <Widget>[
            Icon(
              requiresAuthentication
                  ? Icons.lock_clock_outlined
                  : Icons.error_outline,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              tooltip: 'Dismiss',
              icon: const Icon(Icons.close),
              color: colorScheme.onErrorContainer,
            ),
          ],
        ),
      ),
    );
  }
}
