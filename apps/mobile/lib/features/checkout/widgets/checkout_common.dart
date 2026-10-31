import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/checkout_flow_models.dart';
import '../models/checkout_summary.dart';
import '../utils/checkout_assets.dart';
import '../utils/checkout_theme.dart';
import '../utils/currency_formatter.dart';

class FleureAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FleureAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.closeButton = false,
    this.onLeadingPressed,
    this.showProfile = true,
  });

  final String title;
  final bool showBack;
  final bool closeButton;
  final VoidCallback? onLeadingPressed;
  final bool showProfile;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      leadingWidth: 52,
      leading: showBack
          ? IconButton(
              onPressed:
                  onLeadingPressed ?? () => Navigator.of(context).maybePop(),
              tooltip: closeButton ? 'Đóng' : 'Quay lại',
              icon: Icon(
                closeButton ? Icons.close_rounded : Icons.arrow_back_rounded,
                size: 22,
              ),
            )
          : null,
      titleSpacing: showBack ? 0 : 18,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Image.asset(
            CheckoutAssets.logo,
            width: 68,
            height: 21,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Text(
              'Fleuré',
              style: CheckoutTypography.brand.copyWith(fontSize: 22),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: CheckoutPalette.charcoal500,
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.8,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        if (showProfile) ...[
          IconButton(
            onPressed: () {},
            tooltip: 'Chia sẻ',
            icon: const Icon(Icons.ios_share_outlined, size: 20),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ClipOval(
              child: CheckoutAssetImage(
                asset: CheckoutAssets.profile,
                width: 30,
                height: 30,
                fallbackIcon: Icons.person_outline_rounded,
              ),
            ),
          ),
        ],
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(color: CheckoutPalette.cream200),
      ),
    );
  }
}

class CheckoutAssetImage extends StatelessWidget {
  const CheckoutAssetImage({
    super.key,
    required this.asset,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.local_florist_outlined,
  });

  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => Container(
        width: width,
        height: height,
        color: CheckoutPalette.forest50,
        alignment: Alignment.center,
        child: Icon(fallbackIcon, color: CheckoutPalette.forest700, size: 28),
      ),
    );
    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}

class CheckoutContent extends StatelessWidget {
  const CheckoutContent({super.key, required this.children, this.bottom = 32});

