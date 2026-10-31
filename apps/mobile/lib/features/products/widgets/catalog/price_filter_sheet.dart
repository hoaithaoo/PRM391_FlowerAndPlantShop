import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

import '../../state/price_range.dart';

/// Mở bottom sheet nhập khoảng giá.
///
/// Trả về [PriceRange] khi bấm "Áp dụng"; [PriceRange] rỗng khi bấm "Xoá lọc"
/// hoặc để trống cả hai ô; null khi đóng sheet mà không chọn gì.
Future<PriceRange?> showPriceFilterSheet(
  BuildContext context, {
  int? min,
  int? max,
}) {
  return showModalBottomSheet<PriceRange>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.surfacePastel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _PriceFilterSheet(min: min, max: max),
  );
}

class _PriceFilterSheet extends StatefulWidget {
  const _PriceFilterSheet({this.min, this.max});

  final int? min;
  final int? max;

  @override
  State<_PriceFilterSheet> createState() => _PriceFilterSheetState();
}

class _PriceFilterSheetState extends State<_PriceFilterSheet> {
  late final _minController = TextEditingController(
    text: widget.min?.toString() ?? '',
  );
  late final _maxController = TextEditingController(
    text: widget.max?.toString() ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _apply() {
    final parsed = parsePriceRange(_minController.text, _maxController.text);
    if (!parsed.isValid) {
      setState(() => _error = parsed.error);
      return;
    }
    Navigator.pop(context, parsed.range);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lọc theo giá', style: AppTextStyles.headline2),
            const SizedBox(height: 4),
            Text(
              'Nhập khoảng giá (VNĐ) bạn muốn xem.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PriceField(
                    fieldKey: const Key('catalog-price-min'),
                    controller: _minController,
                    label: 'Từ (₫)',
                    onChanged: (_) => setState(() => _error = null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PriceField(
                    fieldKey: const Key('catalog-price-max'),
                    controller: _maxController,
                    label: 'Đến (₫)',
                    onChanged: (_) => setState(() => _error = null),
                    onSubmitted: (_) => _apply(),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                key: const Key('catalog-price-error'),
                style: AppTextStyles.caption.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('catalog-price-clear'),
                    onPressed: () => Navigator.pop(context, const PriceRange()),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.borderInactive),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: AppTextStyles.button,
                    ),
                    child: const Text('Xoá lọc'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('catalog-price-apply'),
                    onPressed: _apply,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: AppTextStyles.button,
                    ),
                    child: const Text('Áp dụng'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  const _PriceField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.onChanged,
    this.onSubmitted,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
    return TextField(
      key: fieldKey,
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: onSubmitted == null
          ? TextInputAction.next
          : TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(12),
      ],
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: AppTextStyles.body.copyWith(color: AppColors.textHeading),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        floatingLabelStyle: AppTextStyles.caption.copyWith(
          color: AppColors.primaryActive,
        ),
        hintText: '0',
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: border(AppColors.borderInactive),
        focusedBorder: border(AppColors.primaryActive),
        border: border(AppColors.borderInactive),
      ),
    );
  }
}
