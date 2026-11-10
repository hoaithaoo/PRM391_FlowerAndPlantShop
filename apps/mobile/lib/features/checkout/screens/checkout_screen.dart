import 'package:flutter/material.dart';

import '../data/checkout_repository.dart';
import '../models/checkout_flow_models.dart';
import '../models/checkout_request.dart';
import '../models/checkout_summary.dart';
import '../models/payment_method.dart';
import '../models/placed_order.dart';
import '../models/voucher.dart';
import '../state/checkout_controller.dart';
import '../state/checkout_flow_controller.dart';
import '../utils/checkout_theme.dart';
import '../utils/checkout_validators.dart';
import '../widgets/checkout_common.dart';
import 'address_list_screen.dart';
import 'order_success_screen.dart';
import 'pickup_checkout_screen.dart';
import 'sepay_qr_screen.dart';
import 'voucher_list_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.repository,
    required this.summary,
    this.onCartChanged,
    this.buyNow,
  });

  final CheckoutRepository repository;

  /// Sản phẩm và tạm tính từ giỏ hàng. Server mới quyết định số tiền cuối cùng.
  final CheckoutSummary summary;

  /// Giỏ trên server đã đổi (đặt xong hoặc hết hàng), cần tải lại.
  final VoidCallback? onCartChanged;

  /// Có giá trị nghĩa là mua ngay: giỏ hàng giữ nguyên.
  final CheckoutBuyNow? buyNow;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  /// Giới hạn `note` của POST /checkout.
  static const _maxNoteLength = 500;

  final _formKey = GlobalKey<FormState>();
  final _flowController = CheckoutFlowController();
  late final CheckoutController _checkoutController = CheckoutController(
    repository: widget.repository,
  );
  final _orderNoteController = TextEditingController();
  final _cardMessageController = TextEditingController();
  bool _loadingAddresses = true;
  bool _addressLoadFailed = false;
  bool _submitting = false;
  bool _paymentTouched = false;
  num _shippingFee = 0;
  Voucher? _voucher;
  Voucher? _shippingVoucher;

  CheckoutSummary get _summary {
    final summary = widget.summary;
    final discount = _voucher?.discountAmount ?? 0;
    final shippingDiscount = _shippingVoucher?.discountOn(_shippingFee) ?? 0;
    final grandTotal =
        summary.subtotal -
        discount +
        summary.tax +
        _shippingFee -
        shippingDiscount;
    return CheckoutSummary(
      items: summary.items,
      subtotal: summary.subtotal,
      discount: discount,
      tax: summary.tax,
      shippingFee: _shippingFee,
      shippingDiscount: shippingDiscount,
      grandTotal: grandTotal < 0 ? 0 : grandTotal,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _orderNoteController.dispose();
    _cardMessageController.dispose();
    _flowController.dispose();
    _checkoutController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _loadingAddresses = true;
      _addressLoadFailed = false;
    });
    try {
      final addresses = await widget.repository.listAddresses();
      if (!mounted) return;
      _flowController.setAddresses(addresses);
      setState(() => _loadingAddresses = false);
      await _refreshShippingFee();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingAddresses = false;
        _addressLoadFailed = true;
      });
    }
  }

  Future<void> _refreshShippingFee() async {
    final address = _flowController.selectedAddress;
    if (address == null || !address.hasCoordinates) {
      setState(() => _shippingFee = 0);
      return;
    }
    try {
      final fee = await widget.repository.estimateShippingFee(
        latitude: address.latitude!,
        longitude: address.longitude!,
      );
      // Bỏ kết quả cũ nếu người dùng đã chọn địa chỉ khác.
      if (!mounted || _flowController.selectedAddress?.id != address.id) return;
      setState(() => _shippingFee = fee);
    } catch (_) {
      // Phí chỉ để xem trước; số thật do POST /checkout trả về.
      if (mounted) setState(() => _shippingFee = 0);
    }
  }

  Future<void> _openAddressBook() async {
    await Navigator.of(context).push<CheckoutAddress>(
      MaterialPageRoute<CheckoutAddress>(
        builder: (_) => AddressListScreen(
          controller: _flowController,
          onSave: widget.repository.saveAddress,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
    await _refreshShippingFee();
  }

  Future<void> _openVoucherList({required bool shipping}) async {
    final selected = await Navigator.of(context).push<Voucher>(
      MaterialPageRoute<Voucher>(
        builder: (_) => VoucherListScreen(
          repository: widget.repository,
          currentVoucher: shipping ? _shippingVoucher : _voucher,
          scope: shipping ? Voucher.shippingScope : Voucher.orderScope,
          subtotal: widget.summary.subtotal,
          shippingFee: _shippingFee,
        ),
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      if (shipping) {
        _shippingVoucher = selected;
      } else {
        _voucher = selected;
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _buildNote(String orderNote, String cardMessage) {
    final note = <String>[
      if (orderNote.isNotEmpty) orderNote,
      if (cardMessage.isNotEmpty) 'Thiệp: $cardMessage',
    ].join('\n');
    return note.length > _maxNoteLength
        ? note.substring(0, _maxNoteLength)
        : note;
  }

  Future<void> _placeOrder() async {
    if (_submitting) return;
    final formValid = _formKey.currentState?.validate() ?? false;
    setState(() => _paymentTouched = true);
    final address = _flowController.selectedAddress;
    final method = _flowController.deliveryPaymentMethod;
    if (!formValid || method == null) return;
    if (address == null) {
      _showMessage('Vui lòng chọn địa chỉ nhận hàng.');
      return;
    }
    if (!address.hasCoordinates) {
      _showMessage(
        'Chưa xác định được vị trí của địa chỉ này. Vui lòng sửa lại địa chỉ.',
      );
      return;
    }

    FocusScope.of(context).unfocus();
    final orderNote = CheckoutValidators.normalizeOptionalText(
      _orderNoteController.text,
    );
    final cardMessage = CheckoutValidators.normalizeOptionalText(
      _cardMessageController.text,
    );
    await _submitOrder(
      CheckoutRequest(
        receiverName: address.recipientName,
        phone: address.normalizedPhone,
        address: address.fullAddress,
        latitude: address.latitude,
        longitude: address.longitude,
        paymentMethod: method == LocalPaymentMethod.sepay
            ? PaymentMethod.sepay
            : PaymentMethod.cod,
        note: _buildNote(orderNote, cardMessage),
        voucherCode: _voucher?.code,
        shippingVoucherCode: _shippingVoucher?.code,
        buyNow: widget.buyNow,
      ),
      address: address,
      cardMessage: cardMessage,
    );
  }

  Future<void> _openPickup() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PickupCheckoutScreen(
          controller: _flowController,
          summary: _summary,
          repository: widget.repository,
          voucher: _voucher,
          onVoucherChanged: (voucher) => setState(() => _voucher = voucher),
          buyNow: widget.buyNow,
          onPlaceOrder: (request, branch, pickupTime) =>
              _submitOrder(request, address: branch, pickupTime: pickupTime),
        ),
      ),
    );
  }

  /// [pickupTime] có giá trị nghĩa là [PickupCheckoutScreen] đang nằm trên màn này.
  Future<void> _submitOrder(
    CheckoutRequest request, {
    required CheckoutAddress address,
    String cardMessage = '',
    String? pickupTime,
  }) async {
    final summary = _summary;
    final navigator = Navigator.of(context);
    setState(() => _submitting = true);
    final result = await _checkoutController.submit(request);
    if (!mounted) return;
    setState(() => _submitting = false);
    widget.onCartChanged?.call();

    if (result == null) {
      final code = _checkoutController.state.errorCode;
      if (code != null && code.startsWith('VOUCHER_')) {
        setState(() {
          _voucher = null;
          _shippingVoucher = null;
        });
        // Tổng tiền ở màn nhận tại quán đã cũ, quay lại để khách thấy số mới.
        if (pickupTime != null) navigator.pop();
      }
      _showMessage(
        _checkoutController.state.errorMessage ??
            'Không thể xử lý đơn hàng lúc này. Vui lòng thử lại.',
      );
      return;
    }

    final order = PlacedOrder(
      result: result,
      summary: summary,
      address: address,
      cardMessage: cardMessage,
      pickupTime: pickupTime,
    );
    if (pickupTime != null) navigator.pop();
    // Thay màn checkout: giỏ đã trống, quay lại đây không còn gì để đặt.
    await navigator.pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => result.payment == null
            ? OrderSuccessScreen(order: order)
            : SepayQrScreen(order: order, repository: widget.repository),
      ),
    );
  }

  Widget _buildAddressSection() {
    if (_loadingAddresses) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_addressLoadFailed) {
      return CheckoutSurfaceCard(
        onTap: _loadAddresses,
        child: const Text('Không tải được sổ địa chỉ. Chạm để thử lại.'),
      );
    }
    final address = _flowController.selectedAddress;
    if (address == null) {
      return CheckoutSurfaceCard(
        key: const Key('checkout-add-address'),
        onTap: _openAddressBook,
        child: const Text('Chưa có địa chỉ. Chạm để thêm địa chỉ nhận hàng.'),
      );
    }
    return CheckoutSurfaceCard(
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
    );
  }

  Widget _buildVoucherSection({required bool shipping}) {
    final voucher = shipping ? _shippingVoucher : _voucher;
    return CheckoutVoucherCard(
      voucher: voucher,
      discount: shipping
          ? voucher?.discountOn(_shippingFee) ?? 0
          : voucher?.discountAmount ?? 0,
      shipping: shipping,
      onTap: () => _openVoucherList(shipping: shipping),
      onRemove: () => setState(() {
        if (shipping) {
          _shippingVoucher = null;
        } else {
          _voucher = null;
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
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
                subtitle: 'Nhà Có Hoa giao tận tay người bạn yêu thương.',
                trailing: TextButton(
                  onPressed: _loadingAddresses ? null : _openAddressBook,
                  child: const Text('Thay đổi'),
                ),
              ),
              const SizedBox(height: 12),
              _buildAddressSection(),
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
                maxLength: 270,
                showCounter: true,
                validator: (value) =>
                    CheckoutValidators.limitedNote(value, maxLength: 270),
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
                    '${summary.totalQuantity} tác phẩm · Được chăm chút riêng cho bạn',
              ),
              const SizedBox(height: 12),
              CheckoutSurfaceCard(
                child: Column(
                  children: <Widget>[
                    for (
                      var index = 0;
                      index < summary.items.length;
                      index++
                    ) ...[
                      CheckoutProductTile(item: summary.items[index]),
                      if (index < summary.items.length - 1)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildVoucherSection(shipping: false),
              const SizedBox(height: 10),
              _buildVoucherSection(shipping: true),
              const SizedBox(height: 14),
              PriceSummaryCard(summary: summary),
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
          key: const Key('checkout-place-order'),
          total: summary.grandTotal,
          label: 'Đặt hàng',
          onPressed: _loadingAddresses ? null : _placeOrder,
          loading: _submitting,
        ),
      ),
    );
  }
}
