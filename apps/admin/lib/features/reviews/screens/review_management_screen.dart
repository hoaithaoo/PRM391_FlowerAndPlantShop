import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';
import '../../../core/network/admin_api_client.dart';

/// Danh sách đánh giá sản phẩm; admin lọc theo sao / trạng thái và ẩn/hiện.
class ReviewManagementScreen extends StatefulWidget {
  const ReviewManagementScreen({super.key});

  @override
  State<ReviewManagementScreen> createState() => _ReviewManagementScreenState();
}

class _ReviewManagementScreenState extends State<ReviewManagementScreen> {
  final _searchController = TextEditingController();
  final _dateFormat = DateFormat('HH:mm - dd/MM/yyyy');
  int? _rating; // lọc số sao, null = tất cả
  bool? _hidden; // lọc ẩn/hiện, null = tất cả
  AdminReviewList? _list; // các trang đã tải, null = đang tải lần đầu
  String? _error;
  final _busy = <String>{}; // id đánh giá đang ẩn/hiện, để khóa nút tránh bấm 2 lần
  bool _loadingMore = false;

  AdminReviewsService get _service => context.read<AdminApiClient>().reviews;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Gọi API 1 trang với bộ lọc hiện tại.
  Future<AdminReviewList> _fetch(int page) => _service.getReviews(
        rating: _rating,
        hidden: _hidden,
        search: _searchController.text.trim(),
        page: page,
      );

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final list = await _fetch(1);
      if (mounted) setState(() => _list = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  /// Cuộn tới cuối thì tải trang kế và nối vào danh sách hiện có.
  Future<void> _loadMore() async {
    final current = _list;
    if (current == null || !current.hasMore || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final next = await _fetch(current.page + 1);
      if (mounted) {
        setState(() => _list = AdminReviewList(
              items: [...current.items, ...next.items],
              total: next.total,
              averageRating: next.averageRating,
              visibleReviews: next.visibleReviews,
              page: next.page,
              totalPages: next.totalPages,
            ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Không tải thêm được: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  /// Đảo trạng thái ẩn/hiện. Bài bị ẩn không hiện ở trang sản phẩm và không tính vào điểm trung bình.
  Future<void> _toggle(ProductReview review) async {
    setState(() => _busy.add(review.id));
    try {
      final updated =
          await _service.setReviewHidden(review.id, !review.isHidden);
      // Thay item tại chỗ để giữ các trang đã tải; thống kê lấy lại từ trang 1.
      final stats = await _fetch(1);
      final current = _list;
      if (mounted && current != null) {
        setState(() => _list = AdminReviewList(
              items: [
                for (final e in current.items) e.id == updated.id ? updated : e,
              ],
              total: stats.total,
              averageRating: stats.averageRating,
              visibleReviews: stats.visibleReviews,
              page: current.page,
              totalPages: stats.totalPages,
            ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Không cập nhật được: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(review.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quản lý đánh giá',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm nội dung, sản phẩm, email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _load,
                ),
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: _rating,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Số sao'),
                    items: [
                      const DropdownMenuItem(child: Text('Tất cả')),
                      for (var star = 5; star >= 1; star--)
                        DropdownMenuItem(value: star, child: Text('$star sao')),
                    ],
                    onChanged: (v) {
                      _rating = v;
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<bool?>(
                    initialValue: _hidden,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Trạng thái'),
                    items: const [
                      DropdownMenuItem(child: Text('Tất cả')),
                      DropdownMenuItem(value: false, child: Text('Đang hiện')),
                      DropdownMenuItem(value: true, child: Text('Đã ẩn')),
                    ],
                    onChanged: (v) {
                      _hidden = v;
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ),
          if (list != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${list.averageRating.toStringAsFixed(1)} trung bình · '
                      '${list.visibleReviews} đang hiện · ${list.total} kết quả',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _error != null
                ? Center(
                    child: TextButton(
                      onPressed: _load,
                      child: Text('Lỗi tải đánh giá: $_error\nChạm để thử lại.',
                          textAlign: TextAlign.center),
                    ),
                  )
                : list == null
                    ? const Center(child: CircularProgressIndicator())
                    : list.items.isEmpty
                        ? const Center(child: Text('Chưa có đánh giá nào.'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount:
                                  list.items.length + (list.hasMore ? 1 : 0),
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, i) => i == list.items.length
                                  ? Center(
                                      child: _loadingMore
                                          ? const CircularProgressIndicator()
                                          : OutlinedButton(
                                              onPressed: _loadMore,
                                              child: Text(
                                                'Tải thêm (${list.items.length}/${list.total})',
                                              ),
                                            ),
                                    )
                                  : _ReviewCard(
                                review: list.items[i],
                                date: _dateFormat.format(list.items[i].createdAt),
                                busy: _busy.contains(list.items[i].id),
                                onToggle: () => _toggle(list.items[i]),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ một đánh giá: sản phẩm, sao, bình luận, ảnh, người viết + nút ẩn/hiện.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.date,
    required this.busy,
    required this.onToggle,
  });

  final ProductReview review;
  final String date;
  final bool busy;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final comment = review.comment?.trim();
    return Opacity(
      opacity: review.isHidden ? 0.6 : 1,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      review.productName ?? 'Sản phẩm',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    review.isHidden ? 'Đã ẩn' : 'Đang hiện',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: review.isHidden
                          ? AppColors.statusCancelled
                          : AppColors.statusDelivered,
                    ),
                  ),
                  Switch(
                    value: !review.isHidden,
                    onChanged: busy ? null : (_) => onToggle(),
                  ),
                ],
              ),
              Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    Icon(
                      i <= review.rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 18,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${review.authorName ?? 'Khách'} · '
                      '${review.authorEmail ?? ''}',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              if (comment != null && comment.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(comment, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
              ],
              if (review.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final url in review.imageUrls)
                      GestureDetector(
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (_) => Dialog(
                            child: InteractiveViewer(child: Image.network(url)),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            url,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox(
                              width: 64,
                              height: 64,
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                [
                  if (review.orderNumber != null) 'Đơn ${review.orderNumber}',
                  date,
                ].join(' · '),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
