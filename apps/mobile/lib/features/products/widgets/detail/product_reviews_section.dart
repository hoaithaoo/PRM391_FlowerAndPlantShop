import 'package:flutter/material.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

import '../../data/product_scope.dart';

/// Khối "Đánh giá" ở trang chi tiết: điểm trung bình, số lượt và danh sách.
/// Tự tải dữ liệu; lỗi tải chỉ ẩn danh sách, không chặn trang sản phẩm.
class ProductReviewsSection extends StatefulWidget {
  const ProductReviewsSection({super.key, required this.productId});

  final String productId;

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  ProductReviewPage? _page;
  bool _failed = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    try {
      final page = await ProductScope.of(context).listProductReviews(
        widget.productId,
      );
      if (mounted) setState(() => _page = page);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _page;
    return Container(
      key: const Key('detail-reviews'),
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Đánh giá', style: AppTextStyles.headline2),
              const Spacer(),
              if (page != null && page.totalReviews > 0) ...[
                const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                const SizedBox(width: 4),
                Text(
                  '${page.averageRating.toStringAsFixed(1)} '
                  '(${page.totalReviews})',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (_failed)
            Text('Không tải được đánh giá.', style: AppTextStyles.caption)
          else if (page == null)
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (page.items.isEmpty)
            Text(
              'Chưa có đánh giá. Mua và nhận hàng để là người đầu tiên đánh giá.',
              style: AppTextStyles.caption,
            )
          else
            for (final (index, review) in page.items.indexed) ...[
              if (index > 0) const Divider(height: 24),
              _ReviewTile(review: review),
            ],
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final ProductReview review;

  @override
  Widget build(BuildContext context) {
    final comment = review.comment?.trim();
    final avatar = review.authorAvatarUrl;
    final d = review.createdAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accentLight,
              backgroundImage: avatar == null ? null : NetworkImage(avatar),
              child: avatar == null
                  ? const Icon(Icons.person, size: 18, color: AppColors.accent)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.authorName ?? 'Khách hàng',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  StarRow(rating: review.rating, size: 14),
                ],
              ),
            ),
            Text(
              '${d.day.toString().padLeft(2, '0')}/'
              '${d.month.toString().padLeft(2, '0')}/${d.year}',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        if (comment != null && comment.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(comment, style: AppTextStyles.body),
        ],
        if (review.imageUrls.isNotEmpty) ...[
          const SizedBox(height: 8),
          ReviewImageStrip(urls: review.imageUrls),
        ],
      ],
    );
  }
}

/// Hàng sao 1–5 chỉ để hiển thị.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.rating, this.size = 16});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: Colors.amber,
            size: size,
          ),
      ],
    );
  }
}

/// Ảnh nhỏ của đánh giá; chạm để xem lớn.
class ReviewImageStrip extends StatelessWidget {
  const ReviewImageStrip({super.key, required this.urls, this.size = 72});

  final List<String> urls;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final url in urls)
          GestureDetector(
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => Dialog(
                insetPadding: const EdgeInsets.all(16),
                child: InteractiveViewer(child: Image.network(url)),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: size,
                  height: size,
                  color: AppColors.border,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
