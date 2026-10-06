import 'package:flutter/material.dart';

import '../models/checkout_summary.dart';
import '../utils/currency_formatter.dart';
import 'checkout_total_section.dart';

class OrderSummary extends StatelessWidget {
  const OrderSummary({super.key, required this.summary});

  final CheckoutSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Order summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (summary.items.isEmpty)
              const _CartIntegrationPlaceholder()
            else
              ...summary.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SummaryItem(item: item),
                ),
              ),
            const Divider(),
            const SizedBox(height: 8),
            CheckoutTotalSection(
              subtotal: summary.subtotal,
              tax: summary.tax,
              shippingFee: summary.shippingFee,
              grandTotal: summary.grandTotal,
            ),
            const SizedBox(height: 12),
            Text(
              'Final totals are calculated and confirmed by the server.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.item});

  final CheckoutSummaryItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('${item.quantity}×'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 2),
              Text(
                formatVnd(item.unitPrice),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          formatVnd(item.subtotal),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _CartIntegrationPlaceholder extends StatelessWidget {
  const _CartIntegrationPlaceholder();

  @override
  Widget build(BuildContext context) {
    // TODO: Nhận dữ liệu giỏ hàng thật sau khi Shopping Cart feature được merge
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: <Widget>[
          const Icon(Icons.shopping_bag_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Cart items will appear here after cart integration.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
