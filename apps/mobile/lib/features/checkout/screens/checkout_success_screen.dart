import 'package:flutter/material.dart';

import '../models/checkout_result.dart';
import '../utils/currency_formatter.dart';
import '../widgets/checkout_total_section.dart';

class CheckoutSuccessScreen extends StatelessWidget {
  const CheckoutSuccessScreen({super.key, required this.result, this.onDone});

  final CheckoutResult result;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final payment = result.payment;

    return Scaffold(
      appBar: AppBar(title: const Text('Order confirmed')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Icon(
                    Icons.check_circle,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your order has been placed',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Keep the order code below for tracking.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  _DetailsCard(
                    title: 'Order',
                    rows: <_DetailRowData>[
                      _DetailRowData('Order code', result.order.orderCode),
                      _DetailRowData('Status', result.order.status),
                      _DetailRowData(
                        'Invoice number',
                        result.invoice.invoiceNumber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            'Billing total',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          CheckoutTotalSection(
                            subtotal: result.invoice.subtotalAmount,
                            tax: result.invoice.taxAmount,
                            shippingFee: result.invoice.shippingFee,
                            grandTotal: result.invoice.grandTotal,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (payment != null) ...[
                    const SizedBox(height: 16),
                    _DetailsCard(
                      title: 'SePay payment',
                      rows: <_DetailRowData>[
                        _DetailRowData(
                          'Payment code',
                          payment.paymentCode ?? 'Pending',
                        ),
                        _DetailRowData('Status', payment.status),
                        _DetailRowData(
                          'Amount',
                          formatVnd(result.invoice.grandTotal),
                        ),
                      ],
                      footer: _PaymentQrPlaceholder(qrUrl: payment.qrUrl),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: onDone ?? () => Navigator.of(context).maybePop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.title, required this.rows, this.footer});

  final String title;
  final List<_DetailRowData> rows;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final row in rows) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: Text(row.label)),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      row.value,
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (footer != null) ...[const SizedBox(height: 8), footer!],
          ],
        ),
      ),
    );
  }
}

class _PaymentQrPlaceholder extends StatelessWidget {
  const _PaymentQrPlaceholder({required this.qrUrl});

  final String? qrUrl;

  @override
  Widget build(BuildContext context) {
    // TODO: Hiển thị QR thật nếu project đã tích hợp QR package
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          const Icon(Icons.qr_code_2, size: 64),
          const SizedBox(height: 8),
          Text(
            qrUrl == null ? 'QR information is pending.' : 'QR URL: $qrUrl',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DetailRowData {
  const _DetailRowData(this.label, this.value);

  final String label;
  final String value;
}
