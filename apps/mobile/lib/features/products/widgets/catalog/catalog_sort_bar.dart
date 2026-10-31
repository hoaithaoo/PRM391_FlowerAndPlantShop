import 'package:flutter/material.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

import '../../state/price_range.dart';

/// Nhãn tiếng Việt của kiểu sắp xếp.
String catalogSortLabel(ProductSort sort) => switch (sort) {
  ProductSort.newest => 'Mới nhất',
  ProductSort.priceAsc => 'Giá tăng dần',
  ProductSort.priceDesc => 'Giá giảm dần',
};

/// Thanh sắp xếp (trái) + nút "Lọc giá (VNĐ)" (phải).
class CatalogSortBar extends StatelessWidget {
  const CatalogSortBar({
    super.key,
    required this.sort,
    required this.minPrice,
    required this.maxPrice,
    required this.onSortChanged,
    required this.onPriceFilterTap,
  });

  final ProductSort sort;
  final int? minPrice;
  final int? maxPrice;
  final ValueChanged<ProductSort> onSortChanged;
  final VoidCallback onPriceFilterTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: _SortDropdown(sort: sort, onChanged: onSortChanged),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: _PriceFilterButton(
            min: minPrice,
            max: maxPrice,
            onTap: onPriceFilterTap,
          ),
        ),
      ],
    );
  }
}

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({required this.sort, required this.onChanged});

  final ProductSort sort;
  final ValueChanged<ProductSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ProductSort>(
      key: const Key('catalog-sort'),
      tooltip: 'Sắp xếp theo',
      initialValue: sort,
      onSelected: onChanged,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        for (final option in ProductSort.values)
          PopupMenuItem<ProductSort>(
            key: Key('catalog-sort-${option.apiValue}'),
            value: option,
            child: Text(
              catalogSortLabel(option),
              style: AppTextStyles.body.copyWith(
                color: option == sort
                    ? AppColors.primaryActive
                    : AppColors.textBody,
                fontWeight: option == sort ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 34),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfacePastel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.swap_vert, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                catalogSortLabel(sort),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHeading,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceFilterButton extends StatelessWidget {
  const _PriceFilterButton({
    required this.min,
    required this.max,
    required this.onTap,
  });

  final int? min;
  final int? max;
  final VoidCallback onTap;

  bool get _active => min != null || max != null;

  @override
  Widget build(BuildContext context) {
    final color = _active ? AppColors.primaryActive : AppColors.textHeading;
    return Semantics(
      button: true,
      selected: _active,
      child: Material(
        color: _active ? AppColors.primaryLight : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: _active ? AppColors.primaryActive : AppColors.border,
          ),
        ),
        child: InkWell(
          key: const Key('catalog-price-filter'),
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 34),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, size: 14, color: color),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _active
                          ? priceRangeLabel(min, max)
                          : 'Lọc giá (VNĐ)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: color,
                        fontWeight: _active ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
