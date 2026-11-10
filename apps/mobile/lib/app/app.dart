import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

import '../features/auth/auth.dart';
import '../features/cart/data/cart_repository.dart';
import '../features/cart/state/cart_controller.dart';
import '../features/cart/state/cart_scope.dart';
import '../features/chatbot/data/chatbot_repository.dart';
import '../features/chatbot/models/chatbot_models.dart';
import '../features/chatbot/widgets/chatbot_overlay_host.dart';
import '../features/checkout/data/checkout_repository.dart';
import '../features/checkout/models/checkout_request.dart';
import '../features/checkout/models/checkout_summary.dart';
import '../features/checkout/screens/checkout_screen.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/notifications/state/notification_controller.dart';
import '../features/map/screens/store_map_screen.dart';
import '../features/products/data/buy_now_scope.dart';
import '../features/products/data/product_repository.dart';
import '../features/products/data/product_scope.dart';
import '../features/products/product_routes.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/screens/account_screen.dart';
import '../features/profile/screens/incident_report_screen.dart';
import '../features/profile/screens/order_detail_screen.dart';
import 'main_shell.dart';

const _chatbotCartItemMissing = 'Không tìm thấy sản phẩm này trong giỏ hàng.';

class PlantFlowerApp extends StatefulWidget {
  const PlantFlowerApp({
    super.key,
    required this.authRepository,
    required this.productRepository,
    required this.cartRepository,
    required this.chatbotRepository,
    required this.checkoutRepository,
    required this.notificationRepository,
    this.profileRepository,
  });

  final AuthRepository authRepository;
  final ProductRepository productRepository;
  final CartRepository cartRepository;
  final ChatbotRepository chatbotRepository;
  final CheckoutRepository checkoutRepository;
  final NotificationRepository notificationRepository;
  final ProfileRepository? profileRepository;

  @override
  State<PlantFlowerApp> createState() => _PlantFlowerAppState();
}

