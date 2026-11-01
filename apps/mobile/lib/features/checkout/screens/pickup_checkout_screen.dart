import 'package:flutter/material.dart';

import '../data/checkout_repository.dart';
import '../models/checkout_flow_models.dart';
import '../models/checkout_request.dart';
import '../models/checkout_summary.dart';
import '../models/payment_method.dart';
import '../state/checkout_flow_controller.dart';
import '../utils/checkout_theme.dart';
import '../utils/checkout_validators.dart';
import '../widgets/checkout_common.dart';
import 'pickup_branch_screen.dart';

class PickupCheckoutScreen extends StatefulWidget {
  const PickupCheckoutScreen({
    super.key,
    required this.controller,
    required this.summary,
    required this.repository,
    required this.onPlaceOrder,
    this.voucherCode,
  });

  final CheckoutFlowController controller;
  final CheckoutSummary summary;
  final CheckoutRepository repository;
  final String? voucherCode;

  /// Màn checkout gửi đơn và điều hướng. [branch] là cửa hàng dưới dạng địa chỉ
  /// để các màn kết quả dùng chung; [pickupTime] là chuỗi hiển thị cho khách.
  final Future<void> Function(
    CheckoutRequest request,
    CheckoutAddress branch,
    String pickupTime,
  )
  onPlaceOrder;

  @override
  State<PickupCheckoutScreen> createState() => _PickupCheckoutScreenState();
}

