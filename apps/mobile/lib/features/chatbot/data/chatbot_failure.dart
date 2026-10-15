enum ChatbotErrorCode {
  authTokenMissing,
  authTokenInvalid,
  productNotFound,
  validationError,
  rateLimited,
  providerError,
  providerTimeout,
  conversationNotFound,
  malformedResponse,
  network,
  unknown,
}

class ChatbotFailure implements Exception {
  const ChatbotFailure({required this.code, this.statusCode, this.message});

  const ChatbotFailure.network()
    : code = ChatbotErrorCode.network,
      statusCode = null,
      message = null;

  final ChatbotErrorCode code;
  final int? statusCode;
  final String? message;

  @override
  String toString() => 'ChatbotFailure($code, $statusCode, $message)';
}

ChatbotErrorCode chatbotErrorCodeFromApi(Object? value) {
  return switch (value) {
    'AUTH_TOKEN_MISSING' => ChatbotErrorCode.authTokenMissing,
    'AUTH_TOKEN_INVALID' => ChatbotErrorCode.authTokenInvalid,
    'PRODUCT_NOT_FOUND' => ChatbotErrorCode.productNotFound,
    'VALIDATION_ERROR' => ChatbotErrorCode.validationError,
    'CHATBOT_RATE_LIMITED' => ChatbotErrorCode.rateLimited,
    'CHATBOT_PROVIDER_ERROR' => ChatbotErrorCode.providerError,
    'CHATBOT_PROVIDER_TIMEOUT' => ChatbotErrorCode.providerTimeout,
    'CHATBOT_CONVERSATION_NOT_FOUND' => ChatbotErrorCode.conversationNotFound,
    _ => ChatbotErrorCode.unknown,
  };
}
