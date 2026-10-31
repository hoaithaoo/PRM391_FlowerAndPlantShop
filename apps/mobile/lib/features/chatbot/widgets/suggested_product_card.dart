import 'package:flutter/material.dart';

import '../models/chatbot_models.dart';

class SuggestedProductCard extends StatelessWidget {
  const SuggestedProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final SuggestedProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Xem chi tiết ${product.name}',
      child: Card(
        margin: EdgeInsets.zero,
        color: const Color(0xFFFFFDF9),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFF3DDE5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('chatbot-product-${product.id}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: <Widget>[
                _ProductImage(imageUrl: product.imageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF171C19),
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _formatPrice(product.price),
                        style: const TextStyle(
                          color: Color(0xFFA84366),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF6B7770),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 58,
      height: 58,
      color: const Color(0xFFFCEAF0),
      alignment: Alignment.center,
      child: const Icon(Icons.local_florist_outlined, color: Color(0xFFA84366)),
    );
    if (imageUrl == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: placeholder,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        imageUrl!,
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

String _formatPrice(String rawPrice) {
  final value = int.tryParse(rawPrice);
  if (value == null) return '$rawPrice ₫';
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[index]);
  }
  return '$buffer ₫';
}
