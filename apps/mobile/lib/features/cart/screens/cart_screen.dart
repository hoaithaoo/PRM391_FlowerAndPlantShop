import 'package:flutter/material.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

import '../../products/widgets/common/brand_header.dart';
import '../models/cart_item.dart';
import '../state/cart_controller.dart';
import '../state/cart_scope.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key, required this.onContinueShopping});

  final VoidCallback onContinueShopping;

  @override
  Widget build(BuildContext context) {
    final controller = CartScope.of(context);
    return Material(
      key: const Key('cart-screen'),
      color: AppColors.background,
      child: Column(
        children: [
          const BrandHeader(),
          Expanded(
            child: controller.isLoading
                ? const Center(
                    child: CircularProgressIndicator(key: Key('cart-loading')),
                  )
                : controller.status == CartStatus.error && controller.isEmpty
                ? _CartLoadError(
                    message: controller.errorMessage,
                    onRetry: controller.initialize,
                  )
                : controller.isEmpty
                ? _EmptyCart(onContinueShopping: onContinueShopping)
                : _CartContents(
                    controller: controller,
                    onContinueShopping: onContinueShopping,
                  ),
          ),
          if (!controller.isLoading && !controller.isEmpty)
            _CheckoutBar(
              subtotal: controller.subtotal,
              isBusy: controller.isMutating,
              onCheckout: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Checkout API chưa được triển khai trên backend.',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CartContents extends StatelessWidget {
  const _CartContents({
    required this.controller,
    required this.onContinueShopping,
  });

  final CartController controller;
  final VoidCallback onContinueShopping;

  Future<void> _clear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Làm trống giỏ hàng?'),
        content: const Text(
          'Tất cả tác phẩm sẽ được xoá khỏi giỏ hàng của bạn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            key: const Key('cart-confirm-clear'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Làm trống'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Giỏ hàng (${controller.items.length})',
                style: AppTextStyles.headline2,
              ),
            ),
            TextButton.icon(
              key: const Key('cart-clear'),
              onPressed: controller.isMutating ? null : () => _clear(context),
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: const Text('Làm trống'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const _NoticeBanner(),
        if (controller.errorMessage case final message?) ...[
          const SizedBox(height: 10),
          _CartErrorBanner(
            message: message,
            onDismiss: controller.dismissError,
          ),
        ],
        const SizedBox(height: 12),
        for (final item in controller.items) ...[
          _CartItemCard(item: item, controller: controller),
          const SizedBox(height: 10),
        ],
        _SubtotalCard(subtotal: controller.subtotal),
        const SizedBox(height: 12),
        const _PromiseBanner(),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: onContinueShopping,
            child: const Text('Tiếp tục chọn tác phẩm'),
          ),
        ),
      ],
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.spa_outlined,
            size: 20,
            color: AppColors.primaryActive,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mỗi tác phẩm hoa tươi được cắm thủ công bởi nghệ nhân Fleuré vào đúng ngày giao.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textBody,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.item, required this.controller});

  final CartItem item;
  final CartController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('cart-item-${item.productId}'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 76,
              height: 86,
              child: _CartImage(item: item),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.serif(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                      ),
                    ),
                    IconButton(
                      key: Key('cart-remove-${item.productId}'),
                      onPressed: controller.isMutating
                          ? null
                          : () => controller.remove(item.id),
                      tooltip: 'Xoá ${item.name}',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline, size: 19),
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
                Text(
                  item.variant,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatVnd(item.unitPrice),
                        style: AppTextStyles.price,
                      ),
                    ),
                    _QuantityStepper(item: item, controller: controller),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartImage extends StatelessWidget {
  const _CartImage({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    if (item.imageAsset case final asset?) {
      return Image.asset(asset, fit: BoxFit.cover);
    }
    if (item.imageUrl case final url?) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _CartImagePlaceholder(),
      );
    }
    return const _CartImagePlaceholder();
  }
}

