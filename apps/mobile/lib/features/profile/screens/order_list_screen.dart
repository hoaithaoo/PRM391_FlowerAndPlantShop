import 'package:flutter/material.dart';

import '../../checkout/utils/checkout_theme.dart';
import '../../checkout/utils/currency_formatter.dart';
import '../../checkout/widgets/checkout_common.dart';
import '../data/profile_repository.dart';
import '../models/profile_models.dart';
import 'order_detail_screen.dart';

String formatOrderDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} '
      '${two(date.hour)}:${two(date.minute)}';
}

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key, required this.repository});

  final ProfileRepository repository;

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final _orders = <OrderSummary>[];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _reload() async {
    _orders.clear();
    _page = 0;
    _hasMore = true;
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final page = await widget.repository.listOrders(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _orders.addAll(page.items);
        _page++;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _open(OrderSummary order) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            OrderDetailScreen(repository: widget.repository, orderId: order.id),
      ),
    );
    if (changed == true && mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return CheckoutTheme(
      child: Scaffold(
        appBar: const FleureAppBar(
          title: 'Đơn hàng của tôi',
          showProfile: false,
        ),
        body: CheckoutContent(
          children: <Widget>[
            for (final order in _orders) ...[
              CheckoutSurfaceCard(
                key: Key('order-${order.id}'),
                onTap: () => _open(order),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            order.orderCode,
                            style: const TextStyle(
                              color: CheckoutPalette.charcoal900,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatOrderDate(order.createdAt),
                            style: const TextStyle(
                              color: CheckoutPalette.charcoal500,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatVnd(order.grandTotal),
                            style: const TextStyle(
                              color: CheckoutPalette.petal500,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CheckoutStatusBadge(text: order.statusLabel),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loadFailed)
              TextButton(
                onPressed: _loadMore,
                child: const Text('Không tải được đơn hàng. Chạm để thử lại.'),
              )
            else if (_orders.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Bạn chưa có đơn hàng nào.',
                  textAlign: TextAlign.center,
                ),
              )
            else if (_hasMore)
              TextButton(
                key: const Key('orders-load-more'),
                onPressed: _loadMore,
                child: const Text('Xem thêm'),
              ),
          ],
        ),
      ),
    );
  }
}
