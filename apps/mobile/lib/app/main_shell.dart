import 'package:flutter/material.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

import '../features/products/screens/home_screen.dart';
import '../features/products/screens/product_catalog_screen.dart';

/// Các tab của thanh điều hướng dưới.
enum MainTab {
  home('Trang chủ', Icons.home_outlined, Icons.home),
  products('Sản phẩm', Icons.storefront_outlined, Icons.storefront),
  chatbot('Chatbot', Icons.auto_awesome_outlined, Icons.auto_awesome),
  cart('Giỏ hàng', Icons.shopping_bag_outlined, Icons.shopping_bag),
  account('Tài khoản', Icons.person_outline, Icons.person);

  const MainTab(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Khung chính có thanh điều hướng nổi (Penpot board "Nav").
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialTab = MainTab.home});

  final MainTab initialTab;

  /// Chuyển sang tab Sản phẩm, chọn sẵn [categoryId] (null là "Tất cả").
  ///
  /// Dùng từ trang chủ: chip danh mục, "Xem thêm", "Khám phá bộ sưu tập".
  static void openCatalog(BuildContext context, {String? categoryId}) {
    final state = context.findAncestorStateOfType<_MainShellState>();
    assert(state != null, 'Không tìm thấy MainShell phía trên widget này.');
    state?._openCatalog(categoryId);
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late MainTab _tab = widget.initialTab;
  String? _catalogCategoryId;

  // Đổi key để dựng lại màn danh mục với category mới
  int _catalogVersion = 0;

  void _openCatalog(String? categoryId) {
    setState(() {
      _catalogCategoryId = categoryId;
      _catalogVersion++;
      _tab = MainTab.products;
    });
  }

  Widget _buildTab(MainTab tab) {
    return switch (tab) {
      MainTab.home => const HomeScreen(),
      MainTab.products => ProductCatalogScreen(
        key: ValueKey(_catalogVersion),
        initialCategoryId: _catalogCategoryId,
      ),
      _ => _ComingSoon(tab: tab),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _tab.index,
        children: [
          for (final tab in MainTab.values)
            // Tab đang ẩn vẫn nằm trong cây; tắt ticker để animation không chạy ngầm
            TickerMode(enabled: tab == _tab, child: _buildTab(tab)),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        current: _tab,
        onSelected: (tab) => setState(() => _tab = tab),
      ),
    );
  }
}

/// Thanh điều hướng dạng viên thuốc nổi, cao 64px, bo tròn hoàn toàn.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.current,
    required this.onSelected,
    this.showCartDot = true,
  });

  final MainTab current;
  final ValueChanged<MainTab> onSelected;
  final bool showCartDot;

  /// Khoảng nội dung cần chừa phía dưới để không bị thanh điều hướng che.
  static const reservedHeight = 64.0 + 12 + 16;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(200),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14171C19),
              offset: Offset(0, -4),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          children: [
            for (final tab in MainTab.values)
              Expanded(
                child: _NavItem(
                  tab: tab,
                  selected: tab == current,
                  showDot: showCartDot && tab == MainTab.cart,
                  onTap: () => onSelected(tab),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.showDot,
    required this.onTap,
  });

  final MainTab tab;
  final bool selected;
  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryActive : AppColors.iconInactive;
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(selected ? tab.activeIcon : tab.icon, size: 20, color: color),
                  if (showDot)
                    const Positioned(
                      right: -2,
                      top: -1,
                      child: SizedBox.square(
                        dimension: 6,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: AppTextStyles.badge.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.tab});

  final MainTab tab;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon, size: 40, color: AppColors.iconInactive),
            const SizedBox(height: 12),
            Text(tab.label, style: AppTextStyles.headline2),
            const SizedBox(height: 4),
            Text(
              'Tính năng đang được phát triển.',
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
