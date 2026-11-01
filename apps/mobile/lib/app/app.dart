import 'package:flutter/material.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

import '../features/auth/auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


import '../features/cart/state/cart_controller.dart';
import '../features/cart/state/cart_scope.dart';
import '../features/cart/data/cart_repository.dart';
import '../features/chatbot/data/chatbot_repository.dart';
import '../features/chatbot/widgets/chatbot_overlay_host.dart';
import '../features/products/data/product_repository.dart';
import '../features/products/data/product_scope.dart';
import '../features/products/product_routes.dart';
import 'main_shell.dart';

class PlantFlowerApp extends StatefulWidget {
  const PlantFlowerApp({
    super.key,
    this.authRepository,
    required this.productRepository,
    required this.cartRepository,
    required this.chatbotRepository,
  });

  final AuthRepository? authRepository;
  final ProductRepository productRepository;
  final CartRepository cartRepository;
  final ChatbotRepository chatbotRepository;

  @override
  State<PlantFlowerApp> createState() => _PlantFlowerAppState();
}

class _PlantFlowerAppState extends State<PlantFlowerApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AuthRepository _authRepository =
      widget.authRepository ?? _defaultAuthRepository();

  static AuthRepository _defaultAuthRepository() {
    try {
      final client = Supabase.instance.client;
      return SupabaseAuthRepository(
        client.auth,
        geocoder: NominatimAddressGeocoder(),
      );
    } catch (_) {
      return MockAuthRepository(initialSignedIn: false);
    }
  }
  late final CartController _cartController = CartController(
    repository: widget.cartRepository,
  )..initialize();

  @override
  void dispose() {
    _cartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      repository: _authRepository,
      child: CartScope(
      controller: _cartController,
      child: ProductScope(
        repository: widget.productRepository,
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Nhà Có Hoa',
          theme: AuthTheme.data(AppTheme.data()),
          home: AuthSessionGate(
            signedInBuilder: (_) => const MainShell(),
          ),
          onGenerateRoute: (settings) {
            return AuthRoutes.onGenerateRoute(settings) ??
                ProductRoutes.onGenerateRoute(settings);
          },
          builder: (context, child) => ChatbotOverlayHost(
            repository: widget.chatbotRepository,
            launcherBottomInset: AppBottomNav.reservedHeight + 8,
            onProductTap: (productId) => _navigatorKey.currentState?.pushNamed(
              ProductRoutes.detail,
              arguments: productId,
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
      ),
    );
  }
}
