import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/chatbot/models/chatbot_models.dart';

void main() {
  group('ChatbotReply', () {
    test('parses product suggestions and incident action', () {
      final reply = ChatbotReply.fromJson(<String, dynamic>{
        'conversationId': 'conversation-1',
        'messageId': 'message-2',
        'reply': 'Mình đã chuẩn bị thông tin để bạn báo sự cố.',
        'suggestedProducts': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'product-1',
            'name': 'Bó hoa Bình Minh',
            'price': '350000',
            'imageUrl': 'https://example.com/flower.jpg',
          },
        ],
        'action': <String, dynamic>{
          'type': 'OPEN_INCIDENT_REPORT',
          'draft': <String, dynamic>{
            'category': 'PAYMENT',
            'title': 'Thanh toán chưa được ghi nhận',
            'description': 'Tôi đã chuyển khoản nhưng đơn vẫn chưa thanh toán.',
            'orderId': 'order-1',
            'paymentId': 'payment-1',
            'conversationId': 'conversation-1',
          },
        },
        'createdAt': '2026-10-15T08:00:00.000Z',
      });

      expect(reply.conversationId, 'conversation-1');
      expect(reply.products.single.id, 'product-1');
      expect(reply.products.single.price, '350000');
      expect(reply.action?.type, ChatbotActionType.openIncidentReport);
      expect(reply.action?.draft?.paymentId, 'payment-1');
    });

    test('ignores malformed optional metadata instead of throwing', () {
      final reply = ChatbotReply.fromJson(<String, dynamic>{
        'conversationId': 'conversation-1',
        'messageId': 'message-2',
        'reply': 'Chào bạn.',
        'suggestedProducts': <Object?>[
          null,
          'invalid',
          <String, dynamic>{'id': 12, 'name': false},
        ],
        'action': <String, dynamic>{'type': 'UNKNOWN'},
        'createdAt': 'not-a-date',
      });

      expect(reply.products, isEmpty);
      expect(reply.action, isNull);
      expect(reply.createdAt, isNull);
    });
  });

  test('ChatbotRequestContext serializes only non-null values', () {
    const context = ChatbotRequestContext(
      productId: 'product-1',
      orderId: 'order-1',
      source: 'product-detail',
    );

    expect(context.toRequestFields(), <String, dynamic>{
      'productId': 'product-1',
      'context': <String, dynamic>{
        'orderId': 'order-1',
        'source': 'product-detail',
      },
    });
  });
}
