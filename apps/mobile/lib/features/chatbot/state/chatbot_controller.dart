import 'package:flutter/foundation.dart';

import '../data/chatbot_failure.dart';
import '../data/chatbot_repository.dart';
import '../models/chatbot_models.dart';
import 'chatbot_state.dart';

typedef ChatbotContextProvider = ChatbotRequestContext? Function();

/// Thực hiện thao tác giỏ hàng của AI. Trả về thông báo lỗi, `null` là thành công.
typedef ChatbotCartHandler = Future<String?> Function(ChatbotCartAction action);

/// Thực hiện thao tác yêu thích của AI. Trả về thông báo lỗi, `null` là thành công.
typedef ChatbotFavoriteHandler =
    Future<String?> Function(ChatbotFavoriteAction action);

/// Trả về id các sản phẩm đang yêu thích để gửi kèm tin nhắn.
typedef ChatbotFavoriteIdsProvider = List<String> Function();

const _favoriteUnsupported =
    'Ứng dụng chưa hỗ trợ cập nhật yêu thích từ chatbot.';

class ChatbotController extends ChangeNotifier {
  ChatbotController({
    required ChatbotRepository repository,
    ChatbotContextProvider? contextProvider,
    ChatbotCartHandler? onCartAction,
    ChatbotFavoriteHandler? onFavoriteAction,
    ChatbotFavoriteIdsProvider? favoriteIdsProvider,
  }) : _repository = repository,
       _contextProvider = contextProvider,
       _onCartAction = onCartAction,
       _onFavoriteAction = onFavoriteAction,
       _favoriteIdsProvider = favoriteIdsProvider;

  final ChatbotRepository _repository;
  final ChatbotContextProvider? _contextProvider;
  final ChatbotCartHandler? _onCartAction;
  final ChatbotFavoriteHandler? _onFavoriteAction;
  final ChatbotFavoriteIdsProvider? _favoriteIdsProvider;
  ChatbotState _state = const ChatbotState();
  var _isDisposed = false;

  ChatbotState get state => _state;

  Future<void> send(String rawMessage) async {
    final message = rawMessage.trim();
    if (message.isEmpty || _state.isBusy) return;

    final userMessage = ChatMessage.pendingUser(message);
    _setState(
      _state.copyWith(
        messages: <ChatMessage>[..._state.messages, userMessage],
        status: ChatbotStatus.sending,
        errorMessage: null,
      ),
    );

    try {
      final reply = await _repository.sendMessage(
        conversationId: _state.conversationId,
        message: message,
        context: _buildContext(),
      );
      // Chạy lần lượt theo thứ tự AI trả về, dừng ở thao tác lỗi đầu tiên.
      String? cartError;
      for (final action in reply.cartActions) {
        cartError = await _onCartAction?.call(action);
        if (cartError != null) break;
      }
      // Sau giỏ hàng mới tới yêu thích; chưa gắn handler thì báo lỗi thay vì im lặng.
      for (final action in reply.favoriteActions) {
        if (cartError != null) break;
        cartError = _onFavoriteAction == null
            ? _favoriteUnsupported
            : await _onFavoriteAction(action);
      }
      _setState(
        _state.copyWith(
          conversationId: reply.conversationId,
          messages: <ChatMessage>[..._state.messages, reply.toMessage()],
          status: cartError == null ? ChatbotStatus.ready : ChatbotStatus.error,
          errorMessage: cartError,
        ),
      );
    } on ChatbotFailure catch (failure) {
      _setFailure(failure);
    } catch (_) {
      _setFailure(const ChatbotFailure.network());
    }
  }

  /// Gộp ngữ cảnh màn hình hiện tại với danh sách yêu thích (nếu có).
  ChatbotRequestContext? _buildContext() {
    final context = _contextProvider?.call();
    final ids = _favoriteIdsProvider?.call() ?? const <String>[];
    if (ids.isEmpty) return context;
    return (context ?? const ChatbotRequestContext()).withFavorites(ids);
  }

  Future<List<ChatbotConversationSummary>> listConversations() =>
      _repository.listConversations();

  Future<void> resume(String conversationId) async {
    if (_state.isBusy || conversationId.trim().isEmpty) return;
    _setState(
      _state.copyWith(status: ChatbotStatus.loadingHistory, errorMessage: null),
    );
    try {
      final history = await _repository.getHistory(conversationId);
      _setState(
        ChatbotState(
          conversationId: history.conversationId,
          messages: history.messages,
        ),
      );
    } on ChatbotFailure catch (failure) {
      _setFailure(failure);
    } catch (_) {
      _setFailure(const ChatbotFailure.network());
    }
  }

  void startNewConversation() {
    if (_state.isBusy) return;
    _setState(const ChatbotState());
  }

  /// Xóa một phiên trong lịch sử; nếu đang mở phiên đó thì về màn trống.
  Future<bool> deleteConversation(String conversationId) async {
    if (_state.isBusy) return false;
    try {
      await _repository.deleteConversation(conversationId);
    } on ChatbotFailure catch (failure) {
      _setFailure(failure);
      return false;
    } catch (_) {
      _setFailure(const ChatbotFailure.network());
      return false;
    }
    if (_state.conversationId == conversationId) {
      _setState(const ChatbotState());
    }
    return true;
  }

  Future<void> deleteCurrentConversation() async {
    if (_state.isBusy) return;
    final conversationId = _state.conversationId;
    if (conversationId == null) {
      startNewConversation();
      return;
    }
    _setState(
      _state.copyWith(status: ChatbotStatus.deleting, errorMessage: null),
    );
    try {
      await _repository.deleteConversation(conversationId);
      _setState(const ChatbotState());
    } on ChatbotFailure catch (failure) {
      _setFailure(failure);
    } catch (_) {
      _setFailure(const ChatbotFailure.network());
    }
  }

  void dismissError() {
    if (_state.status != ChatbotStatus.error &&
        _state.status != ChatbotStatus.authenticationRequired) {
      return;
    }
    _setState(_state.copyWith(status: ChatbotStatus.ready, errorMessage: null));
  }

  void _setFailure(ChatbotFailure failure) {
    final requiresAuthentication =
        failure.code == ChatbotErrorCode.authTokenMissing ||
        failure.code == ChatbotErrorCode.authTokenInvalid;
    _setState(
      _state.copyWith(
        status: requiresAuthentication
            ? ChatbotStatus.authenticationRequired
            : ChatbotStatus.error,
        errorMessage: _messageForFailure(failure),
      ),
    );
  }

  String _messageForFailure(ChatbotFailure failure) {
    return switch (failure.code) {
      ChatbotErrorCode.authTokenMissing || ChatbotErrorCode.authTokenInvalid =>
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      ChatbotErrorCode.rateLimited =>
        'Bạn đang gửi tin nhắn quá nhanh. Vui lòng chờ một chút.',
      ChatbotErrorCode.providerTimeout =>
        'Trợ lý chưa kịp phản hồi. Vui lòng thử lại.',
      ChatbotErrorCode.providerError =>
        'Trợ lý đang tạm gián đoạn. Vui lòng thử lại sau.',
      ChatbotErrorCode.productNotFound =>
        'Sản phẩm bạn đang xem không còn khả dụng.',
      ChatbotErrorCode.validationError =>
        'Tin nhắn chưa hợp lệ. Vui lòng kiểm tra lại.',
      ChatbotErrorCode.conversationNotFound =>
        'Không tìm thấy phiên tư vấn này.',
      _ => 'Không thể kết nối với trợ lý. Vui lòng thử lại.',
    };
  }

  void _setState(ChatbotState nextState) {
    if (_isDisposed) return;
    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
