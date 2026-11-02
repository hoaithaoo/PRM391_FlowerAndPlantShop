import 'package:flutter/material.dart';
import 'package:plant_flower_api_client/plant_flower_api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'features/cart/data/api_cart_repository.dart';
import 'features/cart/data/cart_failure.dart';
import 'features/cart/data/cart_repository.dart';
import 'features/cart/models/cart_item.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/supabase_auth_repository.dart';
import 'features/chatbot/data/mock_chatbot_repository.dart';
import 'features/chatbot/data/api_client_chatbot_transport.dart';
import 'features/chatbot/data/chatbot_remote_data_source.dart';
import 'features/chatbot/data/chatbot_repository.dart';
import 'features/chatbot/data/chatbot_repository_impl.dart';
import 'features/products/data/api_product_repository.dart';
import 'features/products/data/mock_product_repository.dart';
import 'features/products/data/product_repository.dart';
import 'features/checkout/data/checkout_api.dart';
import 'features/checkout/data/checkout_remote_data_source.dart';
import 'features/checkout/data/checkout_repository.dart';
import 'features/checkout/data/checkout_repository_impl.dart';
import 'features/notifications/data/api_client_notification_transport.dart';
import 'features/notifications/data/notification_remote_data_source.dart';
import 'features/notifications/data/notification_repository.dart';
import 'features/notifications/data/notification_repository_impl.dart';

// Truyền qua --dart-define, ví dụ API_BASE_URL=http://10.0.2.2:4000
const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ProductRepository productRepository;
  final CartRepository cartRepository;
  final ChatbotRepository chatbotRepository;
  AuthRepository? authRepository;
  CheckoutRepository? checkoutRepository;
  CheckoutApi? checkoutApi;
  NotificationRepository? notificationRepository;
  if (_apiBaseUrl.isNotEmpty &&
      _supabaseUrl.isNotEmpty &&
      _supabasePublishableKey.isNotEmpty) {
    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabasePublishableKey,
    );
    final apiClient = ApiClient(baseUrl: _apiBaseUrl);
    Future<String?> accessTokenProvider() async =>
        Supabase.instance.client.auth.currentSession?.accessToken;
    authRepository = SupabaseAuthRepository(Supabase.instance.client.auth);
    productRepository = ApiProductRepository(ProductsApi(apiClient));
    cartRepository = ApiCartRepository(
      apiClient,
      accessTokenProvider: accessTokenProvider,
    );
    checkoutApi = CheckoutApi(
      apiClient,
      accessTokenProvider: accessTokenProvider,
    );
    checkoutRepository = CheckoutRepositoryImpl(
      CheckoutRemoteDataSource(
        transport: checkoutApi,
        accessTokenProvider: accessTokenProvider,
      ),
    );
    chatbotRepository = ChatbotRepositoryImpl(
      ChatbotRemoteDataSource(
        transport: ApiClientChatbotTransport(apiClient),
        accessTokenProvider: accessTokenProvider,
      ),
    );
    notificationRepository = NotificationRepositoryImpl(
      NotificationRemoteDataSource(
        transport: ApiClientNotificationTransport(apiClient),
        accessTokenProvider: accessTokenProvider,
      ),
    );
  } else {
    // Chưa cấu hình backend: chạy demo với dữ liệu giả
    debugPrint('API_BASE_URL chưa được cấu hình, dùng MockProductRepository.');
    productRepository = MockProductRepository();
    cartRepository = const _UnavailableCartRepository();
    chatbotRepository = MockChatbotRepository();
  }

  runApp(
    PlantFlowerApp(
      productRepository: productRepository,
      cartRepository: cartRepository,
      chatbotRepository: chatbotRepository,
      authRepository: authRepository,
      checkoutRepository: checkoutRepository,
      checkoutApi: checkoutApi,
      notificationRepository: notificationRepository,
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
