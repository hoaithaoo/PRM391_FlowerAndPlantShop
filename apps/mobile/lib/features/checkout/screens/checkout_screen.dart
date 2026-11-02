import 'package:flutter/material.dart';

import '../data/checkout_api.dart';
import '../data/checkout_failure.dart';
import '../data/checkout_mock_data.dart';
import '../data/checkout_repository.dart';
import '../data/mock_checkout_repository.dart';
import '../models/checkout_flow_models.dart';
import '../models/checkout_request.dart';
import '../models/checkout_result.dart';
import '../models/checkout_summary.dart';
import '../models/payment_method.dart';
import '../state/checkout_controller.dart';
import '../state/checkout_flow_controller.dart';
import '../utils/checkout_theme.dart';
import '../utils/checkout_validators.dart';
import '../widgets/checkout_common.dart';
import 'address_list_screen.dart';
import 'order_success_screen.dart';
import 'sepay_qr_screen.dart';

typedef CheckoutSuccessHandler =
    void Function(BuildContext context, CheckoutResult result);

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.repository,
    required this.summary,
    this.api,
    this.profile,
    this.flowController,
    this.onCheckoutSuccess,
    this.onCheckoutCreated,
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
  final CheckoutApi? api;
  final CheckoutUserProfile? profile;
  final CheckoutFlowController? flowController;
  final CheckoutSuccessHandler? onCheckoutSuccess;
  final VoidCallback? onCheckoutCreated;

  static const CheckoutSummary mockCheckoutSummary = CheckoutMockData.summary;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final CheckoutFlowController _flowController;
  late final CheckoutController _checkoutController;
  late CheckoutSummary _summary;
  late final bool _ownsController;
  late final TextEditingController _orderNoteController;
  late final TextEditingController _cardMessageController;
  bool _priorityDelivery = true;
  bool _submitting = false;
  bool _estimatingShipping = false;
  bool _paymentTouched = false;
  bool _checkoutCreated = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.flowController == null;
    _flowController = widget.flowController ?? CheckoutFlowController();
    _checkoutController = CheckoutController(repository: widget.repository);
    _summary = widget.summary;
    _orderNoteController = TextEditingController(
      text: _flowController.deliveryNote,
    );
    _cardMessageController = TextEditingController(
      text: _flowController.cardMessage,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _estimateShipping());
  }

  @override
  void dispose() {
    _orderNoteController.dispose();
    _cardMessageController.dispose();
    _checkoutController.dispose();
    if (_ownsController) _flowController.dispose();
    super.dispose();
  }

  Future<void> _openAddressBook() async {
    final api = widget.api;
    if (api == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa cấu hình dịch vụ địa chỉ cho thanh toán.'),
        ),
      );
      return;
    }
    await Navigator.of(context).push<CheckoutAddress>(
      MaterialPageRoute<CheckoutAddress>(
        builder: (_) => AddressListScreen(
          controller: _flowController,
          api: api,
          profile: widget.profile,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
    await _estimateShipping();
  }

  Future<void> _estimateShipping() async {
    final api = widget.api;
    final address = _flowController.selectedAddress;
    final latitude = address?.latitude;
    final longitude = address?.longitude;
    if (api == null || latitude == null || longitude == null) return;
    setState(() => _estimatingShipping = true);
    try {
      final estimate = await api.estimateShipping(
        latitude: latitude,
        longitude: longitude,
      );
      if (!mounted) return;
      setState(() {
        _summary = _summary.copyWith(
          shippingFee: estimate.shippingFee,
          grandTotal:
              _summary.subtotal + _summary.tax - _summary.discount +
              estimate.shippingFee,
        );
      });
    } on CheckoutFailure catch (failure) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failure.message ??
                'Không thể tính phí giao hoa. Vui lòng thử lại.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _estimatingShipping = false);
    }
  }

  Future<void> _placeOrder() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    setState(() => _paymentTouched = true);
    final address = _flowController.selectedAddress;
    final addressError = CheckoutValidators.selectedAddress(address);
    final paymentError = CheckoutValidators.selectedPayment(
      _flowController.deliveryPaymentMethod,
    );
    if (!formValid || addressError != null || paymentError != null) return;
    if (address!.latitude == null || address.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Địa chỉ chưa có vị trí hợp lệ. Vui lòng cập nhật vị trí giao hàng.',
          ),
        ),
      );
      return;
    }
    if (_estimatingShipping) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang tính phí giao hoa. Vui lòng đợi.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    _flowController.deliveryNote = CheckoutValidators.normalizeOptionalText(
      _orderNoteController.text,
    );
    _flowController.cardMessage = CheckoutValidators.normalizeOptionalText(
      _cardMessageController.text,
    );
    final method = _flowController.deliveryPaymentMethod;
    if (method != LocalPaymentMethod.cod &&
        method != LocalPaymentMethod.sepay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phương thức thanh toán này chưa được hỗ trợ.'),
        ),
      );
      return;
    }
    final request = CheckoutRequest(
      receiverName: address.recipientName,
      phone: address.phone.replaceAll(RegExp(r'\s+'), ''),
      address: address.fullAddress,
      latitude: address.latitude!,
      longitude: address.longitude!,
      paymentMethod: method == LocalPaymentMethod.sepay
          ? PaymentMethod.sepay
          : PaymentMethod.cod,
      note: _flowController.deliveryNote,
    );

    setState(() => _submitting = true);
    final result = await _checkoutController.submit(request);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _checkoutController.state.errorMessage ??
                'Không thể xử lý đơn hàng. Vui lòng thử lại.',
          ),
        ),
      );
      return;
    }

    setState(() => _checkoutCreated = true);
    widget.onCheckoutCreated?.call();
    widget.onCheckoutSuccess?.call(context, result);
    final confirmedSummary = _summary.copyWith(
      subtotal: result.invoice.subtotalAmount,
      tax: result.invoice.taxAmount,
      shippingFee: result.invoice.shippingFee,
      grandTotal: result.invoice.grandTotal,
      discount: 0,
    );

    if (method == LocalPaymentMethod.sepay) {
      final payment = result.payment;
      final api = widget.api;
      if (payment == null || api == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Máy chủ chưa trả về thông tin thanh toán SePay.',
            ),
          ),
        );
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => SepayQrScreen(
            controller: _flowController,
            summary: confirmedSummary,
            result: result,
            api: api,
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => OrderSuccessScreen(
          controller: _flowController,
          summary: confirmedSummary,
          result: result,
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
              const CheckoutInfoBanner(
                icon: Icons.local_shipping_outlined,
                title: 'Giao hoa tận nơi',
                message:
                    'Hiện tại hệ thống thanh toán trực tuyến hỗ trợ giao tận nơi.',
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
              if (address == null)
                CheckoutSurfaceCard(
                  onTap: _openAddressBook,
                  borderColor: CheckoutPalette.petal200,
                  child: const Row(
                    children: <Widget>[
                      Icon(
                        Icons.add_location_alt_outlined,
                        color: CheckoutPalette.forest800,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Bạn chưa có địa chỉ nhận hàng. Chạm để thêm địa chỉ.',
                          style: TextStyle(
                            color: CheckoutPalette.charcoal700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: CheckoutPalette.charcoal400,
                      ),
                    ],
                  ),
                )
              else
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
                message: address == null || address.driverNote.isEmpty
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
              CheckoutSectionHeader(
                title: 'Tác phẩm trong đơn',
                subtitle:
                    '${_summary.totalQuantity} sản phẩm · Được chăm chút riêng cho bạn',
              ),
              const SizedBox(height: 12),
              CheckoutSurfaceCard(
                child: Column(
                  children: <Widget>[
                    for (
                      var index = 0;
                      index < _summary.items.length;
                      index++
                    ) ...[
                      CheckoutProductTile(item: _summary.items[index]),
                      if (index < _summary.items.length - 1)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              PriceSummaryCard(summary: _summary),
              if (_estimatingShipping) ...[
                const SizedBox(height: 10),
                const LinearProgressIndicator(),
              ],
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
          total: _summary.grandTotal,
          label: _checkoutCreated ? 'Đơn hàng đã được tạo' : 'Đặt hàng',
          onPressed: _estimatingShipping || _checkoutCreated
              ? null
              : _placeOrder,
          loading: _submitting,
        ),
      ),
    );
  }
}
