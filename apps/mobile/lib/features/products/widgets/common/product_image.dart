import 'package:flutter/material.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

/// Ảnh sản phẩm từ URL, có placeholder khi chưa có ảnh hoặc tải lỗi.
///
/// Seed hiện để `imageUrl = null` nên placeholder là trạng thái thường gặp.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.dimmed = false,
  });

  final String? url;
  final BoxFit fit;

  /// Làm mờ ảnh (sản phẩm hết hàng).
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    final Widget image = imageUrl == null || imageUrl.isEmpty
        ? const _Placeholder()
        : Image.network(
            imageUrl,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, _, _) => const _Placeholder(),
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : const _Placeholder(),
          );
    if (!dimmed) return image;
    return Opacity(opacity: 0.55, child: image);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surfacePastel,
      child: Center(
        child: Icon(
          Icons.local_florist_outlined,
          size: 40,
          color: AppColors.accentBorder,
        ),
      ),
    );
  }
}
