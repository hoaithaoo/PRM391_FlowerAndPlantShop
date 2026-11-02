import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/app/app.dart';
import 'package:plant_flower_mobile/features/auth/data/mock_auth_repository.dart';
import 'package:plant_flower_mobile/features/chatbot/data/chatbot_repository.dart';
import 'package:plant_flower_mobile/features/chatbot/models/chatbot_models.dart';
import 'package:plant_flower_mobile/features/checkout/data/mock_checkout_repository.dart';
import 'package:plant_flower_mobile/features/products/data/mock_product_repository.dart';
import 'package:plant_flower_mobile/features/products/screens/product_detail_screen.dart';

import '../support/cart_test_repository.dart';

void main() {
  testWidgets('tapping an AI product suggestion opens its product detail', (
    tester,
  ) async {
    final product = MockProductRepository.defaultProducts.first;
    final auth = MockAuthRepository(delay: Duration.zero);
    final signIn = auth.signInWithPassword(email: 'a@b.vn', password: 'secret');
    await tester.pump(Duration.zero);
    await signIn;
    final app = PlantFlowerApp(
      authRepository: auth,
      productRepository: MockProductRepository(latency: Duration.zero),
      cartRepository: TestCartRepository(),
      chatbotRepository: _SuggestionRepository(product.id, product.name),
      checkoutRepository: const MockCheckoutRepository(),
    );

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chatbot-launcher')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('chatbot-message-input')),
      'Gợi ý hoa cho tôi',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('chatbot-send-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('chatbot-product-${product.id}')));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(find.text(product.name), findsWidgets);
  });
}

class _SuggestionRepository implements ChatbotRepository {
  const _SuggestionRepository(this.productId, this.productName);

  final String productId;
  final String productName;

  @override
  Future<ChatbotReply> sendMessage({
    String? conversationId,
    required String message,
    ChatbotRequestContext? context,
  }) async {
    return ChatbotReply(
      conversationId: conversationId ?? 'conversation-1',
      messageId: 'message-1',
      reply: 'Mình gợi ý sản phẩm này.',
      products: [
        SuggestedProduct(id: productId, name: productName, price: '490000'),
      ],
      createdAt: DateTime.utc(2026, 10, 19),
    );
  }

  @override
  Future<ChatbotHistory> getHistory(
    String conversationId, {
    int page = 1,
  }) async => ChatbotHistory(
    conversationId: conversationId,
    title: null,
    messages: const [],
    page: page,
    totalPages: 1,
  );

  @override
  Future<List<ChatbotConversationSummary>> listConversations() async =>
      const [];

  @override
  Future<void> deleteConversation(String conversationId) async {}
}
