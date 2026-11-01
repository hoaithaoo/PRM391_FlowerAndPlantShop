import 'package:flutter/material.dart';
import 'package:plant_flower_api_client/plant_flower_api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'features/auth/auth.dart';
import 'features/cart/data/api_cart_repository.dart';
import 'features/cart/data/cart_failure.dart';
import 'features/cart/data/cart_repository.dart';
import 'features/cart/models/cart_item.dart';
import 'features/chatbot/data/mock_chatbot_repository.dart';
import 'features/chatbot/data/api_client_chatbot_transport.dart';
import 'features/chatbot/data/chatbot_remote_data_source.dart';
import 'features/chatbot/data/chatbot_repository.dart';
import 'features/chatbot/data/chatbot_repository_impl.dart';
import 'features/checkout/data/api_client_checkout_transport.dart';
import 'features/checkout/data/checkout_remote_data_source.dart';
import 'features/checkout/data/checkout_repository.dart';
import 'features/checkout/data/checkout_repository_impl.dart';
import 'features/checkout/data/mock_checkout_repository.dart';
import 'features/products/data/api_product_repository.dart';
import 'features/products/data/mock_product_repository.dart';
import 'features/products/data/product_repository.dart';

// Truyền qua --dart-define, ví dụ API_BASE_URL=http://10.0.2.2:4000
const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AuthRepository authRepository;
  Future<String?> Function() accessTokenProvider = () async => null;
  Future<String?> Function()? refreshAccessToken;
  void Function()? onSessionExpired;
  if (_supabaseUrl.isNotEmpty && _supabasePublishableKey.isNotEmpty) {
    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabasePublishableKey,
    );
    final auth = Supabase.instance.client.auth;
    authRepository = SupabaseAuthRepository(
      auth,
      geocoder: NominatimAddressGeocoder(),
    );
    // Lỗi mạng ném ra ngoài để nơi gọi không đăng xuất nhầm.
    Future<String?> refresh() async {
      try {
        return (await auth.refreshSession()).session?.accessToken;
      } on AuthRetryableFetchException {
        rethrow;
      } on AuthException {
        return null;
      }
    }

    // Chỉ xóa phiên trên máy: token đã hỏng, gọi server cũng không được.
    void expire() => auth.signOut(scope: SignOutScope.local);

    refreshAccessToken = refresh;
    onSessionExpired = expire;
    accessTokenProvider = () async {
      final session = auth.currentSession;
      if (session == null || !session.isExpired) return session?.accessToken;
      try {
        final token = await refresh();
        if (token == null) expire();
        return token;
      } on AuthException {
        return null;
      }
    };
  } else {
    // Chưa cấu hình Supabase: chạy demo với dữ liệu giả
    debugPrint('SUPABASE_URL chưa được cấu hình, dùng MockAuthRepository.');
    authRepository = MockAuthRepository();
  }

  final ProductRepository productRepository;
  final CartRepository cartRepository;
  final ChatbotRepository chatbotRepository;
  final CheckoutRepository checkoutRepository;
  if (_apiBaseUrl.isNotEmpty) {
    // Render gói free ngủ khi rảnh: lần gọi đầu có thể mất 30-60 giây.
    final apiClient = ApiClient(
      baseUrl: _apiBaseUrl,
      timeout: const Duration(seconds: 60),
      refreshAccessToken: refreshAccessToken,
      onSessionExpired: onSessionExpired,
    );
    productRepository = ApiProductRepository(ProductsApi(apiClient));
    cartRepository = ApiCartRepository(
      apiClient,
      // Never embed a shared bearer token in the app binary.
      accessTokenProvider: accessTokenProvider,
    );
    chatbotRepository = ChatbotRepositoryImpl(
      ChatbotRemoteDataSource(
        transport: ApiClientChatbotTransport(apiClient),
        accessTokenProvider: accessTokenProvider,
      ),
    );
    checkoutRepository = CheckoutRepositoryImpl(
      CheckoutRemoteDataSource(
        transport: ApiClientCheckoutTransport(apiClient),
        accessTokenProvider: accessTokenProvider,
      ),
    );
  } else {
    // Chưa cấu hình backend: chạy demo với dữ liệu giả
    debugPrint('API_BASE_URL chưa được cấu hình, dùng MockProductRepository.');
    productRepository = MockProductRepository();
    cartRepository = const _UnavailableCartRepository();
    chatbotRepository = MockChatbotRepository();
    checkoutRepository = const MockCheckoutRepository();
  }

  runApp(
    PlantFlowerApp(
      authRepository: authRepository,
      productRepository: productRepository,
      cartRepository: cartRepository,
      chatbotRepository: chatbotRepository,
      checkoutRepository: checkoutRepository,
    ),
  );
}

class _UnavailableCartRepository implements CartRepository {
  const _UnavailableCartRepository();

  static const _failure = CartFailure(
    code: CartErrorCode.network,
    message: 'API_BASE_URL chưa được cấu hình.',
  );

  @override
  Future<CartSnapshot> load() => Future.error(_failure);

  @override
  Future<CartSnapshot> add({
    required String productId,
    required int quantity,
  }) => Future.error(_failure);

  @override
  Future<CartSnapshot> update({
    required String itemId,
    required int quantity,
  }) => Future.error(_failure);

  @override
  Future<CartSnapshot> remove({required String itemId}) =>
      Future.error(_failure);

  @override
  Future<CartSnapshot> clear() => Future.error(_failure);
}
