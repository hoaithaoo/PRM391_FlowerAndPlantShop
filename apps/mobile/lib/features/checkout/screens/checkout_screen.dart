import 'package:flutter/material.dart';

import '../data/checkout_mock_data.dart';
import '../data/checkout_repository.dart';
import '../data/mock_checkout_repository.dart';
import '../models/checkout_flow_models.dart';
import '../models/checkout_result.dart';
import '../models/checkout_summary.dart';
import '../state/checkout_flow_controller.dart';
import '../utils/checkout_theme.dart';
import '../utils/checkout_validators.dart';
import '../widgets/checkout_common.dart';
import 'address_list_screen.dart';
import 'order_success_screen.dart';
import 'pickup_checkout_screen.dart';
import 'sepay_qr_screen.dart';

typedef CheckoutSuccessHandler =
    void Function(BuildContext context, CheckoutResult result);

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.repository,
    required this.summary,
    this.flowController,
    this.onCheckoutSuccess,
  });

  factory CheckoutScreen.withMockData({
    Key? key,
    CheckoutSummary summary = CheckoutMockData.summary,
    CheckoutFlowController? flowController,
    CheckoutSuccessHandler? onCheckoutSuccess,
  }) {
    return CheckoutScreen(
      key: key,
      repository: MockCheckoutRepository(summary: summary),
      summary: summary,
      flowController: flowController,
      onCheckoutSuccess: onCheckoutSuccess,
    );
  }

  final CheckoutRepository repository;
  final CheckoutSummary summary;
  final CheckoutFlowController? flowController;
  final CheckoutSuccessHandler? onCheckoutSuccess;

  static const CheckoutSummary mockCheckoutSummary = CheckoutMockData.summary;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final CheckoutFlowController _flowController;
  late final bool _ownsController;
  late final TextEditingController _orderNoteController;
  late final TextEditingController _cardMessageController;
  bool _priorityDelivery = true;
  bool _submitting = false;
  bool _paymentTouched = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.flowController == null;
    _flowController = widget.flowController ?? CheckoutFlowController();
    _orderNoteController = TextEditingController(
      text: _flowController.deliveryNote,
    );
    _cardMessageController = TextEditingController(
      text: _flowController.cardMessage,
    );
  }

  @override
  void dispose() {
    _orderNoteController.dispose();
    _cardMessageController.dispose();
    if (_ownsController) _flowController.dispose();
    super.dispose();
  }

  Future<void> _openAddressBook() async {
    await Navigator.of(context).push<CheckoutAddress>(
      MaterialPageRoute<CheckoutAddress>(
        builder: (_) => AddressListScreen(controller: _flowController),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openPickup() async {
    _flowController.setFulfillmentMode(FulfillmentMode.pickup);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PickupCheckoutScreen(
          controller: _flowController,
          summary: widget.summary,
        ),
      ),
    );
    if (!mounted) return;
    _flowController.setFulfillmentMode(FulfillmentMode.delivery);
    setState(() {});
  }

  Future<void> _placeOrder() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    setState(() => _paymentTouched = true);
    final addressError = CheckoutValidators.selectedAddress(
      _flowController.selectedAddress,
    );
    final paymentError = CheckoutValidators.selectedPayment(
      _flowController.deliveryPaymentMethod,
    );
    if (!formValid || addressError != null || paymentError != null) return;

    FocusScope.of(context).unfocus();
    _flowController.deliveryNote = CheckoutValidators.normalizeOptionalText(
      _orderNoteController.text,
    );
    _flowController.cardMessage = CheckoutValidators.normalizeOptionalText(
      _cardMessageController.text,
    );
    setState(() => _submitting = true);

    // TODO: Gửi CheckoutRequest qua CheckoutRepository khi backend checkout hoàn tất.
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => _submitting = false);

    final method = _flowController.deliveryPaymentMethod;
    if (method == LocalPaymentMethod.sepay) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => SepayQrScreen(
            controller: _flowController,
            summary: widget.summary,
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => OrderSuccessScreen(
          controller: _flowController,
          summary: widget.summary,
          isPickup: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final address = _flowController.selectedAddress;
    return CheckoutTheme(
      child: Scaffold(
        appBar: const FleureAppBar(title: 'Thanh toán'),
        body: Form(
          key: _formKey,
          child: CheckoutContent(
            bottom: 128,
            children: <Widget>[
              FulfillmentSwitch(
                value: FulfillmentMode.delivery,
                onChanged: (value) {
                  if (value == FulfillmentMode.pickup) _openPickup();
                },
              ),
              const SizedBox(height: 24),
              CheckoutSectionHeader(
                title: 'Thông tin giao hoa',
                subtitle: 'Fleuré giao tận tay người bạn yêu thương.',
                trailing: TextButton(
                  onPressed: _openAddressBook,
                  child: const Text('Thay đổi'),
                ),
              ),
              const SizedBox(height: 12),
              CheckoutSurfaceCard(
                onTap: _openAddressBook,
                borderColor: CheckoutPalette.forest100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: CheckoutPalette.forest100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.home_outlined,
                        color: CheckoutPalette.forest800,
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
                                address.label,
                                style: const TextStyle(
                                  color: CheckoutPalette.charcoal900,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (address.isDefault)
                                const CheckoutStatusBadge(text: 'Mặc định'),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            '${address.recipientName} · ${address.phone}',
                            style: const TextStyle(
                              color: CheckoutPalette.charcoal700,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            address.fullAddress,
                            style: const TextStyle(
                              color: CheckoutPalette.charcoal500,
                              fontSize: 11,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: CheckoutPalette.charcoal400,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CheckoutInfoBanner(
                icon: Icons.support_agent_rounded,
                title: 'Chăm sóc hành trình giao hoa',
                message: address.driverNote.isEmpty
                    ? 'Tài xế sẽ gọi xác nhận trước khi giao.'
                    : address.driverNote,
              ),
              const SizedBox(height: 12),
              CheckoutSurfaceCard(
                color: CheckoutPalette.petal50,
                borderColor: CheckoutPalette.petal200,
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _priorityDelivery,
                  activeThumbColor: CheckoutPalette.forest800,
                  onChanged: (value) =>
                      setState(() => _priorityDelivery = value),
                  secondary: const Icon(
                    Icons.bolt_rounded,
                    color: CheckoutPalette.petal500,
                  ),
                  title: const Text(
                    'Ưu tiên khung giờ đẹp',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Dự kiến giao hôm nay, 16:00 – 18:00',
                    style: TextStyle(fontSize: 10.5),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const CheckoutSectionHeader(
                title: 'Lời nhắn cho đơn hoa',
                subtitle: 'Nghệ nhân sẽ đọc kỹ trước khi hoàn thiện tác phẩm.',
              ),
              const SizedBox(height: 12),
              LabeledCheckoutField(
                label: 'Ghi chú đơn hàng',
                controller: _orderNoteController,
                hint: 'Ví dụ: phối tông hồng nhạt, hạn chế hoa ly...',
                maxLines: 3,
                maxLength: 300,
                showCounter: true,
                validator: CheckoutValidators.limitedNote,
              ),
              const SizedBox(height: 14),
              LabeledCheckoutField(
                label: 'Nội dung thiệp viết tay',
                controller: _cardMessageController,
                hint: 'Viết điều bạn muốn gửi đến người nhận...',
                maxLines: 4,
                maxLength: 220,
                showCounter: true,
                validator: CheckoutValidators.cardMessage,
              ),
              const SizedBox(height: 28),
              const CheckoutSectionHeader(
                title: 'Phương thức thanh toán',
                subtitle: 'Chọn cách thanh toán phù hợp với bạn.',
              ),
              const SizedBox(height: 12),
              PaymentOptionCard(
                method: LocalPaymentMethod.sepay,
                selected:
                    _flowController.deliveryPaymentMethod ==
                    LocalPaymentMethod.sepay,
                onTap: () => setState(
                  () => _flowController.setDeliveryPayment(
                    LocalPaymentMethod.sepay,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              PaymentOptionCard(
                method: LocalPaymentMethod.cod,
                selected:
                    _flowController.deliveryPaymentMethod ==
                    LocalPaymentMethod.cod,
                onTap: () => setState(
                  () => _flowController.setDeliveryPayment(
                    LocalPaymentMethod.cod,
                  ),
                ),
              ),
              if (_paymentTouched &&
                  CheckoutValidators.selectedPayment(
                        _flowController.deliveryPaymentMethod,
                      ) !=
                      null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Vui lòng chọn phương thức thanh toán.',
                  style: TextStyle(color: CheckoutPalette.error, fontSize: 11),
                ),
              ],
              const SizedBox(height: 28),
              const CheckoutSectionHeader(
                title: 'Tác phẩm trong đơn',
                subtitle: '2 tác phẩm · Được chăm chút riêng cho bạn',
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
              const SizedBox(height: 14),
              PriceSummaryCard(summary: widget.summary),
              const SizedBox(height: 14),
              const CheckoutInfoBanner(
                icon: Icons.lock_outline_rounded,
                title: 'Thông tin được bảo mật',
                message:
                    'Dữ liệu giao nhận và thanh toán chỉ dùng để hoàn tất đơn hoa này.',
              ),
            ],
          ),
        ),
        bottomNavigationBar: CheckoutStickyBar(
          total: widget.summary.grandTotal,
          label: 'Đặt hàng',
          onPressed: _placeOrder,
          loading: _submitting,
        ),
      ),
    );
  }
}
