import 'package:flutter/material.dart';
import 'package:plant_flower_api_client/plant_flower_api_client.dart';

import 'app/app.dart';
import 'features/cart/data/api_cart_repository.dart';
import 'features/cart/data/cart_failure.dart';
import 'features/cart/data/cart_repository.dart';
import 'features/cart/models/cart_item.dart';
import 'features/chatbot/data/mock_chatbot_repository.dart';
import 'features/chatbot/data/api_client_chatbot_transport.dart';
import 'features/chatbot/data/chatbot_remote_data_source.dart';
import 'features/chatbot/data/chatbot_repository.dart';
import 'features/chatbot/data/chatbot_repository_impl.dart';
import 'features/products/data/api_product_repository.dart';
import 'features/products/data/mock_product_repository.dart';
import 'features/products/data/product_repository.dart';

// Truyền qua --dart-define, ví dụ API_BASE_URL=http://10.0.2.2:4000
const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final ProductRepository productRepository;
  final CartRepository cartRepository;
  final ChatbotRepository chatbotRepository;
  if (_apiBaseUrl.isNotEmpty) {
    final apiClient = ApiClient(baseUrl: _apiBaseUrl);
    productRepository = ApiProductRepository(ProductsApi(apiClient));
    cartRepository = ApiCartRepository(
      apiClient,
      // Never embed a shared bearer token in the app binary. Wire this to
      // Supabase currentSession.accessToken when mobile auth is available.
      accessTokenProvider: () async => null,
    );
    chatbotRepository = ChatbotRepositoryImpl(
      ChatbotRemoteDataSource(
        transport: ApiClientChatbotTransport(apiClient),
        // Mobile auth is not present on this branch yet.
        accessTokenProvider: () async => null,
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
