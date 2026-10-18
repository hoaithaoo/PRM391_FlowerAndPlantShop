import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/chatbot/data/chatbot_failure.dart';
import 'package:plant_flower_mobile/features/chatbot/data/chatbot_repository.dart';
import 'package:plant_flower_mobile/features/chatbot/models/chatbot_models.dart';
import 'package:plant_flower_mobile/features/chatbot/state/chatbot_controller.dart';
import 'package:plant_flower_mobile/features/chatbot/state/chatbot_state.dart';

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
  Future<void> deleteConversation(String conversationId) async {
    deletedConversationId = conversationId;
  }
}
