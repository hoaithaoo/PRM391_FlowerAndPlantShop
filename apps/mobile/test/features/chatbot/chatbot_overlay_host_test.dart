import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/chatbot/data/chatbot_repository.dart';
import 'package:plant_flower_mobile/features/chatbot/models/chatbot_models.dart';
import 'package:plant_flower_mobile/features/chatbot/widgets/chatbot_overlay_host.dart';

void main() {
  testWidgets('launcher is shown only when the host is visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatbotOverlayHost(
          repository: WidgetTestChatbotRepository(),
          visible: false,
          child: const Scaffold(body: Text('Trang chủ')),
        ),
      ),
    );

    expect(find.byKey(const Key('chatbot-launcher')), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: ChatbotOverlayHost(
          repository: WidgetTestChatbotRepository(),
          child: const Scaffold(body: Text('Trang chủ')),
        ),
      ),
    );

    expect(find.byKey(const Key('chatbot-launcher')), findsOneWidget);
  });

  testWidgets(
    'panel sends a message and forwards product and incident actions',
    (tester) async {
      String? openedProductId;
      IncidentReportDraft? openedDraft;

      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(body: Text('Trang sản phẩm')),
          builder: (context, child) => ChatbotOverlayHost(
            repository: WidgetTestChatbotRepository(),
            onProductTap: (id) => openedProductId = id,
            onOpenIncidentReport: (draft) => openedDraft = draft,
            child: child!,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('chatbot-launcher')));
      await tester.pumpAndSettle();
      expect(find.text('Trợ lý Nhà Có Hoa'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('chatbot-message-input')),
        'Tư vấn hoa sinh nhật',
      );
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('chatbot-send-button')))
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(const Key('chatbot-send-button')));
      await tester.pumpAndSettle();

      expect(find.text('Mình gợi ý mẫu hoa này cho bạn.'), findsOneWidget);
      expect(find.text('Bó hoa Bình Minh'), findsOneWidget);

      await tester.tap(find.byKey(const Key('chatbot-product-product-1')));
      await tester.pumpAndSettle();
      expect(openedProductId, 'product-1');

      await tester.tap(find.byKey(const Key('chatbot-launcher')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chatbot-incident-action')));
      await tester.pumpAndSettle();
      expect(openedDraft?.paymentId, 'payment-1');
    },
  );

  testWidgets('closing and reopening preserves the conversation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatbotOverlayHost(
          repository: WidgetTestChatbotRepository(),
          child: const Scaffold(body: Text('Trang chủ')),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('chatbot-launcher')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('chatbot-message-input')),
      'Xin chào',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('chatbot-send-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chatbot-close-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chatbot-launcher')));
    await tester.pumpAndSettle();

    expect(find.text('Xin chào'), findsOneWidget);
    expect(find.text('Mình gợi ý mẫu hoa này cho bạn.'), findsOneWidget);
  });
}

class WidgetTestChatbotRepository implements ChatbotRepository {
  @override
  Future<ChatbotReply> sendMessage({
    String? conversationId,
    required String message,
    ChatbotRequestContext? context,
  }) async {
    return ChatbotReply(
      conversationId: conversationId ?? 'conversation-1',
      messageId: 'assistant-1',
      reply: 'Mình gợi ý mẫu hoa này cho bạn.',
      products: const <SuggestedProduct>[
        SuggestedProduct(
          id: 'product-1',
          name: 'Bó hoa Bình Minh',
          price: '350000',
        ),
      ],
      action: const ChatbotAction(
        type: ChatbotActionType.openIncidentReport,
        draft: IncidentReportDraft(
          category: 'PAYMENT',
          title: 'Thanh toán chưa được ghi nhận',
          description: 'Tôi đã thanh toán nhưng trạng thái chưa cập nhật.',
          conversationId: 'conversation-1',
          paymentId: 'payment-1',
        ),
      ),
      createdAt: DateTime.utc(2026, 10, 15),
    );
  }

  @override
  Future<ChatbotHistory> getHistory(
    String conversationId, {
    int page = 1,
  }) async {
    return ChatbotHistory(
      conversationId: conversationId,
      title: null,
      messages: const <ChatMessage>[],
      page: page,
      totalPages: 1,
    );
  }

  @override
  Future<void> deleteConversation(String conversationId) async {}
}
