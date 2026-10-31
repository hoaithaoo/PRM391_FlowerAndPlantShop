enum ChatMessageRole { user, assistant }

enum ChatbotActionType { openIncidentReport }

class ChatbotRequestContext {
  const ChatbotRequestContext({
    this.productId,
    this.orderId,
    this.paymentId,
    this.source,
  });

  final String? productId;
  final String? orderId;
  final String? paymentId;
  final String? source;

  Map<String, dynamic> toRequestFields() {
    final context = <String, dynamic>{
      if (_hasValue(orderId)) 'orderId': orderId,
      if (_hasValue(paymentId)) 'paymentId': paymentId,
      if (_hasValue(source)) 'source': source,
    };

    return <String, dynamic>{
      if (_hasValue(productId)) 'productId': productId,
      if (context.isNotEmpty) 'context': context,
    };
  }

  static bool _hasValue(String? value) =>
      value != null && value.trim().isNotEmpty;
}

class SuggestedProduct {
  const SuggestedProduct({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String price;
  final String? imageUrl;

  static SuggestedProduct? tryParse(Object? value) {
    if (value is! Map) return null;
    final json = Map<String, dynamic>.from(value);
    final id = json['id'];
    final name = json['name'];
    final rawPrice = json['price'];
    if (id is! String || id.isEmpty || name is! String || name.isEmpty) {
      return null;
    }
    final price = switch (rawPrice) {
      final String value when value.isNotEmpty => value,
      final num value => value.toStringAsFixed(0),
      _ => null,
    };
    if (price == null) return null;
    final rawImageUrl = json['imageUrl'];
    return SuggestedProduct(
      id: id,
      name: name,
      price: price,
      imageUrl: rawImageUrl is String && rawImageUrl.isNotEmpty
          ? rawImageUrl
          : null,
    );
  }
}

class IncidentReportDraft {
  const IncidentReportDraft({
    required this.category,
    required this.title,
    required this.description,
    required this.conversationId,
    this.orderId,
    this.paymentId,
  });

  final String category;
  final String title;
  final String description;
  final String conversationId;
  final String? orderId;
  final String? paymentId;

  static IncidentReportDraft? tryParse(Object? value) {
    if (value is! Map) return null;
    final json = Map<String, dynamic>.from(value);
    final category = json['category'];
    final title = json['title'];
    final description = json['description'];
    final conversationId = json['conversationId'];
    if (category is! String ||
        category.isEmpty ||
        title is! String ||
        title.isEmpty ||
        description is! String ||
        description.isEmpty ||
        conversationId is! String ||
        conversationId.isEmpty) {
      return null;
    }

    return IncidentReportDraft(
      category: category,
      title: title,
      description: description,
      conversationId: conversationId,
      orderId: _optionalString(json['orderId']),
      paymentId: _optionalString(json['paymentId']),
    );
  }
}

class ChatbotAction {
  const ChatbotAction({required this.type, required this.draft});

  final ChatbotActionType type;
  final IncidentReportDraft? draft;

  static ChatbotAction? tryParse(Object? value) {
    if (value is! Map) return null;
    final json = Map<String, dynamic>.from(value);
    if (json['type'] != 'OPEN_INCIDENT_REPORT') return null;
    final draft = IncidentReportDraft.tryParse(json['draft']);
    if (draft == null) return null;
    return ChatbotAction(
      type: ChatbotActionType.openIncidentReport,
      draft: draft,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.products = const <SuggestedProduct>[],
    this.action,
  });

  final String id;
  final ChatMessageRole role;
  final String content;
  final DateTime? createdAt;
  final List<SuggestedProduct> products;
  final ChatbotAction? action;

  factory ChatMessage.pendingUser(String content, {DateTime? createdAt}) {
    final timestamp = createdAt ?? DateTime.now();
    return ChatMessage(
      id: 'local-${timestamp.microsecondsSinceEpoch}',
      role: ChatMessageRole.user,
      content: content,
      createdAt: timestamp,
    );
  }

  static ChatMessage? tryParse(Object? value) {
    if (value is! Map) return null;
    final json = Map<String, dynamic>.from(value);
    final id = json['id'];
    final content = json['content'];
    final role = switch (json['role']) {
      'USER' => ChatMessageRole.user,
      'ASSISTANT' => ChatMessageRole.assistant,
      _ => null,
    };
    if (id is! String || id.isEmpty || content is! String || role == null) {
      return null;
    }
    return ChatMessage(
      id: id,
      role: role,
      content: content,
      createdAt: _tryDate(json['createdAt']),
      products: _parseProducts(json['suggestedProducts']),
      action: ChatbotAction.tryParse(json['action']),
    );
  }
}

class ChatbotReply {
  const ChatbotReply({
    required this.conversationId,
    required this.messageId,
    required this.reply,
    required this.products,
    required this.createdAt,
    this.action,
  });

  final String conversationId;
  final String messageId;
  final String reply;
  final List<SuggestedProduct> products;
  final ChatbotAction? action;
  final DateTime? createdAt;

  factory ChatbotReply.fromJson(Map<String, dynamic> json) {
    return ChatbotReply(
      conversationId: _requiredString(json, 'conversationId'),
      messageId: _requiredString(json, 'messageId'),
      reply: _requiredString(json, 'reply'),
      products: _parseProducts(json['suggestedProducts']),
      action: ChatbotAction.tryParse(json['action']),
      createdAt: _tryDate(json['createdAt']),
    );
  }

  ChatMessage toMessage() => ChatMessage(
    id: messageId,
    role: ChatMessageRole.assistant,
    content: reply,
    createdAt: createdAt,
    products: products,
    action: action,
  );
}

class ChatbotHistory {
  const ChatbotHistory({
    required this.conversationId,
    required this.title,
    required this.messages,
    required this.page,
    required this.totalPages,
  });

  final String conversationId;
  final String? title;
  final List<ChatMessage> messages;
  final int page;
  final int totalPages;

  factory ChatbotHistory.fromJson(Map<String, dynamic> json) {
    final conversation = json['conversation'];
    if (conversation is! Map) {
      throw const FormatException('Missing chatbot conversation.');
    }
    final conversationJson = Map<String, dynamic>.from(conversation);
    final rawItems = json['items'];
    final messages = rawItems is List
        ? rawItems.map(ChatMessage.tryParse).whereType<ChatMessage>().toList()
        : <ChatMessage>[];
    return ChatbotHistory(
      conversationId: _requiredString(conversationJson, 'id'),
      title: _optionalString(conversationJson['title']),
      messages: List<ChatMessage>.unmodifiable(messages),
      page: _positiveInt(json['page'], fallback: 1),
      totalPages: _positiveInt(json['totalPages'], fallback: 1),
    );
  }
}

List<SuggestedProduct> _parseProducts(Object? value) {
  if (value is! List) return const <SuggestedProduct>[];
  return List<SuggestedProduct>.unmodifiable(
    value.map(SuggestedProduct.tryParse).whereType<SuggestedProduct>(),
  );
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Missing or invalid $key.');
}

String? _optionalString(Object? value) {
  return value is String && value.isNotEmpty ? value : null;
}

DateTime? _tryDate(Object? value) {
  return value is String ? DateTime.tryParse(value) : null;
}

int _positiveInt(Object? value, {required int fallback}) {
  return value is num && value >= 1 ? value.toInt() : fallback;
}
