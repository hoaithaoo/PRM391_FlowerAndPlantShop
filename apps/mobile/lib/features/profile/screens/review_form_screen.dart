import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart' show ProductReview;

import '../../checkout/utils/checkout_theme.dart';
import '../../checkout/widgets/checkout_common.dart';
import '../data/profile_repository.dart';

/// Form đánh giá một sản phẩm trong đơn đã hoàn thành.
/// Pop trả [ProductReview] khi gửi thành công.
class ReviewFormScreen extends StatefulWidget {
  const ReviewFormScreen({
    super.key,
    required this.repository,
    required this.orderId,
    required this.productId,
    required this.productName,
  });

  final ProfileRepository repository;
  final String orderId;
  final String productId;
  final String productName;

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

/// Khớp giới hạn của backend và bucket `review-images`.
const _maxImages = 3;

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  final _comment = TextEditingController();
  final _images = <({Uint8List bytes, String contentType})>[];
  int _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
      limit: _maxImages - _images.length,
    );
    if (picked.isEmpty) return;
    final files = [
      for (final file in picked.take(_maxImages - _images.length))
        (
          bytes: await file.readAsBytes(),
          contentType: file.mimeType ?? 'image/jpeg',
        ),
    ];
    if (mounted) setState(() => _images.addAll(files));
  }

  Future<void> _submit() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);
    try {
      final urls = <String>[
        for (final image in _images)
          await widget.repository.uploadReviewImage(
            image.bytes,
            image.contentType,
          ),
      ];
      final comment = _comment.text.trim();
      final review = await widget.repository.createReview(
        orderId: widget.orderId,
        productId: widget.productId,
        rating: _rating,
        comment: comment.isEmpty ? null : comment,
        imageUrls: urls,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Cảm ơn bạn đã đánh giá!')),
      );
      navigator.pop(review);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(
        SnackBar(content: Text(profileErrorMessage(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CheckoutTheme(
      child: Scaffold(
        appBar: const FleureAppBar(title: 'Đánh giá sản phẩm', showProfile: false),
        body: CheckoutContent(
          children: <Widget>[
            Text(
              widget.productName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (var star = 1; star <= 5; star++)
                  IconButton(
                    key: Key('review-star-$star'),
                    iconSize: 36,
                    tooltip: '$star sao',
                    onPressed: () => setState(() => _rating = star),
                    icon: Icon(
                      star <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('review-comment'),
              controller: _comment,
              maxLength: 1000,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Nhận xét (không bắt buộc)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final (index, image) in _images.indexed)
                  Stack(
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          image.bytes,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: IconButton(
                          tooltip: 'Bỏ ảnh',
                          onPressed: _submitting
                              ? null
                              : () => setState(() => _images.removeAt(index)),
                          icon: const Icon(Icons.cancel, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                if (_images.length < _maxImages)
                  OutlinedButton.icon(
                    key: const Key('review-add-image'),
                    onPressed: _submitting ? null : _pickImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text('Thêm ảnh (${_images.length}/$_maxImages)'),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton(
              key: const Key('review-submit'),
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'Đang gửi...' : 'Gửi đánh giá'),
            ),
          ],
        ),
      ),
    );
  }
}
