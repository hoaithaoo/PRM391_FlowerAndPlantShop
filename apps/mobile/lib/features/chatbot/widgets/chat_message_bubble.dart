import 'package:flutter/material.dart';

import '../models/chatbot_models.dart';
import 'suggested_product_card.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onProductTap,
    this.onOpenIncidentReport,
  });

  final ChatMessage message;
  final ValueChanged<String>? onProductTap;
  final ValueChanged<IncidentReportDraft>? onOpenIncidentReport;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatMessageRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF132B1E)
                    : const Color(0xFFF1F7F4),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 5),
                  bottomRight: Radius.circular(isUser ? 5 : 18),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isUser ? Colors.white : const Color(0xFF36403A),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ),
            ),
            if (!isUser && message.products.isNotEmpty) ...<Widget>[
              const SizedBox(height: 9),
              for (final product in message.products) ...<Widget>[
                SuggestedProductCard(
                  product: product,
                  onTap: () => onProductTap?.call(product.id),
                ),
                const SizedBox(height: 8),
              ],
            ],
            if (!isUser && message.action?.draft != null) ...<Widget>[
              const SizedBox(height: 4),
              OutlinedButton.icon(
                key: const Key('chatbot-incident-action'),
                onPressed: () =>
                    onOpenIncidentReport?.call(message.action!.draft!),
                icon: const Icon(Icons.report_problem_outlined),
                label: const Text('Mở báo cáo sự cố'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 46),
                  foregroundColor: const Color(0xFFA84366),
                  side: const BorderSide(color: Color(0xFFF6D6E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
