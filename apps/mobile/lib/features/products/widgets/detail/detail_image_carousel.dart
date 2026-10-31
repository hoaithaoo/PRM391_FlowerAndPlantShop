import 'package:flutter/material.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

import '../common/product_image.dart';

/// Carousel ảnh sản phẩm (Penpot: "Hero Image Carousel Container").
///
/// Khung 350x406 trên màn 390, bo 16, co giãn theo tỉ lệ. Không có ảnh thì
/// hiện một trang placeholder. Chip "i / n" ở góc dưới trái, chấm phân trang
/// ở góc dưới phải (ẩn khi chỉ có 1 ảnh).
class DetailImageCarousel extends StatefulWidget {
  const DetailImageCarousel({
    super.key,
    required this.imageUrls,
    this.dimmed = false,
  });

  final List<String> imageUrls;

  /// Làm mờ ảnh khi sản phẩm hết hàng.
  final bool dimmed;

  /// Tỉ lệ rộng/cao của khung ảnh theo Penpot (350 / 406).
  static const aspectRatio = 350 / 406;

  @override
  State<DetailImageCarousel> createState() => _DetailImageCarouselState();
}

class _DetailImageCarouselState extends State<DetailImageCarousel> {
  final _controller = PageController();
  int _index = 0;

  int get _count => widget.imageUrls.isEmpty ? 1 : widget.imageUrls.length;

  @override
  void didUpdateWidget(DetailImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls != widget.imageUrls && _index >= _count) {
      _index = 0;
      if (_controller.hasClients) _controller.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AspectRatio(
        aspectRatio: DetailImageCarousel.aspectRatio,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.softShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  key: const Key('detail-carousel'),
                  controller: _controller,
                  itemCount: _count,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => ProductImage(
                    url: urls.isEmpty ? null : urls[i],
                    dimmed: widget.dimmed,
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CounterChip(index: _index, count: _count),
                      if (_count > 1)
                        _Dots(
                          key: const Key('detail-page-indicator'),
                          index: _index,
                          count: _count,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CounterChip extends StatelessWidget {
  const _CounterChip({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('detail-image-counter'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        boxShadow: AppColors.softShadow,
      ),
      child: Text(
        '${index + 1} / $count',
        style: AppTextStyles.badge.copyWith(color: AppColors.textHeading),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({super.key, required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
              width: i == index ? 8 : 6,
              height: i == index ? 8 : 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == index ? AppColors.primary : AppColors.iconInactive,
              ),
            ),
        ],
      ),
    );
  }
}
