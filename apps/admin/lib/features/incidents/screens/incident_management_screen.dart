import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';
import '../../../core/network/admin_api_client.dart';

/// Danh sách phiếu sự cố khách gửi; admin lọc, xem và cập nhật trạng thái.
class IncidentManagementScreen extends StatefulWidget {
  const IncidentManagementScreen({super.key});

  @override
  State<IncidentManagementScreen> createState() =>
      _IncidentManagementScreenState();
}

class _IncidentManagementScreenState extends State<IncidentManagementScreen> {
  final _searchController = TextEditingController();
  final _dateFormat = DateFormat('HH:mm - dd/MM/yyyy');
  String? _status;
  String? _category;
  List<IncidentModel>? _items;
  String? _error;

  AdminIncidentsService get _service =>
      context.read<AdminApiClient>().incidents;

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

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final items = await _service.getIncidents(
        status: _status,
        category: _category,
        search: _searchController.text.trim(),
      );
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  static Color statusColor(String status) => switch (status) {
        'OPEN' => AppColors.statusPending,
        'IN_PROGRESS' => AppColors.statusProcessing,
        'RESOLVED' => AppColors.statusDelivered,
        _ => AppColors.statusCancelled,
      };

  Future<void> _openDetail(IncidentModel item) async {
    final updated = await showDialog<IncidentModel>(
      context: context,
      builder: (_) => _IncidentDialog(item: item, service: _service),
    );
    if (updated != null) _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quản lý phiếu sự cố',
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
                hintText: 'Tìm mã phiếu, tiêu đề, mã đơn, email...',
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
                  child: _FilterDropdown(
                    label: 'Trạng thái',
                    value: _status,
                    options: incidentStatusLabels,
                    onChanged: (v) {
                      _status = v;
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FilterDropdown(
                    label: 'Loại sự cố',
                    value: _category,
                    options: incidentCategoryLabels,
                    onChanged: (v) {
                      _category = v;
                      _load();
                    },
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
                      child: Text('Lỗi tải phiếu: $_error\nChạm để thử lại.',
                          textAlign: TextAlign.center),
                    ),
                  )
                : items == null
                    ? const Center(child: CircularProgressIndicator())
                    : items.isEmpty
                        ? const Center(child: Text('Không có phiếu sự cố nào.'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: items.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) => _IncidentTile(
                                item: items[i],
                                date: _dateFormat.format(items[i].createdAt),
                                onTap: () => _openDetail(items[i]),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final Map<String, String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: [
        const DropdownMenuItem(child: Text('Tất cả')),
        for (final e in options.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value)),
      ],
      onChanged: onChanged,
    );
  }
}

class _IncidentTile extends StatelessWidget {
  const _IncidentTile({
    required this.item,
    required this.date,
    required this.onTap,
  });

  final IncidentModel item;
  final String date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _IncidentManagementScreenState.statusColor(item.status);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        title: Text(
          item.title,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          '${item.code} · ${item.categoryLabel}\n'
          '${item.customerName ?? item.customerEmail ?? 'Khách'}'
          '${item.orderCode == null ? '' : ' · Đơn ${item.orderCode}'} · $date',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        isThreeLine: true,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            item.statusLabel,
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Xem chi tiết phiếu, đổi trạng thái và ghi phản hồi cho khách.
class _IncidentDialog extends StatefulWidget {
  const _IncidentDialog({required this.item, required this.service});

  final IncidentModel item;
  final AdminIncidentsService service;

  @override
  State<_IncidentDialog> createState() => _IncidentDialogState();
}

class _IncidentDialogState extends State<_IncidentDialog> {
  late String _status = widget.item.status;
  late final _note = TextEditingController(text: widget.item.adminNote);
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final updated = await widget.service.updateIncident(
        widget.item.id,
        status: _status,
        adminNote: _note.text.trim(),
      );
      navigator.pop(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Lưu thất bại: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final contact = [item.customerName, item.customerEmail, item.customerPhone]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' · ');
    return AlertDialog(
      title: Text(item.code),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text('Loại: ${item.categoryLabel}'),
              if (item.orderCode != null) Text('Đơn hàng: ${item.orderCode}'),
              if (contact.isNotEmpty) Text('Khách: $contact'),
              const SizedBox(height: 10),
              Text(item.description),
              const Divider(height: 28),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
                items: [
                  for (final e in incidentStatusLabels.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                maxLength: 2000,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Phản hồi cho khách',
                  hintText: 'VD: Shop sẽ giao bù bó hoa mới trong hôm nay.',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Đang lưu...' : 'Lưu'),
        ),
      ],
    );
  }
}
