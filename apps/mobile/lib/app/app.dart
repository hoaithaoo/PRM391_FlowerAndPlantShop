import 'package:flutter/material.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

import '../features/cart/state/cart_controller.dart';
import '../features/cart/state/cart_scope.dart';
import '../features/cart/data/cart_repository.dart';
import '../features/auth/auth_routes.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/auth_scope.dart';
import '../features/auth/screens/auth_session_gate.dart';
import '../features/chatbot/data/chatbot_repository.dart';
import '../features/chatbot/widgets/chatbot_overlay_host.dart';
import '../features/checkout/data/checkout_api.dart';
import '../features/checkout/data/checkout_repository.dart';
import '../features/checkout/screens/checkout_entry_screen.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/notifications/state/notification_controller.dart';
import '../features/products/data/product_repository.dart';
import '../features/products/data/product_scope.dart';
import '../features/products/product_routes.dart';
import 'main_shell.dart';

class PlantFlowerApp extends StatefulWidget {
  const PlantFlowerApp({
    super.key,
    required this.productRepository,
    required this.cartRepository,
    required this.chatbotRepository,
    this.authRepository,
    this.checkoutRepository,
    this.checkoutApi,
    this.notificationRepository,
  });

  final ProductRepository productRepository;
  final CartRepository cartRepository;
  final ChatbotRepository chatbotRepository;
  final AuthRepository? authRepository;
  final CheckoutRepository? checkoutRepository;
  final CheckoutApi? checkoutApi;
  final NotificationRepository? notificationRepository;

  @override
  State<PlantFlowerApp> createState() => _PlantFlowerAppState();
}

class _PlantFlowerAppState extends State<PlantFlowerApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final CartController _cartController = CartController(
    repository: widget.cartRepository,
  );

  @override
  void initState() {
    super.initState();
    if (widget.authRepository == null) {
      _cartController.initialize();
    }
  }

  @override
  void dispose() {
    _cartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final materialApp = CartScope(
      controller: _cartController,
      child: ProductScope(
        repository: widget.productRepository,
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Nhà Có Hoa',
          theme: AppTheme.data(),
          home: widget.authRepository == null
              ? MainShell(onCheckout: _openCheckout)
              : AuthSessionGate(
                  signedInBuilder: (_) => _SignedInShell(
                    cartController: _cartController,
                    onCheckout: _openCheckout,
                    notificationRepository: widget.notificationRepository,
                    onOpenNotifications: _openNotifications,
                  ),
                ),
          onGenerateRoute: (settings) =>
              AuthRoutes.onGenerateRoute(settings) ??
              ProductRoutes.onGenerateRoute(settings),
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
    );
    final authRepository = widget.authRepository;
    if (authRepository == null) return materialApp;
    return AuthScope(repository: authRepository, child: materialApp);
  }

  void _openCheckout() {
    final repository = widget.checkoutRepository;
    final api = widget.checkoutApi;
    final navigator = _navigatorKey.currentState;
    if (repository == null || api == null || navigator == null) return;
    navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CheckoutEntryScreen(
          cartController: _cartController,
          checkoutRepository: repository,
          api: api,
        ),
      ),
    );
  }

  void _openNotifications(NotificationController controller) {
    _navigatorKey.currentState?.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsScreen(controller: controller),
      ),
    );
  }
}

class _SignedInShell extends StatefulWidget {
  const _SignedInShell({
    required this.cartController,
    required this.onCheckout,
    required this.notificationRepository,
    required this.onOpenNotifications,
  });

  final CartController cartController;
  final VoidCallback onCheckout;
  final NotificationRepository? notificationRepository;
  final ValueChanged<NotificationController> onOpenNotifications;

  @override
  State<_SignedInShell> createState() => _SignedInShellState();
}

class _SignedInShellState extends State<_SignedInShell> {
  NotificationController? _notificationController;

  @override
  void initState() {
    super.initState();
    widget.cartController.initialize();
    final repository = widget.notificationRepository;
    if (repository != null) {
      _notificationController = NotificationController(repository: repository)
        ..loadInitial();
    }
  }

  @override
  void dispose() {
    _notificationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationController = _notificationController;
    return MainShell(
      onCheckout: widget.onCheckout,
      notificationController: notificationController,
      onNotifications: notificationController == null
          ? null
          : () => widget.onOpenNotifications(notificationController),
    );
  }
}