  final List<Widget> children;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(18, 18, 18, bottom),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

class FulfillmentSwitch extends StatelessWidget {
  const FulfillmentSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final FulfillmentMode value;
  final ValueChanged<FulfillmentMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEBE8E2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          _item(
            context,
            mode: FulfillmentMode.delivery,
            icon: Icons.local_shipping_outlined,
            label: 'Giao tận nơi',
          ),
          _item(
            context,
            mode: FulfillmentMode.pickup,
            icon: Icons.storefront_outlined,
            label: 'Lấy tại quán',
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required FulfillmentMode mode,
    required IconData icon,
    required String label,
  }) {
    final selected = mode == value;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(mode),
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: selected ? CheckoutPalette.forest800 : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : CheckoutPalette.charcoal500,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : CheckoutPalette.charcoal700,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CheckoutSectionHeader extends StatelessWidget {
  const CheckoutSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: CheckoutTypography.section),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: CheckoutPalette.charcoal500,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class CheckoutSurfaceCard extends StatelessWidget {
  const CheckoutSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = CheckoutPalette.surface,
    this.borderColor = CheckoutPalette.cream300,
    this.radius = 16,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class CheckoutInfoBanner extends StatelessWidget {
  const CheckoutInfoBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.color = CheckoutPalette.forest50,
    this.iconColor = CheckoutPalette.forest700,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: CheckoutPalette.charcoal900,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: CheckoutPalette.charcoal500,
                    fontSize: 11.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentOptionCard extends StatelessWidget {
  const PaymentOptionCard({
    super.key,
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final LocalPaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (method) {
      LocalPaymentMethod.sepay => Icons.qr_code_2_rounded,
      LocalPaymentMethod.cod => Icons.local_shipping_outlined,
      LocalPaymentMethod.payAtStore => Icons.storefront_outlined,
    };
    return CheckoutSurfaceCard(
      onTap: onTap,
      color: selected ? CheckoutPalette.forest50 : CheckoutPalette.surface,
      borderColor: selected
          ? CheckoutPalette.forest700
          : CheckoutPalette.cream300,
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: selected
                  ? CheckoutPalette.forest100
                  : CheckoutPalette.creamPastel,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 23, color: CheckoutPalette.forest800),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        method.label,
                        style: const TextStyle(
                          color: CheckoutPalette.charcoal900,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (method == LocalPaymentMethod.sepay) ...[
                      const SizedBox(width: 8),
                      const CheckoutStatusBadge(
                        text: 'Khuyên dùng',
                        color: CheckoutPalette.petal100,
                        textColor: CheckoutPalette.petal500,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  method.description,
                  style: const TextStyle(
                    color: CheckoutPalette.charcoal500,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? CheckoutPalette.forest800 : Colors.transparent,
              border: Border.all(
                color: selected
                    ? CheckoutPalette.forest800
                    : CheckoutPalette.charcoal400,
                width: 1.4,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : null,
          ),
        ],
      ),
    );
  }
}

class CheckoutProductTile extends StatelessWidget {
  const CheckoutProductTile({super.key, required this.item});

  final CheckoutSummaryItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CheckoutAssetImage(
          asset: item.imageAsset ?? '',
          width: 64,
          height: 80,
          borderRadius: BorderRadius.circular(12),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.name,
                style: const TextStyle(
                  color: CheckoutPalette.charcoal900,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (item.variant != null) ...[
                const SizedBox(height: 5),
                Text(
                  item.variant!,
                  style: const TextStyle(
                    color: CheckoutPalette.charcoal500,
                    fontSize: 10.5,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                'Số lượng: ${item.quantity}',
                style: const TextStyle(
                  color: CheckoutPalette.charcoal500,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
        Text(
          formatVnd(item.subtotal),
          style: const TextStyle(
            color: CheckoutPalette.charcoal900,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class PriceSummaryCard extends StatelessWidget {
  const PriceSummaryCard({
    super.key,
    required this.summary,
    this.pickup = false,
  });

  final CheckoutSummary summary;
  final bool pickup;

  @override
  Widget build(BuildContext context) {
    final total = pickup
        ? summary.grandTotal - summary.shippingFee
        : summary.grandTotal;
    return CheckoutSurfaceCard(
      child: Column(
        children: <Widget>[
          _row('Tạm tính', formatVnd(summary.subtotal)),
          const SizedBox(height: 11),
          _row(
            pickup ? 'Phí nhận tại quán' : 'Phí giao hoa ưu tiên',
            pickup ? 'Miễn phí' : formatVnd(summary.shippingFee),
            valueColor: pickup ? CheckoutPalette.forest700 : null,
          ),
          const SizedBox(height: 11),
          _row(
            'Ưu đãi thành viên',
            '-${formatVnd(summary.discount)}',
            valueColor: CheckoutPalette.petal500,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(),
          ),
          _row('Tổng thanh toán', formatVnd(total), emphasized: true),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Đã bao gồm thuế',
              style: TextStyle(
                color: CheckoutPalette.charcoal400,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool emphasized = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: emphasized
                ? CheckoutPalette.charcoal900
                : CheckoutPalette.charcoal500,
            fontSize: emphasized ? 14 : 12,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? CheckoutPalette.charcoal900,
            fontSize: emphasized ? 17 : 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class CheckoutStickyBar extends StatelessWidget {
  const CheckoutStickyBar({
    super.key,
    required this.total,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final num total;
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        decoration: const BoxDecoration(
          color: CheckoutPalette.surface,
          border: Border(top: BorderSide(color: CheckoutPalette.cream200)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Color(0x100D1E15),
              blurRadius: 18,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'TỔNG CỘNG',
                    style: TextStyle(
                      color: CheckoutPalette.charcoal500,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatVnd(total),
                    style: const TextStyle(
                      color: CheckoutPalette.forest900,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 210,
              height: 54,
              child: FilledButton(
                onPressed: loading ? null : onPressed,
                child: loading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Flexible(child: Text(label)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckoutStatusBadge extends StatelessWidget {
  const CheckoutStatusBadge({
    super.key,
    required this.text,
    this.color = CheckoutPalette.forest100,
    this.textColor = CheckoutPalette.forest700,
  });

  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class CheckoutDetailRow extends StatelessWidget {
  const CheckoutDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.trailing,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (icon != null) ...[
          Icon(icon, color: CheckoutPalette.forest700, size: 18),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: CheckoutPalette.charcoal400,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: CheckoutPalette.charcoal900,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class CheckoutTimeline extends StatelessWidget {
  const CheckoutTimeline({super.key, required this.steps});

  final List<CheckoutTimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.generate(steps.length, (index) {
        final step = steps[index];
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                width: 28,
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: step.isActive
                            ? CheckoutPalette.forest800
                            : CheckoutPalette.forest50,
                        shape: BoxShape.circle,
                        border: Border.all(color: CheckoutPalette.forest100),
                      ),
                      child: Icon(
                        step.isActive
                            ? Icons.check_rounded
                            : Icons.local_florist_outlined,
                        color: step.isActive
                            ? Colors.white
                            : CheckoutPalette.forest700,
                        size: 13,
                      ),
                    ),
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          width: 1,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: CheckoutPalette.forest100,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: index < steps.length - 1 ? 18 : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        step.title,
                        style: const TextStyle(
                          color: CheckoutPalette.charcoal900,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        step.description,
                        style: const TextStyle(
                          color: CheckoutPalette.charcoal500,
                          fontSize: 10.5,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class LabeledCheckoutField extends StatelessWidget {
  const LabeledCheckoutField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.inputFormatters,
    this.onChanged,
    this.focusNode,
    this.showCounter = false,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool showCounter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: CheckoutPalette.charcoal700,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          focusNode: focusNode,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.none,
          buildCounter: showCounter && maxLength != null
              ? (
                  context, {
                  required currentLength,
                  required isFocused,
                  required maxLength,
                }) => Text(
                  '$currentLength/$maxLength',
                  semanticsLabel:
                      'Đã nhập $currentLength trên $maxLength ký tự',
                )
              : null,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 19),
            counterText: showCounter ? null : '',
          ),
        ),
      ],
    );
  }
}

class LabeledCheckoutDropdown<T> extends StatelessWidget {
  const LabeledCheckoutDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.validator,
    this.hint,
    this.fieldKey,
    this.prefixIcon,
  });

  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?) validator;
  final String? hint;
  final GlobalKey<FormFieldState<T>>? fieldKey;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: CheckoutPalette.charcoal700,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        DropdownButtonFormField<T>(
          key: fieldKey,
          initialValue: value,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(item.toString()),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: const TextStyle(
            color: CheckoutPalette.charcoal700,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 19),
          ),
        ),
      ],
    );
  }
}

class CheckoutHeroMark extends StatelessWidget {
  const CheckoutHeroMark({
    super.key,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Container(
          width: 118,
          height: 118,
          decoration: BoxDecoration(
            color: background.withValues(alpha: 0.55),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 7),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0x160D1E15), blurRadius: 18),
            ],
          ),
          child: Icon(icon, size: 38, color: foreground),
        ),
      ],
    );
  }
}
