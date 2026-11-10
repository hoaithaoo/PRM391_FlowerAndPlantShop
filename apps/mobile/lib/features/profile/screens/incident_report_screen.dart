import 'package:flutter/material.dart';

import '../../checkout/utils/checkout_theme.dart';
import '../../checkout/widgets/checkout_common.dart';
import '../data/profile_repository.dart';
import '../models/profile_models.dart';
import 'order_list_screen.dart';

/// Form gửi phiếu báo sự cố. Pop trả `true` khi gửi thành công.
class IncidentReportFormScreen extends StatefulWidget {
  const IncidentReportFormScreen({
    super.key,
    required this.repository,
    this.category,
    this.title,
    this.description,
    this.orderId,
  });

  final ProfileRepository repository;

  /// Giá trị điền sẵn, ví dụ từ bản nháp của chatbot hoặc màn chi tiết đơn.
  final String? category;
  final String? title;
  final String? description;
  final String? orderId;

  @override
  State<IncidentReportFormScreen> createState() =>
      _IncidentReportFormScreenState();
}

class _IncidentReportFormScreenState extends State<IncidentReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.title);
  late final _description = TextEditingController(text: widget.description);
  late String _category = incidentCategoryLabels.containsKey(widget.category)
      ? widget.category!
      : 'OTHER';
  late String? _orderId = widget.orderId;
  List<OrderSummary> _orders = const <OrderSummary>[];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      final page = await widget.repository.listOrders();
      if (mounted) setState(() => _orders = page.items);
    } catch (_) {
      // Không có danh sách đơn thì vẫn gửi phiếu được, chỉ không chọn đơn.
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);
    try {
      final report = await widget.repository.createIncident(
        category: _category,
        title: _title.text.trim(),
        description: _description.text.trim(),
        orderId: _orderId,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Đã gửi phiếu ${report.code}.')),
      );
      navigator.pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(
        SnackBar(content: Text(profileErrorMessage(error))),
      );
    }
  }

  String? _length(String? value, int min, int max) {
    final length = value?.trim().length ?? 0;
    if (length < min) return 'Nhập ít nhất $min ký tự.';
    if (length > max) return 'Tối đa $max ký tự.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Đơn điền sẵn có thể nằm ngoài trang đầu, vẫn giữ để không mất liên kết.
    final orderIds = <String>{
      for (final order in _orders) order.id,
      ?widget.orderId,
    };
    return CheckoutTheme(
      child: Scaffold(
        appBar: const FleureAppBar(title: 'Báo sự cố', showProfile: false),
        body: Form(
          key: _formKey,
          child: CheckoutContent(
            children: <Widget>[
              DropdownButtonFormField<String>(
                key: const Key('incident-category'),
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Loại sự cố'),
                items: <DropdownMenuItem<String>>[
                  for (final entry in incidentCategoryLabels.entries)
                    DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                ],
                onChanged: (value) => setState(() => _category = value!),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String?>(
                key: const Key('incident-order'),
                initialValue: _orderId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Đơn hàng liên quan (không bắt buộc)',
                ),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem(child: Text('Không gắn đơn hàng')),
                  for (final id in orderIds)
                    DropdownMenuItem(
                      value: id,
                      child: Text(_orderLabel(id)),
                    ),
                ],
                onChanged: (value) => setState(() => _orderId = value),
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('incident-title'),
                controller: _title,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Tiêu đề'),
                validator: (value) => _length(value, 3, 120),
              ),
              const SizedBox(height: 6),
              TextFormField(
                key: const Key('incident-description'),
                controller: _description,
                maxLength: 2000,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Mô tả chi tiết',
                  alignLabelWithHint: true,
                ),
                validator: (value) => _length(value, 10, 2000),
              ),
              const SizedBox(height: 18),
              FilledButton(
                key: const Key('incident-submit'),
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? 'Đang gửi...' : 'Gửi phiếu'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _orderLabel(String id) {
    final order = _orders.where((order) => order.id == id).firstOrNull;
    if (order == null) return 'Đơn đang xem';
    return '${order.orderCode} · ${formatOrderDate(order.createdAt)}';
  }
}

/// Danh sách phiếu sự cố của khách và trạng thái xử lý.
class IncidentListScreen extends StatefulWidget {
  const IncidentListScreen({super.key, required this.repository});

  final ProfileRepository repository;

  @override
  State<IncidentListScreen> createState() => _IncidentListScreenState();
}

class _IncidentListScreenState extends State<IncidentListScreen> {
  List<IncidentReport>? _reports;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    try {
      final reports = await widget.repository.listIncidents();
      if (mounted) setState(() => _reports = reports);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            IncidentReportFormScreen(repository: widget.repository),
      ),
    );
    if (created == true) _load();
  }

  Widget _buildBody() {
    final reports = _reports;
    if (reports == null) {
      return Center(
        child: _loadFailed
            ? TextButton(
                onPressed: _load,
                child: const Text('Không tải được phiếu. Chạm để thử lại.'),
              )
            : const CircularProgressIndicator(),
      );
    }
    if (reports.isEmpty) {
      return const Center(child: Text('Bạn chưa gửi phiếu sự cố nào.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
        itemCount: reports.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _IncidentCard(report: reports[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CheckoutTheme(
      child: Scaffold(
        appBar: const FleureAppBar(title: 'Phiếu sự cố', showProfile: false),
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('incident-create'),
          onPressed: _create,
          icon: const Icon(Icons.add),
          label: const Text('Báo sự cố'),
        ),
        body: _buildBody(),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.report});

  final IncidentReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = report.adminNote;
    return CheckoutSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  report.code,
                  style: theme.textTheme.labelLarge,
                ),
              ),
              Text(
                report.statusLabel,
                style: TextStyle(
                  color: switch (report.status) {
                    'RESOLVED' => Colors.green.shade700,
                    'REJECTED' => Colors.red.shade700,
                    _ => CheckoutPalette.petal500,
                  },
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(report.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '${report.categoryLabel}'
            '${report.orderCode == null ? '' : ' · Đơn ${report.orderCode}'}'
            ' · ${formatOrderDate(report.createdAt)}',
            style: theme.textTheme.bodySmall,
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Phản hồi: $note'),
          ],
        ],
      ),
    );
  }
}