class _PlantFlowerAppState extends State<PlantFlowerApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final CartController _cartController = CartController(
    repository: widget.cartRepository,
  );
  late final StreamSubscription<bool> _signedInSub;

  @override
  void initState() {
    super.initState();
    // Giỏ hàng cần access token nên chỉ tải khi đã có phiên đăng nhập.
    if (widget.authRepository.isSignedIn) _cartController.initialize();
    _signedInSub = widget.authRepository.signedInChanges.listen((signedIn) {
      if (signedIn) {
        _cartController.initialize();
      } else {
        _cartController.reset();
      }
    });
  }

  @override
  void dispose() {
    _signedInSub.cancel();
    _cartController.dispose();
    super.dispose();
  }

  void _buyNow(ProductDetail product, int quantity) {
    final subtotal = product.price * quantity;
    _navigatorKey.currentState?.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CheckoutScreen(
          repository: widget.checkoutRepository,
          buyNow: CheckoutBuyNow(productId: product.id, quantity: quantity),
          summary: CheckoutSummary(
            items: <CheckoutSummaryItem>[
              CheckoutSummaryItem(
                productId: product.id,
                name: product.name,
                quantity: quantity,
                unitPrice: product.price,
                subtotal: subtotal,
                imageUrl: product.imageUrls.firstOrNull,
              ),
            ],
            subtotal: subtotal,
            tax: 0,
            shippingFee: 0,
            grandTotal: subtotal,
          ),
        ),
      ),
    );
  }

  void _openCheckout() {
    final cart = _cartController;
    _navigatorKey.currentState?.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CheckoutScreen(
          repository: widget.checkoutRepository,
          summary: CheckoutSummary(
            items: <CheckoutSummaryItem>[
              for (final item in cart.items)
                CheckoutSummaryItem(
                  productId: item.productId,
                  name: item.name,
                  quantity: item.quantity,
                  unitPrice: item.unitPrice,
                  subtotal: item.subtotal,
                  imageUrl: item.imageUrl,
                  imageAsset: item.imageAsset,
                  variant: item.variant.isEmpty ? null : item.variant,
                ),
            ],
            subtotal: cart.subtotal,
            tax: 0,
            shippingFee: 0,
            grandTotal: cart.subtotal,
          ),
          onCartChanged: cart.initialize,
        ),
      ),
    );
  }

  void _openNotifications(NotificationController controller) {
    final profile = widget.profileRepository;
    final navigator = _navigatorKey.currentState;
    navigator?.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsScreen(
          controller: controller,
          onOpenOrder: profile == null
              ? null
              : (orderId) => navigator.push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => OrderDetailScreen(
                      repository: profile,
                      orderId: orderId,
                    ),
                  ),
                ),
          onOpenIncidents: profile == null
              ? null
              : () => navigator.push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => IncidentListScreen(repository: profile),
                  ),
                ),
        ),
      ),
    );
  }

  Future<String?> _applyChatbotCartAction(ChatbotCartAction action) async {
    final cart = _cartController;
    final item = cart.items
        .where((item) => item.productId == action.productId)
        .firstOrNull;
    final bool done;
    switch (action.type) {
      case ChatbotCartActionType.add:
        done = await cart.addProductById(
          action.productId ?? '',
          quantity: action.quantity ?? 1,
        );
      case ChatbotCartActionType.update:
        if (item == null) return _chatbotCartItemMissing;
        done = await cart.updateQuantity(item.id, action.quantity ?? 1);
      case ChatbotCartActionType.remove:
        if (item == null) return _chatbotCartItemMissing;
        done = await cart.remove(item.id);
      case ChatbotCartActionType.clear:
        done = await cart.clear();
    }
    if (done) return null;
    return cart.errorMessage ??
        'Chưa cập nhật được giỏ hàng. Vui lòng thử lại.';
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    return AuthRoutes.onGenerateRoute(settings) ??
        ProductRoutes.onGenerateRoute(settings);
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.authRepository;
    final profile = widget.profileRepository;
    return AuthScope(
      repository: auth,
      child: CartScope(
        controller: _cartController,
        child: ProductScope(
          repository: widget.productRepository,
          child: BuyNowScope(
            onBuyNow: _buyNow,
            child: MaterialApp(
              navigatorKey: _navigatorKey,
              debugShowCheckedModeBanner: false,
              title: 'Nhà Có Hoa',
              theme: AppTheme.data(),
              home: AuthSessionGate(
                signedInBuilder: (_) => _SignedInShell(
                  notificationRepository: widget.notificationRepository,
                  checkoutRepository: widget.checkoutRepository,
                  onOpenNotifications: _openNotifications,
                  onSignOut: auth.signOut,
                  onCheckout: _openCheckout,
                  accountBuilder: profile == null
                      ? null
                      : (_) => AccountScreen(
                          repository: profile,
                          checkoutRepository: widget.checkoutRepository,
                          onSignOut: auth.signOut,
                        ),
                ),
              ),
              onGenerateRoute: _onGenerateRoute,
              builder: (context, child) => StreamBuilder<bool>(
                stream: auth.signedInChanges,
                initialData: auth.isSignedIn,
                builder: (context, snapshot) => ChatbotOverlayHost(
                  repository: widget.chatbotRepository,
                  // Chỉ hiện trên màn chính, không che form đăng nhập.
                  visible: (snapshot.data ?? false) && auth.isProfileComplete,
                  launcherBottomInset: AppBottomNav.reservedHeight + 8,
                  contextProvider: currentChatbotContext,
                  onProductTap: (productId) => _navigatorKey.currentState
                      ?.pushNamed(ProductRoutes.detail, arguments: productId),
                  onCartAction: _applyChatbotCartAction,
                  onOpenIncidentReport: profile == null
                      ? null
                      : (draft) => _navigatorKey.currentState?.push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (_) => IncidentReportFormScreen(
                              repository: profile,
                              category: draft.category,
                              title: draft.title,
                              description: draft.description,
                              orderId: draft.orderId,
                            ),
                          ),
                        ),
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignedInShell extends StatefulWidget {
  const _SignedInShell({
    required this.notificationRepository,
    required this.checkoutRepository,
    required this.onOpenNotifications,
    required this.onSignOut,
    required this.onCheckout,
    this.accountBuilder,
  });

  final NotificationRepository notificationRepository;
  final CheckoutRepository checkoutRepository;
  final ValueChanged<NotificationController> onOpenNotifications;
  final VoidCallback onSignOut;
  final VoidCallback onCheckout;
  final WidgetBuilder? accountBuilder;

  @override
  State<_SignedInShell> createState() => _SignedInShellState();
}

class _SignedInShellState extends State<_SignedInShell> {
  late final NotificationController _notificationController =
      NotificationController(repository: widget.notificationRepository)
        ..loadInitial();

  @override
  void dispose() {
    _notificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainShell(
      onSignOut: widget.onSignOut,
      onCheckout: widget.onCheckout,
      onOpenStores: () {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => StoreMapScreen(
              repository: widget.checkoutRepository,
            ),
          ),
        );
      },
      accountBuilder: widget.accountBuilder,
      notificationController: _notificationController,
      onNotifications: () =>
          widget.onOpenNotifications(_notificationController),
    );
  }
}
