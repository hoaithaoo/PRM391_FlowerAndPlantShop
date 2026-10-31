import 'package:flutter/material.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

/// Ô tìm kiếm "Tìm sản phẩm..." cao 52, bo 12, có nút xoá khi đã nhập chữ.
class CatalogSearchField extends StatelessWidget {
  const CatalogSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;

  /// Gọi mỗi lần gõ (controller sẽ debounce).
  final ValueChanged<String> onChanged;

  /// Nhấn tìm kiếm trên bàn phím.
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          key: const Key('catalog-search'),
          controller: controller,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textInputAction: TextInputAction.search,
          style: AppTextStyles.body.copyWith(color: AppColors.textHeading),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: 'Tìm sản phẩm...',
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            prefixIcon: const Icon(
              Icons.search,
              size: 20,
              color: AppColors.textMuted,
            ),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    key: const Key('catalog-search-clear'),
                    tooltip: 'Xoá tìm kiếm',
                    onPressed: onClear,
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            enabledBorder: border(AppColors.border),
            focusedBorder: border(AppColors.primaryActive),
            border: border(AppColors.border),
          ),
        );
      },
    );
  }
}
