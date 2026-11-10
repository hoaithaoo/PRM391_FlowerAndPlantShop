import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';
import '../../../core/network/admin_api_client.dart';

/// FAQ chatbot dùng để trả lời chính sách cửa hàng: admin thêm, sửa, bật/tắt, xóa.
class FaqManagementScreen extends StatefulWidget {
  const FaqManagementScreen({super.key});

  @override
  State<FaqManagementScreen> createState() => _FaqManagementScreenState();
}

class _FaqManagementScreenState extends State<FaqManagementScreen> {
  List<AdminFaq>? _items; // null = đang tải lần đầu
  String? _error;

  AdminFaqsService get _service => context.read<AdminApiClient>().faqs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final items = await _service.getFaqs();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  /// Chạy một thao tác (thêm/sửa/xóa/bật tắt), xong thì tải lại danh sách; lỗi hiện SnackBar.
  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  /// Mở dialog thêm (faq == null) hoặc sửa. Câu mới mặc định thứ tự = lớn nhất + 10 để nằm cuối.
  Future<void> _edit([AdminFaq? faq]) async {
    final maxOrder = (_items ?? const <AdminFaq>[])
        .fold<int>(0, (max, e) => e.sortOrder > max ? e.sortOrder : max);
    final result = await showDialog<AdminFaq>(
      context: context,
      builder: (_) => _FaqDialog(faq: faq, defaultSortOrder: maxOrder + 10),
    );
    if (result == null) return;
    await _run(() => faq == null ? _service.createFaq(result) : _service.updateFaq(result));
  }

  Future<void> _delete(AdminFaq faq) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa câu hỏi?'),
        content: Text('"${faq.topic}" sẽ bị xóa, chatbot không dùng nữa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) await _run(() => _service.deleteFaq(faq.id));
  }

  /// Bật/tắt nhanh: câu đang tắt thì chatbot không dùng nhưng vẫn giữ để bật lại.
  Future<void> _toggle(AdminFaq faq, bool isActive) => _run(() => _service.updateFaq(AdminFaq(
        id: faq.id,
        topic: faq.topic,
        answer: faq.answer,
        sortOrder: faq.sortOrder,
        isActive: isActive,
      )));

  Widget _body() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }
    final items = _items;
    if (items == null) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: items.isEmpty
          ? ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Chưa có câu hỏi nào. Chatbot sẽ không trả lời được câu hỏi về chính sách cửa hàng.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted),
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _FaqCard(
                faq: items[i],
                onEdit: () => _edit(items[i]),
                onDelete: () => _delete(items[i]),
                onToggle: (value) => _toggle(items[i], value),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FAQ chatbot',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm câu hỏi'),
      ),
      body: _body(),
    );
  }
}

/// Một thẻ FAQ: chủ đề + công tắc bật/tắt + nút xóa; chạm vào thẻ để sửa.
class _FaqCard extends StatelessWidget {
  const _FaqCard({
    required this.faq,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final AdminFaq faq;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      faq.topic,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: faq.isActive ? AppColors.textHeading : AppColors.textMuted,
                      ),
                    ),
                  ),
                  Switch(value: faq.isActive, onChanged: onToggle),
                  IconButton(
                    tooltip: 'Xóa',
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: onDelete,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  faq.answer,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textBody),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Form thêm/sửa FAQ. Trả về AdminFaq qua Navigator.pop; bấm Hủy thì trả null.
/// Câu mới có id rỗng; _edit() dựa vào faq == null để gọi createFaq thay vì updateFaq.
class _FaqDialog extends StatefulWidget {
  const _FaqDialog({this.faq, required this.defaultSortOrder});

  final AdminFaq? faq;
  final int defaultSortOrder;

  @override
  State<_FaqDialog> createState() => _FaqDialogState();
}

class _FaqDialogState extends State<_FaqDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _topic = TextEditingController(text: widget.faq?.topic);
  late final _answer = TextEditingController(text: widget.faq?.answer);
  late final _order =
      TextEditingController(text: '${widget.faq?.sortOrder ?? widget.defaultSortOrder}');
  late bool _active = widget.faq?.isActive ?? true;

  @override
  void dispose() {
    _topic.dispose();
    _answer.dispose();
    _order.dispose();
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Không được để trống' : null;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      AdminFaq(
        id: widget.faq?.id ?? '',
        topic: _topic.text.trim(),
        answer: _answer.text.trim(),
        sortOrder: int.tryParse(_order.text) ?? 0,
        isActive: _active,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.faq == null ? 'Thêm câu hỏi' : 'Sửa câu hỏi'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _topic,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'Chủ đề (vd: Phí giao hàng)'),
                  validator: _required,
                ),
                TextFormField(
                  controller: _answer,
                  maxLength: 2000,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Câu trả lời',
                    helperText: 'Chatbot chỉ trả lời đúng nội dung này.',
                  ),
                  validator: _required,
                ),
                TextFormField(
                  controller: _order,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Thứ tự (nhỏ đứng trước)'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Chatbot đang dùng'),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: _save, child: const Text('Lưu')),
      ],
    );
  }
}