class _CartImagePlaceholder extends StatelessWidget {
  const _CartImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surfacePastel,
      child: Center(
        child: Icon(Icons.local_florist_outlined, color: AppColors.accent),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.item, required this.controller});

  final CartItem item;
  final CartController controller;

  @override
  Widget build(BuildContext context) {
    final max = mathMin(cartMaxPerProduct, item.stock);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfacePastel,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            key: Key('cart-decrease-${item.productId}'),
            icon: Icons.remove,
            tooltip: 'Giảm số lượng ${item.name}',
            onPressed: !controller.isMutating && item.quantity > 1
                ? () => controller.updateQuantity(item.id, item.quantity - 1)
                : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '${item.quantity}',
              key: Key('cart-quantity-${item.productId}'),
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textHeading,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _StepButton(
            key: Key('cart-increase-${item.productId}'),
            icon: Icons.add,
            tooltip: 'Tăng số lượng ${item.name}',
            onPressed: !controller.isMutating && item.quantity < max
                ? () => controller.updateQuantity(item.id, item.quantity + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 16),
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      padding: EdgeInsets.zero,
      color: AppColors.primary,
      disabledColor: AppColors.iconInactive,
    );
  }
}

class _SubtotalCard extends StatelessWidget {
  const _SubtotalCard({required this.subtotal});

  final int subtotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('cart-subtotal'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Tạm tính', style: AppTextStyles.body),
              const Spacer(),
              Text(
                formatVnd(subtotal),
                style: AppFonts.sans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Phí vận chuyển và ưu đãi sẽ được tính ở bước thanh toán.',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromiseBanner extends StatelessWidget {
  const _PromiseBanner();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.recycling_outlined,
          size: 17,
          color: AppColors.statusPending,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Đóng gói an toàn · Tiêu chuẩn Fleuré Studio',
            textAlign: TextAlign.center,
            style: AppTextStyles.badge.copyWith(color: AppColors.statusPending),
          ),
        ),
      ],
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.subtotal,
    required this.isBusy,
    required this.onCheckout,
  });

  final int subtotal;
  final bool isBusy;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 92),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F171C19),
            offset: Offset(0, -4),
            blurRadius: 18,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tổng tạm tính', style: AppTextStyles.caption),
                Text(
                  formatVnd(subtotal),
                  style: AppFonts.sans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            key: const Key('cart-checkout'),
            onPressed: isBusy ? null : onCheckout,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Tiến hành thanh toán'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 52),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartErrorBanner extends StatelessWidget {
  const _CartErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.error.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        key: const Key('cart-mutation-error'),
        dense: true,
        leading: const Icon(Icons.error_outline, color: AppColors.error),
        title: Text(message, style: AppTextStyles.caption),
        trailing: IconButton(
          onPressed: onDismiss,
          tooltip: 'Đóng thông báo',
          icon: const Icon(Icons.close, size: 18),
        ),
      ),
    );
  }
}

class _CartLoadError extends StatelessWidget {
  const _CartLoadError({required this.message, required this.onRetry});

  final String? message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('cart-load-error'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppColors.iconInactive,
            ),
            const SizedBox(height: 16),
            Text('Không tải được giỏ hàng', style: AppTextStyles.headline2),
            const SizedBox(height: 8),
            Text(
              message ?? 'Vui lòng kiểm tra kết nối và thử lại.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const Key('cart-retry'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onContinueShopping});

  final VoidCallback onContinueShopping;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('cart-empty'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 40,
                color: AppColors.primaryActive,
              ),
            ),
            const SizedBox(height: 22),
            Text('Giỏ hàng đang trống', style: AppTextStyles.headline2),
            const SizedBox(height: 8),
            Text(
              'Khám phá những tác phẩm hoa và cây xanh được tuyển chọn cho bạn.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              key: const Key('cart-explore'),
              onPressed: onContinueShopping,
              icon: const Icon(Icons.local_florist_outlined),
              label: const Text('Khám phá sản phẩm'),
            ),
          ],
        ),
      ),
    );
  }
}

int mathMin(int a, int b) => a < b ? a : b;
