import 'package:flutter/material.dart';

import '../models/checkout_summary.dart';
import '../utils/checkout_theme.dart';
import '../utils/currency_formatter.dart';
import 'checkout_section_card.dart';
import 'checkout_total_section.dart';

class OrderSummary extends StatelessWidget {
  const OrderSummary({super.key, required this.summary});

  final CheckoutSummary summary;

  @override
  Widget build(BuildContext context) {
    return CheckoutSectionCard(
      title: 'Thông tin đơn hàng',
      subtitle: 'Kiểm tra sản phẩm trước khi đặt hàng',
      icon: Icons.shopping_bag_outlined,
      trailing: summary.items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: CheckoutPalette.sage,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${summary.totalQuantity} sản phẩm',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: CheckoutPalette.forest,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (summary.items.isEmpty)
            const _CartIntegrationPlaceholder()
          else
            ...summary.items.indexed.map(
              (entry) => Padding(
                padding: EdgeInsets.only(
                  bottom: entry.$1 == summary.items.length - 1 ? 0 : 14,
                ),
                child: _SummaryItem(item: entry.$2),
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Divider(),
          ),
          CheckoutTotalSection(
            subtotal: summary.subtotal,
            tax: summary.tax,
            shippingFee: summary.shippingFee,
            grandTotal: summary.grandTotal,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CheckoutPalette.field,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                  color: CheckoutPalette.forest,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Tổng tiền cuối cùng sẽ được máy chủ tính toán và xác nhận.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: CheckoutPalette.mutedText,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _ProductThumbnail(imageUrl: item.imageUrl),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: CheckoutPalette.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Số lượng: ${item.quantity} · Đơn giá: ${formatVnd(item.unitPrice)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: CheckoutPalette.mutedText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          formatVnd(item.subtotal),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: CheckoutPalette.forest,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: CheckoutPalette.sage,
      alignment: Alignment.center,
      child: const Icon(
        Icons.local_florist_outlined,
        color: CheckoutPalette.forest,
        size: 23,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: SizedBox(
        width: 52,
        height: 52,
        child: imageUrl == null || imageUrl!.isEmpty
            ? fallback
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

class _CartIntegrationPlaceholder extends StatelessWidget {
  const _CartIntegrationPlaceholder();

  @override
  Widget build(BuildContext context) {
    // TODO: Nhận dữ liệu giỏ hàng thật sau khi module Giỏ hàng được merge
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CheckoutPalette.field,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.shopping_bag_outlined,
              color: CheckoutPalette.forest,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sản phẩm sẽ hiển thị tại đây sau khi tích hợp Giỏ hàng.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: CheckoutPalette.mutedText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
