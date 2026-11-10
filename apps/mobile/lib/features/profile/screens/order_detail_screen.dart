import 'package:flutter/material.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart' show ProductReview;

import '../../chatbot/models/chatbot_models.dart';
import '../../checkout/utils/checkout_theme.dart';
import '../../checkout/utils/currency_formatter.dart';
import '../../checkout/widgets/checkout_common.dart';
import '../data/profile_repository.dart';
import '../models/profile_models.dart';
import 'incident_report_screen.dart';
import 'order_list_screen.dart';
import 'review_form_screen.dart';

/// Pop trả `true` khi đơn vừa bị hủy để danh sách tải lại.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({
    super.key,
    required this.repository,
    required this.orderId,
  });

  final ProfileRepository repository;
  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderDetail? _order;
  bool _loadFailed = false;
  bool _cancelling = false;

  /// Đánh giá đã viết trong đơn này, theo productId.
  Map<String, ProductReview> _myReviews = const {};

  @override
  void initState() {
    super.initState();
    // Chatbot gửi kèm đơn đang xem để trả lời trạng thái / soạn phiếu sự cố đúng đơn.
    ChatbotRequestContext.viewingOrderId = widget.orderId;
    _load();
  }

  @override
  void dispose() {
    if (ChatbotRequestContext.viewingOrderId == widget.orderId) {
      ChatbotRequestContext.viewingOrderId = null;
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    try {
      final order = await widget.repository.getOrder(widget.orderId);
      if (mounted) setState(() => _order = order);
      if (order.status == 'COMPLETED') await _loadReviews();
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await widget.repository.listMyReviews(widget.orderId);
      if (!mounted) return;
      setState(() {
        _myReviews = {
          for (final review in reviews)
            if (review.productId != null) review.productId!: review,
        };
      });
    } catch (_) {
      // Không tải được thì vẫn hiện nút; backend chặn đánh giá trùng.
    }
  }

  Future<void> _review(OrderDetail order, OrderLine item) async {
    final review = await Navigator.of(context).push<ProductReview>(
      MaterialPageRoute<ProductReview>(
        builder: (_) => ReviewFormScreen(
          repository: widget.repository,
          orderId: order.id,
          productId: item.productId!,
          productName: item.name,
        ),
      ),
    );
    if (review != null && mounted) {
      setState(() => _myReviews = {..._myReviews, item.productId!: review});
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đơn hàng này?'),
        content: const Text('Đơn sẽ bị hủy và không khôi phục được.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Giữ đơn'),
          ),
          FilledButton(
            key: const Key('order-confirm-cancel'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _cancelling = true);
    try {
      await widget.repository.cancelOrder(widget.orderId);
      navigator.pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      messenger.showSnackBar(
        SnackBar(content: Text(profileErrorMessage(error))),
      );
    }
  }

  Widget _buildBody() {
    final order = _order;
    if (order == null) {
      return Center(
        child: _loadFailed
            ? TextButton(
                onPressed: _load,
                child: const Text('Không tải được đơn hàng. Chạm để thử lại.'),
              )
            : const CircularProgressIndicator(),
      );
    }
    final pickupAt = order.pickupAt;
    return CheckoutContent(
      children: <Widget>[
        CheckoutSurfaceCard(
          child: Column(
            children: <Widget>[
              CheckoutDetailRow(
                label: 'Mã đơn hàng',
                value: order.orderCode,
                icon: Icons.receipt_long_outlined,
              ),
              const SizedBox(height: 14),
              CheckoutDetailRow(
                label: 'Trạng thái',
                value: order.statusLabel,
                icon: Icons.local_shipping_outlined,
              ),
              const SizedBox(height: 14),
              CheckoutDetailRow(
                label: 'Ngày đặt',
                value: formatOrderDate(order.createdAt),
                icon: Icons.calendar_today_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        CheckoutSurfaceCard(
          child: Column(
            children: <Widget>[
              CheckoutDetailRow(
                label: 'Người nhận',
                value: '${order.receiverName} · ${order.phone}',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),
              CheckoutDetailRow(
                label: order.pickupStoreName == null ? 'Địa chỉ' : 'Nhận tại',
                value: order.pickupStoreName == null
                    ? order.address
                    : '${order.pickupStoreName}, ${order.address}',
                icon: Icons.location_on_outlined,
              ),
              if (pickupAt != null) ...[
                const SizedBox(height: 14),
                CheckoutDetailRow(
                  label: 'Thời gian nhận',
                  value: formatOrderDate(pickupAt),
                  icon: Icons.schedule_outlined,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        CheckoutSurfaceCard(
          child: Column(
            children: <Widget>[
              for (final item in order.items) ...[
                Row(
                  children: <Widget>[
                    Expanded(child: Text('${item.quantity} × ${item.name}')),
                    const SizedBox(width: 8),
                    Text(formatVnd(item.subtotal)),
                  ],
                ),
                if (order.status == 'COMPLETED' && item.productId != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: _myReviews[item.productId] == null
                        ? TextButton.icon(
                            key: Key('order-review-${item.productId}'),
                            onPressed: () => _review(order, item),
                            icon: const Icon(Icons.star_outline_rounded),
                            label: const Text('Đánh giá'),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Đã đánh giá '
                              '${_myReviews[item.productId]!.rating}★',
                              style: const TextStyle(
                                color: CheckoutPalette.petal500,
                              ),
                            ),
                          ),
                  ),
                const SizedBox(height: 10),
              ],
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text('Tổng thanh toán'),
                  Text(
                    formatVnd(order.grandTotal),
                    style: const TextStyle(
                      color: CheckoutPalette.petal500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        TextButton.icon(
          key: const Key('order-report-incident'),
          onPressed: () => Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (_) => IncidentReportFormScreen(
                repository: widget.repository,
                orderId: order.id,
                title: 'Sự cố đơn ${order.orderCode}',
              ),
            ),
          ),
          icon: const Icon(Icons.report_problem_outlined),
          label: const Text('Báo sự cố với đơn này'),
        ),
        if (order.canCancel) ...[
          const SizedBox(height: 22),
          OutlinedButton(
            key: const Key('order-cancel'),
            onPressed: _cancelling ? null : _cancel,
            child: Text(_cancelling ? 'Đang hủy đơn...' : 'Hủy đơn'),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CheckoutTheme(
      child: Scaffold(
        appBar: const FleureAppBar(title: 'Chi tiết đơn', showProfile: false),
        body: _buildBody(),
      ),
    );
  }
}
