import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/chatbot/data/chatbot_failure.dart';
import 'package:plant_flower_mobile/features/chatbot/data/chatbot_repository.dart';
import 'package:plant_flower_mobile/features/chatbot/models/chatbot_models.dart';
import 'package:plant_flower_mobile/features/chatbot/state/chatbot_controller.dart';
import 'package:plant_flower_mobile/features/chatbot/state/chatbot_state.dart';
import 'package:plant_flower_mobile/features/chatbot/widgets/chat_message_bubble.dart';
import 'package:plant_flower_mobile/features/chatbot/widgets/chatbot_panel.dart';

void main() {
  test('send keeps the user message and appends the assistant reply', () async {
    final repository = FakeChatbotRepository();
    final controller = ChatbotController(
      repository: repository,
      contextProvider: () => const ChatbotRequestContext(
        productId: 'product-1',
        source: 'product-detail',
      ),
    );

    await controller.send('  Tư vấn hoa sinh nhật  ');

    expect(repository.lastMessage, 'Tư vấn hoa sinh nhật');
    expect(repository.lastContext?.productId, 'product-1');
    expect(controller.state.conversationId, 'conversation-1');
    expect(controller.state.messages, hasLength(2));
    expect(controller.state.messages.first.role, ChatMessageRole.user);
    expect(controller.state.messages.last.role, ChatMessageRole.assistant);
    expect(controller.state.status, ChatbotStatus.ready);
  });

  test('send ignores another message while a request is in flight', () async {
    final completer = Completer<ChatbotReply>();
    final repository = FakeChatbotRepository(sendCompleter: completer);
    final controller = ChatbotController(repository: repository);

    final firstSend = controller.send('Tin đầu');
    await Future<void>.delayed(Duration.zero);
    await controller.send('Tin trùng');

    expect(repository.sendCalls, 1);
    expect(controller.state.messages, hasLength(1));
    expect(controller.state.status, ChatbotStatus.sending);

    completer.complete(_reply);
    await firstSend;
    expect(controller.state.messages, hasLength(2));
  });

  test('send preserves conversation and exposes provider error', () async {
    final repository = FakeChatbotRepository(
      sendFailure: const ChatbotFailure(
        code: ChatbotErrorCode.providerTimeout,
        statusCode: 504,
      ),
    );
    final controller = ChatbotController(repository: repository);

    await controller.send('Bạn còn ở đó không?');

    expect(controller.state.messages.single.content, 'Bạn còn ở đó không?');
    expect(controller.state.status, ChatbotStatus.error);
    expect(controller.state.errorMessage, contains('phản hồi'));
  });

  group('cart action', () {
    ChatbotReply cartReply() => ChatbotReply.fromJson({
      'conversationId': 'conversation-1',
      'messageId': 'assistant-1',
      'reply': 'Đã thêm vào giỏ.',
      'cartActions': [
        {'type': 'UPDATE', 'productId': 'product-1', 'quantity': 2},
      ],
    });

    test('applies the action before showing the reply', () async {
      final completer = Completer<ChatbotReply>()..complete(cartReply());
      final calls = <ChatbotCartAction>[];
      final controller = ChatbotController(
        repository: FakeChatbotRepository(sendCompleter: completer),
        onCartAction: (action) async {
          calls.add(action);
          return null;
        },
      );

      await controller.send('Đổi thành 2 bó');

      expect(calls.single.type, ChatbotCartActionType.update);
      expect(calls.single.productId, 'product-1');
      expect(calls.single.quantity, 2);
      expect(controller.state.status, ChatbotStatus.ready);
    });

    test('runs actions in order and stops at the first failure', () async {
      final completer = Completer<ChatbotReply>()
        ..complete(
          ChatbotReply.fromJson({
            'conversationId': 'conversation-1',
            'messageId': 'assistant-1',
            'reply': 'Đã xong.',
            'cartActions': [
              {'type': 'REMOVE', 'productId': 'product-1'},
              {'type': 'ADD', 'productId': 'product-2', 'quantity': 1},
              {'type': 'CLEAR'},
            ],
          }),
        );
      final calls = <ChatbotCartActionType>[];
      final controller = ChatbotController(
        repository: FakeChatbotRepository(sendCompleter: completer),
        onCartAction: (action) async {
          calls.add(action.type);
          return action.type == ChatbotCartActionType.add ? 'Hết hàng' : null;
        },
      );

      await controller.send('Bỏ hoa hồng, thêm hướng dương');

      expect(calls, [ChatbotCartActionType.remove, ChatbotCartActionType.add]);
      expect(controller.state.errorMessage, 'Hết hàng');
    });

    test('parses every action type and rejects unknown ones', () {
      for (final (raw, type) in [
        ('ADD', ChatbotCartActionType.add),
        ('UPDATE', ChatbotCartActionType.update),
        ('REMOVE', ChatbotCartActionType.remove),
        ('CLEAR', ChatbotCartActionType.clear),
      ]) {
        expect(ChatbotCartAction.tryParse({'type': raw})?.type, type);
      }
      expect(ChatbotCartAction.tryParse({'type': 'DROP'}), isNull);
    });

    test('keeps the reply and shows the error when adding fails', () async {
      final completer = Completer<ChatbotReply>()..complete(cartReply());
      final controller = ChatbotController(
        repository: FakeChatbotRepository(sendCompleter: completer),
        onCartAction: (_) async => 'Hết hàng',
      );

      await controller.send('Thêm vào giỏ');

      expect(controller.state.messages, hasLength(2));
      expect(controller.state.status, ChatbotStatus.error);
      expect(controller.state.errorMessage, 'Hết hàng');
    });

    test('a reply without cartAction adds nothing', () async {
      var called = false;
      final controller = ChatbotController(
        repository: FakeChatbotRepository(),
        onCartAction: (_) async {
          called = true;
          return null;
        },
      );

      await controller.send('Tư vấn giúp tôi');

      expect(called, isFalse);
    });
  });

  test('bold markdown becomes bold spans without asterisks', () {
    final spans = boldMarkdownSpans('Mua **Bó hoa** nhé').cast<TextSpan>();

    expect(spans.map((span) => span.text), ['Mua ', 'Bó hoa', ' nhé']);
    expect(spans[1].style?.fontWeight, FontWeight.w700);
  });

  testWidgets('history lists conversations and opens the selected one', (
    tester,
  ) async {
    final controller = ChatbotController(
      repository: FakeChatbotRepository(
        history: ChatbotHistory(
          conversationId: 'conversation-history',
          title: 'Hoa sinh nhật',
          messages: <ChatMessage>[
            ChatMessage(
              id: 'history-1',
              role: ChatMessageRole.user,
              content: 'Tư vấn giúp tôi',
              createdAt: DateTime.utc(2026, 10, 15),
            ),
          ],
          page: 1,
          totalPages: 1,
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ChatbotPanel(controller: controller, onClose: () {}),
      ),
    );

    await tester.tap(find.byKey(const Key('chatbot-history-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('chatbot-conversation-conversation-history')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tư vấn giúp tôi'), findsOneWidget);
    expect(controller.state.conversationId, 'conversation-history');
  });

  testWidgets('deletes a conversation only after confirming', (tester) async {
    final repository = FakeChatbotRepository();
    final controller = ChatbotController(repository: repository);
    await tester.pumpWidget(
      MaterialApp(
        home: ChatbotPanel(controller: controller, onClose: () {}),
      ),
    );
    await tester.tap(find.byKey(const Key('chatbot-history-button')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('chatbot-conversation-delete-conversation-history')),
    );
    await tester.pumpAndSettle();
    expect(repository.deletedConversationId, isNull);

    await tester.tap(
      find.byKey(
        const Key('chatbot-conversation-confirm-delete-conversation-history'),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.deletedConversationId, 'conversation-history');
  });

  test('deleting the open conversation clears it', () async {
    final repository = FakeChatbotRepository();
    final controller = ChatbotController(repository: repository);
    await controller.send('Xin chào');

    expect(await controller.deleteConversation('other'), isTrue);
    expect(controller.state.messages, hasLength(2));

    expect(await controller.deleteConversation('conversation-1'), isTrue);
    expect(controller.state.messages, isEmpty);
    expect(controller.state.conversationId, isNull);
  });

  test('a failed delete keeps the conversation and shows the error', () async {
    final controller = ChatbotController(
      repository: _FailingDeleteRepository(),
    );
    await controller.send('Xin chào');

    expect(await controller.deleteConversation('conversation-1'), isFalse);
    expect(controller.state.messages, hasLength(2));
    expect(controller.state.errorMessage, isNotNull);
  });

  testWidgets('shows typing dots only while waiting for a reply', (
    tester,
  ) async {
    final completer = Completer<ChatbotReply>();
    final controller = ChatbotController(
      repository: FakeChatbotRepository(sendCompleter: completer),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ChatbotPanel(controller: controller, onClose: () {}),
      ),
    );

    final send = controller.send('Xin chào');
    await tester.pump();
    expect(find.byKey(const Key('chatbot-typing-indicator')), findsOneWidget);

    completer.complete(_reply);
    await send;
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chatbot-typing-indicator')), findsNothing);
  });

  test('resume replaces messages with persisted history', () async {
    final repository = FakeChatbotRepository(
      history: ChatbotHistory(
        conversationId: 'conversation-history',
        title: 'Hoa sinh nhật',
        messages: <ChatMessage>[
          ChatMessage(
            id: 'history-1',
            role: ChatMessageRole.user,
            content: 'Tư vấn giúp tôi',
            createdAt: DateTime.utc(2026, 10, 15),
          ),
        ],
        page: 1,
        totalPages: 1,
      ),
    );
    final controller = ChatbotController(repository: repository);

    await controller.resume('conversation-history');

    expect(controller.state.conversationId, 'conversation-history');
    expect(controller.state.messages.single.id, 'history-1');
    expect(controller.state.status, ChatbotStatus.ready);
  });

  test('delete current conversation resets local state', () async {
    final repository = FakeChatbotRepository();
    final controller = ChatbotController(repository: repository);
    await controller.send('Xin chào');

    await controller.deleteCurrentConversation();

    expect(repository.deletedConversationId, 'conversation-1');
    expect(controller.state.conversationId, isNull);
    expect(controller.state.messages, isEmpty);
    expect(controller.state.status, ChatbotStatus.ready);
  });
}

final _reply = ChatbotReply(
  conversationId: 'conversation-1',
  messageId: 'assistant-1',
  reply: 'Mình có thể giúp bạn chọn hoa.',
  products: const <SuggestedProduct>[],
  createdAt: DateTime.utc(2026, 10, 15),
);

class _FailingDeleteRepository extends FakeChatbotRepository {
  @override
  Future<void> deleteConversation(String conversationId) async {
    throw const ChatbotFailure.network();
  }
}

class FakeChatbotRepository implements ChatbotRepository {
  FakeChatbotRepository({this.sendCompleter, this.sendFailure, this.history});

  final Completer<ChatbotReply>? sendCompleter;
  final ChatbotFailure? sendFailure;
  final ChatbotHistory? history;
  int sendCalls = 0;
  String? lastMessage;
  ChatbotRequestContext? lastContext;
  String? deletedConversationId;

  @override
  Future<ChatbotReply> sendMessage({
    String? conversationId,
    required String message,
    ChatbotRequestContext? context,
  }) async {
    sendCalls++;
    lastMessage = message;
    lastContext = context;
    if (sendFailure != null) throw sendFailure!;
    if (sendCompleter != null) return sendCompleter!.future;
    return _reply;
  }

  @override
  Future<ChatbotHistory> getHistory(
    String conversationId, {
    int page = 1,
  }) async {
    return history ??
        ChatbotHistory(
          conversationId: conversationId,
          title: null,
          messages: const <ChatMessage>[],
          page: page,
          totalPages: 1,
        );
  }

  @override
  Future<List<ChatbotConversationSummary>> listConversations() async =>
      <ChatbotConversationSummary>[
        ChatbotConversationSummary(
          id: 'conversation-history',
          title: 'Hoa sinh nhật',
          updatedAt: DateTime.utc(2026, 10, 15),
        ),
      ];

  @override
  Future<void> deleteConversation(String conversationId) async {
    deletedConversationId = conversationId;
  }
}
