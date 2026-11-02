import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:plant_flower_api_client/plant_flower_api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'features/auth/auth.dart';
import 'features/cart/data/api_cart_repository.dart';
import 'features/cart/data/cart_repository.dart';
import 'features/chatbot/data/api_client_chatbot_transport.dart';
import 'features/chatbot/data/chatbot_remote_data_source.dart';
import 'features/chatbot/data/chatbot_repository.dart';
import 'features/chatbot/data/chatbot_repository_impl.dart';
import 'features/products/data/api_product_repository.dart';
import 'features/products/data/product_repository.dart';

// Biến môi trường truyền qua --dart-define hoặc --dart-define-from-file=.env
const _envApiBaseUrl = String.fromEnvironment('API_BASE_URL');
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabasePublishableKey =
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

String _resolveApiBaseUrl() {
  if (_envApiBaseUrl.isNotEmpty) return _envApiBaseUrl;
  if (!kIsWeb && Platform.isAndroid) {
    return 'http://10.0.2.2:4000';
  }
  return 'http://localhost:4000';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_supabaseUrl.isEmpty || _supabasePublishableKey.isEmpty) {
    throw StateError('Thiếu thông tin cấu hình khởi chạy ứng dụng.');
  }

  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabasePublishableKey,
  );

  final authRepository = SupabaseAuthRepository(
    Supabase.instance.client.auth,
    geocoder: NominatimAddressGeocoder(),
  );

  final apiBaseUrl = _resolveApiBaseUrl();
  final apiClient = ApiClient(baseUrl: apiBaseUrl);
  final ProductRepository productRepository =
      ApiProductRepository(ProductsApi(apiClient));
  final CartRepository cartRepository = ApiCartRepository(
    apiClient,
    accessTokenProvider: () async => authRepository.accessToken,
  );
  final ChatbotRepository chatbotRepository = ChatbotRepositoryImpl(
    ChatbotRemoteDataSource(
      transport: ApiClientChatbotTransport(apiClient),
      accessTokenProvider: () async => authRepository.accessToken,
    ),
  );

  runApp(
    PlantFlowerApp(
      authRepository: authRepository,
      productRepository: productRepository,
      cartRepository: cartRepository,
      chatbotRepository: chatbotRepository,
    ),
  );
}
