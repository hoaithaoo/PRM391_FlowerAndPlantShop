import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

/// Ô nhập số lượng, kẹp trong khoảng 1 đến [max].
///
/// Mặc định chỉ báo [onChanged] khi rời ô hoặc bấm xong để không gọi API theo
/// từng phím. [live] báo ngay từng số hợp lệ, dùng khi giá trị chỉ nằm trên máy.
class QuantityInput extends StatefulWidget {
  const QuantityInput({
    super.key,
    required this.value,
    required this.max,
    required this.onChanged,
    this.enabled = true,
    this.live = false,
    this.width = 40,
    this.semanticLabel = 'Số lượng',
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final bool live;
  final double width;
  final String semanticLabel;

  @override
  State<QuantityInput> createState() => _QuantityInputState();
}

class _QuantityInputState extends State<QuantityInput> {
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.value}',
  );
  final _focusNode = FocusNode();

  int get _upperBound => widget.max < 1 ? 1 : widget.max;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(QuantityInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _commit();
  }

  void _commit() {
    final parsed = int.tryParse(_controller.text) ?? widget.value;
    final next = parsed.clamp(1, _upperBound);
    _controller.text = '$next';
    if (next != widget.value) widget.onChanged(next);
  }

  void _onTextChanged(String text) {
    if (!widget.live) return;
    final parsed = int.tryParse(text);
    if (parsed != null && parsed >= 1 && parsed <= _upperBound) {
      widget.onChanged(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Semantics(
        label: widget.semanticLabel,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          onChanged: _onTextChanged,
          onSubmitted: (_) => _commit(),
          style: AppTextStyles.body.copyWith(
            color: widget.enabled ? AppColors.textHeading : AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
          decoration: const InputDecoration(
            isCollapsed: true,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