class _PickupCheckoutScreenState extends State<PickupCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _noteController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _submitting = false;
  bool _loadingBranches = true;
  bool _branchLoadFailed = false;
  bool _scheduleTouched = false;
  bool _paymentTouched = false;
  String? _dateError;
  String? _timeError;
  String? _branchError;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.controller.pickupNote);
    final address = widget.controller.selectedAddress;
    _nameController = TextEditingController(text: address?.recipientName);
    _phoneController = TextEditingController(text: address?.normalizedPhone);
    _loadBranches();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    setState(() {
      _loadingBranches = true;
      _branchLoadFailed = false;
    });
    final address = widget.controller.selectedAddress;
    try {
      final branches = await widget.repository.listStores(
        latitude: address?.latitude,
        longitude: address?.longitude,
      );
      if (!mounted) return;
      widget.controller.setBranches(branches);
      setState(() {
        _loadingBranches = false;
        _branchLoadFailed = branches.isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingBranches = false;
        _branchLoadFailed = true;
      });
    }
  }

  Future<void> _selectBranch() async {
    await Navigator.of(context).push<PickupBranch>(
      MaterialPageRoute<PickupBranch>(
        builder: (_) => PickupBranchScreen(controller: widget.controller),
      ),
    );
    if (mounted) {
      setState(() {
        _branchError = CheckoutValidators.selectedBranch(
          widget.controller.selectedBranch,
        );
      });
    }
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: widget.controller.pickupDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: 'Chọn ngày nhận hoa',
      cancelText: 'Hủy',
      confirmText: 'Chọn ngày',
    );
    if (selected == null || !mounted) return;
    widget.controller.setPickupSchedule(selected, widget.controller.pickupTime);
    setState(() {
      _scheduleTouched = true;
      _dateError = CheckoutValidators.pickupDate(selected);
    });
  }

  Future<void> _selectTime() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: CheckoutPalette.creamPastel,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Chọn khung giờ nhận hoa',
                style: CheckoutTypography.section,
              ),
              const SizedBox(height: 14),
              for (final time in pickupTimeSlots)
                ListTile(
                  title: Text(time),
                  trailing: time == widget.controller.pickupTime
                      ? const Icon(
                          Icons.check_circle,
                          color: CheckoutPalette.forest700,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(time),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    widget.controller.setPickupSchedule(widget.controller.pickupDate, selected);
    setState(() {
      _scheduleTouched = true;
      _timeError = CheckoutValidators.pickupTime(selected, pickupTimeSlots);
    });
  }

  /// Giờ bắt đầu của khung đã chọn, ví dụ `15:00 – 16:00` là 15:00.
  DateTime get _pickupAt {
    final date = widget.controller.pickupDate;
    final start = widget.controller.pickupTime.substring(0, 5).split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(start[0]),
      int.parse(start[1]),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _submit() async {
    if (_submitting) return;
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _scheduleTouched = true;
      _paymentTouched = true;
      _branchError = CheckoutValidators.selectedBranch(
        widget.controller.selectedBranch,
      );
      _dateError = CheckoutValidators.pickupDate(widget.controller.pickupDate);
      _timeError =
          CheckoutValidators.pickupTime(
            widget.controller.pickupTime,
            pickupTimeSlots,
          ) ??
          (_pickupAt.isAfter(DateTime.now())
              ? null
              : 'Khung giờ này đã qua. Vui lòng chọn giờ khác.');
    });
    if (!valid ||
        _branchError != null ||
        _dateError != null ||
        _timeError != null ||
        CheckoutValidators.selectedPayment(
              widget.controller.pickupPaymentMethod,
            ) !=
            null) {
      return;
    }
    FocusScope.of(context).unfocus();
    widget.controller.pickupNote = CheckoutValidators.normalizeOptionalText(
      _noteController.text,
    );
    final branch = widget.controller.selectedBranch!;
    final destination = CheckoutAddress(
      id: branch.id,
      label: 'Nhận tại quán',
      recipientName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      addressLine: '${branch.name}, ${branch.address}',
      ward: '',
      district: '',
      city: '',
    );
    setState(() => _submitting = true);
    await widget.onPlaceOrder(
      CheckoutRequest(
        receiverName: destination.recipientName,
        phone: destination.normalizedPhone,
        paymentMethod:
            widget.controller.pickupPaymentMethod == LocalPaymentMethod.sepay
            ? PaymentMethod.sepay
            : PaymentMethod.cod,
        note: widget.controller.pickupNote,
        voucherCode: widget.voucherCode,
        pickupStoreId: branch.id,
        pickupAt: _pickupAt,
      ),
      destination,
      '${widget.controller.pickupTime}, ${_formatDate(widget.controller.pickupDate)}',
    );
    if (mounted) setState(() => _submitting = false);
  }

  Widget _buildBranchCard() {
    final branch = widget.controller.selectedBranch;
    if (_loadingBranches) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_branchLoadFailed || branch == null) {
      return CheckoutSurfaceCard(
        key: const Key('pickup-branch-retry'),
        onTap: _loadBranches,
        child: const Text('Không tải được danh sách cửa hàng. Chạm để thử lại.'),
      );
    }
    return CheckoutSurfaceCard(
      onTap: _selectBranch,
      borderColor: CheckoutPalette.forest100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CheckoutAssetImage(
            asset: branch.imageAsset,
            width: 78,
            height: 92,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  branch.name,
                  style: const TextStyle(
                    color: CheckoutPalette.charcoal900,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  branch.address,
                  style: const TextStyle(
                    color: CheckoutPalette.charcoal500,
                    fontSize: 10.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  branch.readyTime,
                  style: const TextStyle(
                    color: CheckoutPalette.forest700,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.controller.pickupDate;
    final pickupTotal = widget.summary.grandTotal - widget.summary.shippingFee;
    return CheckoutTheme(
      child: Scaffold(
        appBar: const FleureAppBar(title: 'Thanh toán · Lấy tại quán'),
        body: Form(
          key: _formKey,
          child: CheckoutContent(
            bottom: 128,
            children: <Widget>[
              FulfillmentSwitch(
                value: FulfillmentMode.pickup,
                onChanged: (value) {
                  if (value == FulfillmentMode.delivery) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(height: 24),
              CheckoutSectionHeader(
                title: 'Studio nhận hoa',
                subtitle: 'Ghé nhận tác phẩm khi đã được hoàn thiện.',
                trailing: TextButton(
                  onPressed: _loadingBranches ? null : _selectBranch,
                  child: const Text('Thay đổi'),
                ),
              ),
              const SizedBox(height: 12),
              _buildBranchCard(),
              if (_branchError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _branchError!,
                  style: const TextStyle(
                    color: CheckoutPalette.error,
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const CheckoutInfoBanner(
                icon: Icons.shopping_bag_outlined,
                title: 'Trải nghiệm nhận hoa tại studio',
                message:
                    'Nhân viên sẽ kiểm tra lần cuối và hướng dẫn cách chăm hoa trước khi bạn mang về.',
              ),
              const SizedBox(height: 26),
              const CheckoutSectionHeader(
                title: 'Người nhận hoa',
                subtitle: 'Fleuré liên hệ số này khi hoa đã sẵn sàng.',
              ),
              const SizedBox(height: 12),
              LabeledCheckoutField(
                label: 'Họ và tên',
                controller: _nameController,
                validator: CheckoutValidators.recipientName,
              ),
              const SizedBox(height: 14),
              LabeledCheckoutField(
                label: 'Số điện thoại',
                controller: _phoneController,
                validator: CheckoutValidators.vietnamesePhone,
              ),
              const SizedBox(height: 26),
              const CheckoutSectionHeader(
                title: 'Thời gian ghé nhận',
                subtitle: 'Chọn khung giờ để Fleuré chuẩn bị chu đáo.',
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: CheckoutSurfaceCard(
                      onTap: _selectDate,
                      child: CheckoutDetailRow(
                        label: 'Ngày nhận',
                        value: _formatDate(date),
                        icon: Icons.calendar_today_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CheckoutSurfaceCard(
                      onTap: _selectTime,
                      child: CheckoutDetailRow(
                        label: 'Khung giờ',
                        value: widget.controller.pickupTime,
                        icon: Icons.schedule_outlined,
                      ),
                    ),
                  ),
                ],
              ),
              if (_scheduleTouched &&
                  (_dateError != null || _timeError != null)) ...[
                const SizedBox(height: 8),
                Text(
                  _dateError ?? _timeError!,
                  style: const TextStyle(
                    color: CheckoutPalette.error,
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 26),
              const CheckoutSectionHeader(
                title: 'Tác phẩm của bạn',
                subtitle: 'Sẵn sàng được trao tận tay tại studio.',
              ),
              const SizedBox(height: 12),
              CheckoutSurfaceCard(
                child: Column(
                  children: <Widget>[
                    for (
                      var index = 0;
                      index < widget.summary.items.length;
                      index++
                    ) ...[
                      CheckoutProductTile(item: widget.summary.items[index]),
                      if (index < widget.summary.items.length - 1)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const CheckoutSectionHeader(
                title: 'Lời nhắn cho nghệ nhân',
                subtitle: 'Tùy chọn, tối đa 240 ký tự.',
              ),
              const SizedBox(height: 12),
              LabeledCheckoutField(
                label: 'Ghi chú khi nhận hoa',
                controller: _noteController,
                hint: 'Ví dụ: giữ lại giấy gói, thêm thiệp trắng...',
                maxLines: 3,
                maxLength: 240,
                showCounter: true,
                validator: (value) =>
                    CheckoutValidators.limitedNote(value, maxLength: 240),
              ),
              const SizedBox(height: 26),
              const CheckoutSectionHeader(
                title: 'Phương thức thanh toán',
                subtitle: 'Thanh toán trước hoặc khi ghé studio.',
              ),
              const SizedBox(height: 12),
              PaymentOptionCard(
                method: LocalPaymentMethod.payAtStore,
                selected:
                    widget.controller.pickupPaymentMethod ==
                    LocalPaymentMethod.payAtStore,
                onTap: () => setState(
                  () => widget.controller.setPickupPayment(
                    LocalPaymentMethod.payAtStore,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              PaymentOptionCard(
                method: LocalPaymentMethod.sepay,
                selected:
                    widget.controller.pickupPaymentMethod ==
                    LocalPaymentMethod.sepay,
                onTap: () => setState(
                  () => widget.controller.setPickupPayment(
                    LocalPaymentMethod.sepay,
                  ),
                ),
              ),
              if (_paymentTouched &&
                  CheckoutValidators.selectedPayment(
                        widget.controller.pickupPaymentMethod,
                      ) !=
                      null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Vui lòng chọn phương thức thanh toán.',
                  style: TextStyle(color: CheckoutPalette.error, fontSize: 11),
                ),
              ],
              const SizedBox(height: 26),
              PriceSummaryCard(summary: widget.summary, pickup: true),
            ],
          ),
        ),
        bottomNavigationBar: CheckoutStickyBar(
          total: pickupTotal,
          key: const Key('pickup-place-order'),
          label: 'Đặt đơn và lấy tại quán',
          onPressed: _loadingBranches ? null : _submit,
          loading: _submitting,
        ),
      ),
    );
  }
}
