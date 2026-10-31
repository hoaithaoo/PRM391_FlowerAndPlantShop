import 'package:flutter/material.dart';

import '../data/checkout_mock_data.dart';
import '../models/checkout_flow_models.dart';
import '../models/checkout_summary.dart';
import '../state/checkout_flow_controller.dart';
import '../utils/checkout_theme.dart';
import '../utils/checkout_validators.dart';
import '../widgets/checkout_common.dart';
import 'order_success_screen.dart';
import 'pickup_branch_screen.dart';
import 'sepay_qr_screen.dart';

class PickupCheckoutScreen extends StatefulWidget {
  const PickupCheckoutScreen({
    super.key,
    required this.controller,
    required this.summary,
  });

  final CheckoutFlowController controller;
  final CheckoutSummary summary;

  @override
  State<PickupCheckoutScreen> createState() => _PickupCheckoutScreenState();
}

class _PickupCheckoutScreenState extends State<PickupCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _noteController;
  bool _submitting = false;
  bool _scheduleTouched = false;
  bool _paymentTouched = false;
  String? _dateError;
  String? _timeError;
  String? _branchError;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.controller.pickupNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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
              for (final time in CheckoutMockData.pickupTimeSlots)
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
      _timeError = CheckoutValidators.pickupTime(
        selected,
        CheckoutMockData.pickupTimeSlots,
      );
    });
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _scheduleTouched = true;
      _paymentTouched = true;
      _branchError = CheckoutValidators.selectedBranch(
        widget.controller.selectedBranch,
      );
      _dateError = CheckoutValidators.pickupDate(widget.controller.pickupDate);
      _timeError = CheckoutValidators.pickupTime(
        widget.controller.pickupTime,
        CheckoutMockData.pickupTimeSlots,
      );
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
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _submitting = false);

    if (widget.controller.pickupPaymentMethod == LocalPaymentMethod.sepay) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => SepayQrScreen(
            controller: widget.controller,
            summary: widget.summary,
            isPickup: true,
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => OrderSuccessScreen(
          controller: widget.controller,
          summary: widget.summary,
          isPickup: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branch = widget.controller.selectedBranch;
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
                  onPressed: _selectBranch,
                  child: const Text('Thay đổi'),
                ),
              ),
              const SizedBox(height: 12),
              CheckoutSurfaceCard(
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
              ),
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
                        value:
                            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
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
          label: 'Đặt đơn và lấy tại quán',
          onPressed: _submit,
          loading: _submitting,
        ),
      ),
    );
  }
}
