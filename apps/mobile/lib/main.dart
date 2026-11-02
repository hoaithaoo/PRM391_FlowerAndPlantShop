import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:plant_flower_api_client/plant_flower_api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'features/auth/auth.dart';
import 'features/cart/data/api_cart_repository.dart';
import 'features/chatbot/data/api_client_chatbot_transport.dart';
import 'features/chatbot/data/chatbot_remote_data_source.dart';
import 'features/chatbot/data/chatbot_repository_impl.dart';
import 'features/checkout/data/api_client_checkout_transport.dart';
import 'features/checkout/data/checkout_remote_data_source.dart';
import 'features/checkout/data/checkout_repository_impl.dart';
import 'features/products/data/api_product_repository.dart';
import 'features/profile/data/profile_repository.dart';

const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_apiBaseUrl.isEmpty ||
      _supabaseUrl.isEmpty ||
      _supabasePublishableKey.isEmpty) {
    throw StateError('Thiếu thông tin cấu hình khởi chạy ứng dụng.');
  }

  // Khởi tạo Supabase
  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabasePublishableKey,
  );

  final auth = Supabase.instance.client.auth;
  final authRepository = SupabaseAuthRepository(
    auth,
    geocoder: NominatimAddressGeocoder(),
  );

  // Tự làm mới access token khi hết hạn
  Future<String?> refresh() async {
    try {
      return (await auth.refreshSession()).session?.accessToken;
    } on AuthRetryableFetchException {
      rethrow;
    } on AuthException {
      return null;
    }
  }

  void expire() => auth.signOut(scope: SignOutScope.local);

  Future<String?> accessTokenProvider() async {
    final session = auth.currentSession;
    if (session == null || !session.isExpired) return session?.accessToken;
    try {
      final token = await refresh();
      if (token == null) expire();
      return token;
    } on AuthException {
      return null;
    }
  }

  // Uploader ảnh đại diện lên Supabase Storage
  Future<String> avatarUploader(Uint8List bytes, String contentType) async {
    final path = '${auth.currentUser!.id}/avatar';
    final bucket = Supabase.instance.client.storage.from('avatars');
    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(upsert: true, contentType: contentType),
    );
    final version = DateTime.now().millisecondsSinceEpoch;
    return '${bucket.getPublicUrl(path)}?v=$version';
  }

  // Kết nối tới server Render duy nhất (timeout 60s cho gói free khi idle)
  final apiClient = ApiClient(
    baseUrl: _apiBaseUrl,
    timeout: const Duration(seconds: 60),
    refreshAccessToken: refresh,
    onSessionExpired: expire,
  );

  // 100% Repository kết nối Backend thật
  final productRepository = ApiProductRepository(ProductsApi(apiClient));
  final cartRepository = ApiCartRepository(
    apiClient,
    accessTokenProvider: accessTokenProvider,
  );
  final chatbotRepository = ChatbotRepositoryImpl(
    ChatbotRemoteDataSource(
      transport: ApiClientChatbotTransport(apiClient),
      accessTokenProvider: accessTokenProvider,
    ),
  );
  final checkoutRepository = CheckoutRepositoryImpl(
    CheckoutRemoteDataSource(
      transport: ApiClientCheckoutTransport(apiClient),
      accessTokenProvider: accessTokenProvider,
    ),
  );
  final profileRepository = ApiProfileRepository(
    apiClient,
    accessTokenProvider: accessTokenProvider,
    avatarUploader: avatarUploader,
  );

  runApp(
    PlantFlowerApp(
      authRepository: authRepository,
      productRepository: productRepository,
      cartRepository: cartRepository,
      chatbotRepository: chatbotRepository,
      checkoutRepository: checkoutRepository,
      profileRepository: profileRepository,
    ),
  );
}