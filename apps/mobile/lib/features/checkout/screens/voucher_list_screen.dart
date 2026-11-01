import 'package:flutter/material.dart';

import '../data/checkout_failure.dart';
import '../data/checkout_repository.dart';
import '../models/voucher.dart';
import '../utils/checkout_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/checkout_common.dart';

class VoucherListScreen extends StatefulWidget {
  const VoucherListScreen({
    super.key,
    required this.repository,
    this.currentVoucher,
  });

  final CheckoutRepository repository;
  final Voucher? currentVoucher;

  @override
  State<VoucherListScreen> createState() => _VoucherListScreenState();
}

class _VoucherListScreenState extends State<VoucherListScreen> {
  final _codeController = TextEditingController();
  bool _loading = true;
  bool _loadFailed = false;
  bool _validating = false;
  String? _validationError;
  List<Voucher> _vouchers = const <Voucher>[];

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadVouchers() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });

    try {
      final items = await widget.repository.availableVouchers();
      if (!mounted) return;
      setState(() {
        _vouchers = items;
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

  Future<void> _applyCustomCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || _validating) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _validating = true;
      _validationError = null;
    });

    try {
      final voucher = await widget.repository.validateVoucher(code);
      if (!mounted) return;
      Navigator.of(context).pop(voucher);
    } on CheckoutFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _validating = false;
        _validationError = _errorMessageForFailure(failure);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _validating = false;
        _validationError = 'Không thể áp dụng voucher lúc này. Vui lòng thử lại.';
      });
    }
  }

  String _errorMessageForFailure(CheckoutFailure failure) {
    return switch (failure.code) {
      CheckoutErrorCode.voucherNotFound => 'Mã voucher không tồn tại.',
      CheckoutErrorCode.voucherExpired => 'Voucher đã hết hạn.',
      CheckoutErrorCode.voucherUsageExceeded => 'Voucher đã hết lượt sử dụng.',
      CheckoutErrorCode.voucherMinOrderNotMet =>
        'Đơn hàng chưa đạt giá trị tối thiểu của voucher.',
      CheckoutErrorCode.network =>
        'Không kết nối được máy chủ. Vui lòng thử lại.',
      _ => 'Mã voucher không hợp lệ.',
    };
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  Widget _buildInputSection() {
    return CheckoutSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Mã giảm giá',
            style: TextStyle(
              color: CheckoutPalette.charcoal900,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: TextField(
                  key: const Key('voucher-code-input'),
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'Nhập mã voucher...',
                    prefixIcon: Icon(
                      Icons.local_offer_outlined,
                      size: 20,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (_) => _applyCustomCode(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: FilledButton(
                  key: const Key('voucher-apply-button'),
                  onPressed: _validating ? null : _applyCustomCode,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    minimumSize: const Size(80, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _validating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Áp dụng',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
          if (_validationError != null) ...[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.error_outline_rounded,
                  color: CheckoutPalette.error,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _validationError!,
                    style: const TextStyle(
                      color: CheckoutPalette.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoucherCard(Voucher voucher) {
    final eligible = voucher.eligible;
    final isSelected = widget.currentVoucher?.code == voucher.code;

    String discountText;
    if (voucher.type == 'PERCENT' && voucher.value != null) {
      discountText = 'Giảm ${voucher.value}%';
      if (voucher.maxDiscount != null) {
        discountText += ' (tối đa ${formatVnd(voucher.maxDiscount!)})';
      }
    } else if (voucher.type == 'FIXED' && voucher.value != null) {
      discountText = 'Giảm ${formatVnd(voucher.value!)}';
    } else {
      discountText = 'Giảm ${formatVnd(voucher.discountAmount)}';
    }

    final card = CheckoutSurfaceCard(
      key: Key('voucher-item-${voucher.code}'),
      borderColor: isSelected
          ? CheckoutPalette.forest
          : (eligible ? CheckoutPalette.cream300 : CheckoutPalette.cream200),
      color: isSelected
          ? CheckoutPalette.forest50
          : (eligible ? CheckoutPalette.surface : CheckoutPalette.field),
      onTap: eligible ? () => Navigator.of(context).pop(voucher) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: eligible
                      ? CheckoutPalette.petal100
                      : CheckoutPalette.cream200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_offer_rounded,
                  color: eligible
                      ? CheckoutPalette.petal500
                      : CheckoutPalette.charcoal400,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          voucher.code,
                          style: TextStyle(
                            color: eligible
                                ? CheckoutPalette.charcoal900
                                : CheckoutPalette.charcoal500,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const CheckoutStatusBadge(text: 'Đang chọn'),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      discountText,
                      style: TextStyle(
                        color: eligible
                            ? CheckoutPalette.petal500
                            : CheckoutPalette.charcoal500,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Đơn tối thiểu ${formatVnd(voucher.minOrderAmount)}',
                      style: const TextStyle(
                        color: CheckoutPalette.charcoal500,
                        fontSize: 11,
                      ),
                    ),
                    if (voucher.endsAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Hạn sử dụng: ${_formatDate(voucher.endsAt!)}',
                        style: const TextStyle(
                          color: CheckoutPalette.charcoal400,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (eligible)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: CheckoutPalette.charcoal400,
                ),
            ],
          ),
          if (!eligible && voucher.ineligibleReason != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: CheckoutPalette.errorSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.info_outline_rounded,
                    color: CheckoutPalette.error,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      voucher.ineligibleReason!,
                      style: const TextStyle(
                        color: CheckoutPalette.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    if (!eligible) {
      return Opacity(
        opacity: 0.55,
        child: card,
      );
    }
    return card;
  }

  Widget _buildListSection() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(color: CheckoutPalette.forest),
        ),
      );
    }

    if (_loadFailed) {
      return CheckoutSurfaceCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              color: CheckoutPalette.error,
              size: 36,
            ),
            const SizedBox(height: 12),
            const Text(
              'Không thể tải danh sách voucher.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CheckoutPalette.charcoal900,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadVouchers,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
              style: OutlinedButton.styleFrom(
                foregroundColor: CheckoutPalette.forest,
                side: const BorderSide(color: CheckoutPalette.forest),
              ),
            ),
          ],
        ),
      );
    }

    if (_vouchers.isEmpty) {
      return const CheckoutSurfaceCard(
        padding: EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Icon(
              Icons.confirmation_number_outlined,
              color: CheckoutPalette.charcoal400,
              size: 40,
            ),
            SizedBox(height: 12),
            Text(
              'Chưa có voucher khả dụng',
              style: TextStyle(
                color: CheckoutPalette.charcoal900,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Các mã ưu đãi mới sẽ xuất hiện ở đây hoặc bạn có thể nhập mã riêng ở trên.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CheckoutPalette.charcoal500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: <Widget>[
        for (var i = 0; i < _vouchers.length; i++) ...[
          _buildVoucherCard(_vouchers[i]),
          if (i < _vouchers.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CheckoutTheme(
      child: Scaffold(
        appBar: const FleureAppBar(title: 'Ưu đãi & Voucher'),
        body: CheckoutContent(
          children: <Widget>[
            _buildInputSection(),
            const SizedBox(height: 24),
            const CheckoutSectionHeader(
              title: 'Mã giảm giá có sẵn',
              subtitle: 'Chọn mã phù hợp nhất với đơn hoa của bạn.',
            ),
            const SizedBox(height: 12),
            _buildListSection(),
          ],
        ),
      ),
    );
  }
}
