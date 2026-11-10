import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/checkout/checkout.dart';

class _MockVoucherRepository implements CheckoutRepository {
  _MockVoucherRepository({
    this.vouchers = const <Voucher>[],
    this.addresses = const <CheckoutAddress>[],
    this.checkoutError,
    this.onCheckout,
    this.validateResult,
    this.validateError,
  });

  final List<Voucher> vouchers;
  final List<CheckoutAddress> addresses;
  final Object? checkoutError;
  final void Function(CheckoutRequest request, String key)? onCheckout;
  final Voucher? validateResult;
  final Object? validateError;

  final keys = <String>[];

  @override
  Future<List<Voucher>> availableVouchers({num? subtotal, num? shippingFee}) async => vouchers;

  @override
  Future<List<PickupBranch>> listStores({
    double? latitude,
    double? longitude,
  }) async => const <PickupBranch>[];

  @override
  Future<Voucher> validateVoucher(String code, {num? subtotal, num? shippingFee}) async {
    if (validateError != null) throw validateError!;
    return validateResult ??
        Voucher(
          code: code.toUpperCase(),
          type: 'FIXED',
          value: 50000,
          minOrderAmount: 300000,
          eligible: true,
          discountAmount: 50000,
        );
  }

  @override
  Future<CheckoutResult> checkout(
    CheckoutRequest request, {
    required String idempotencyKey,
  }) async {
    keys.add(idempotencyKey);
    onCheckout?.call(request, idempotencyKey);
    if (checkoutError != null) throw checkoutError!;

    return CheckoutResult(
      order: const CheckoutOrder(
        id: 'ord-1',
        orderCode: 'PFS-ORD-1',
        status: 'PENDING',
      ),
      invoice: CheckoutInvoice(
        id: 'inv-1',
        invoiceNumber: 'INV-1',
        subtotalAmount: 350000,
        discountAmount: 50000,
        taxAmount: 0,
        shippingFee: 20000,
        grandTotal: 320000,
      ),
      payment: null,
    );
  }

  @override
  Future<List<CheckoutAddress>> listAddresses() async => addresses;

  @override
  Future<CheckoutAddress> saveAddress(CheckoutAddress address) async => address;

  @override
  Future<num> estimateShippingFee({
    required double latitude,
    required double longitude,
  }) async => 20000;

  @override
  Future<String> getPaymentStatus(String paymentId) async => 'PENDING';

  @override
  Future<void> cancelOrder(String orderId, {String? reason}) async {}
}

const _testAddress = CheckoutAddress(
  id: 'addr-1',
  label: 'Nhà riêng',
  recipientName: 'Lan Hương',
  phone: '0901234567',
  addressLine: '123 Hoa Hồng',
  ward: 'Phường 1',
  district: 'Quận 3',
  city: 'TP. Hồ Chí Minh',
  latitude: 10.77,
  longitude: 106.68,
  isDefault: true,
);

const _testSummary = CheckoutSummary(
  items: <CheckoutSummaryItem>[
    CheckoutSummaryItem(
      productId: 'p-1',
      name: 'Bó hoa hồng đỏ',
      quantity: 1,
      unitPrice: 350000,
      subtotal: 350000,
    ),
  ],
  subtotal: 350000,
  tax: 0,
  shippingFee: 20000,
  grandTotal: 370000,
);

void main() {
  test('discountOn: voucher ship giảm theo phí ship và không vượt phí', () {
    const fixed = Voucher(
      code: 'SHIP',
      type: 'FIXED',
      scope: Voucher.shippingScope,
      value: 20000,
      discountAmount: 0,
    );
    const percent = Voucher(
      code: 'SHIP50',
      type: 'PERCENT',
      scope: Voucher.shippingScope,
      value: 50,
      maxDiscount: 10000,
      discountAmount: 0,
    );
    expect(fixed.discountOn(15000), 15000);
    expect(fixed.discountOn(30000), 20000);
    expect(percent.discountOn(15000), 7500);
    expect(percent.discountOn(40000), 10000);
  });

  group('CheckoutRequest voucher serialization', () {
    test('toJson excludes voucherCode when absent or empty', () {
      const requestWithout = CheckoutRequest(
        receiverName: 'Lan Hương',
        phone: '0901234567',
        address: '123 Hoa Hồng',
        paymentMethod: PaymentMethod.cod,
      );
      expect(requestWithout.toJson().containsKey('voucherCode'), isFalse);

      const requestEmpty = CheckoutRequest(
        receiverName: 'Lan Hương',
        phone: '0901234567',
        address: '123 Hoa Hồng',
        paymentMethod: PaymentMethod.cod,
        voucherCode: '',
      );
      expect(requestEmpty.toJson().containsKey('voucherCode'), isFalse);
    });

    test('toJson includes voucherCode when present', () {
      const request = CheckoutRequest(
        receiverName: 'Lan Hương',
        phone: '0901234567',
        address: '123 Hoa Hồng',
        paymentMethod: PaymentMethod.cod,
        voucherCode: 'HOA50K',
      );
      expect(request.toJson()['voucherCode'], 'HOA50K');
    });
  });

  group('CheckoutController idempotency with voucher', () {
    var counter = 0;
    String nextKey() => 'key-${++counter}';

    test('changing voucher creates a new idempotency key', () async {
      final repository = _MockVoucherRepository(
        checkoutError: const CheckoutFailure.network(),
      );
      final controller = CheckoutController(
        repository: repository,
        idempotencyKeyFactory: nextKey,
      );

      const baseRequest = CheckoutRequest(
        receiverName: 'Lan Hương',
        phone: '0901234567',
        address: '123 Hoa Hồng',
        paymentMethod: PaymentMethod.cod,
        voucherCode: 'HOA50K',
      );

      await controller.submit(baseRequest);
      await controller.submit(baseRequest);
      expect(repository.keys, hasLength(2));
      expect(repository.keys.toSet(), hasLength(1));

      // Đổi mã voucher -> fingerprint đổi -> tạo Idempotency-Key mới
      const changedRequest = CheckoutRequest(
        receiverName: 'Lan Hương',
        phone: '0901234567',
        address: '123 Hoa Hồng',
        paymentMethod: PaymentMethod.cod,
        voucherCode: 'HOA20',
      );

      await controller.submit(changedRequest);
      expect(repository.keys.toSet(), hasLength(2));
    });
  });

  group('VoucherListScreen', () {
    testWidgets('eligible voucher can be tapped and returned', (tester) async {
      final eligibleVoucher = Voucher(
        code: 'HOA50K',
        type: 'FIXED',
        value: 50000,
        minOrderAmount: 300000,
        eligible: true,
        discountAmount: 50000,
      );

      final repository = _MockVoucherRepository(
        vouchers: [eligibleVoucher],
      );

      Voucher? returnedVoucher;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  returnedVoucher = await Navigator.push<Voucher>(
                    context,
                    MaterialPageRoute<Voucher>(
                      builder: (_) => VoucherListScreen(
                        repository: repository,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('HOA50K'), findsOneWidget);
      expect(find.text('Giảm 50.000 ₫'), findsOneWidget);

      await tester.tap(find.byKey(const Key('voucher-item-HOA50K')));
      await tester.pumpAndSettle();

      expect(returnedVoucher, equals(eligibleVoucher));
    });

    testWidgets('ineligible voucher cannot be tapped and shows reason', (
      tester,
    ) async {
      final ineligibleVoucher = Voucher(
        code: 'HOAVIP',
        type: 'FIXED',
        value: 100000,
        minOrderAmount: 500000,
        eligible: false,
        discountAmount: 0,
        ineligibleReason: 'Mua thêm 150.000đ để dùng',
      );

      final repository = _MockVoucherRepository(
        vouchers: [ineligibleVoucher],
      );

      Voucher? returnedVoucher;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  returnedVoucher = await Navigator.push<Voucher>(
                    context,
                    MaterialPageRoute<Voucher>(
                      builder: (_) => VoucherListScreen(
                        repository: repository,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('HOAVIP'), findsOneWidget);
      expect(find.text('Mua thêm 150.000đ để dùng'), findsOneWidget);

      await tester.tap(find.byKey(const Key('voucher-item-HOAVIP')));
      await tester.pumpAndSettle();

      // Màn không bị pop, voucher không được chọn
      expect(returnedVoucher, isNull);
      expect(find.byType(VoucherListScreen), findsOneWidget);
    });

    testWidgets('applying custom code calls validateVoucher and returns', (
      tester,
    ) async {
      const validVoucher = Voucher(
        code: 'PRIVATE50',
        type: 'FIXED',
        value: 50000,
        discountAmount: 50000,
      );

      final repository = _MockVoucherRepository(
        validateResult: validVoucher,
      );

      Voucher? returnedVoucher;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  returnedVoucher = await Navigator.push<Voucher>(
                    context,
                    MaterialPageRoute<Voucher>(
                      builder: (_) => VoucherListScreen(
                        repository: repository,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('voucher-code-input')),
        'PRIVATE50',
      );
      await tester.tap(find.byKey(const Key('voucher-apply-button')));
      await tester.pumpAndSettle();

      expect(returnedVoucher, equals(validVoucher));
    });

    testWidgets('applying invalid code shows error message', (tester) async {
      final repository = _MockVoucherRepository(
        validateError: const CheckoutFailure(
          code: CheckoutErrorCode.voucherNotFound,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoucherListScreen(
              repository: repository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('voucher-code-input')),
        'UNKNOWN',
      );
      await tester.tap(find.byKey(const Key('voucher-apply-button')));
      await tester.pumpAndSettle();

      expect(find.text('Mã voucher không tồn tại.'), findsOneWidget);
    });
  });

  group('CheckoutScreen with voucher', () {
    testWidgets('displays discount line and updates grand total after selection', (
      tester,
    ) async {
      final voucher = Voucher(
        code: 'HOA50K',
        type: 'FIXED',
        value: 50000,
        minOrderAmount: 300000,
        eligible: true,
        discountAmount: 50000,
      );

      final repository = _MockVoucherRepository(
        addresses: [_testAddress],
        vouchers: [voucher],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CheckoutScreen(
            repository: repository,
            summary: _testSummary,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ban đầu: chưa có dòng giảm giá
      expect(find.text('Ưu đãi thành viên'), findsNothing);
      expect(find.text('370.000 ₫'), findsWidgets); // subtotal 350k + ship 20k

      // Mở màn voucher
      final selectVoucherButton = find.byKey(const Key('checkout-select-voucher'));
      await tester.ensureVisible(selectVoucherButton);
      await tester.tap(selectVoucherButton);
      await tester.pumpAndSettle();

      // Chọn HOA50K
      await tester.tap(find.byKey(const Key('voucher-item-HOA50K')));
      await tester.pumpAndSettle();

      // Sau khi chọn: có dòng giảm giá và tổng tiền giảm 50.000đ
      expect(find.text('Ưu đãi thành viên'), findsOneWidget);
      expect(find.text('-50.000 ₫'), findsWidgets);
      expect(find.text('320.000 ₫'), findsWidgets); // 350k - 50k + 20k = 320k

      // Nút bỏ chọn voucher
      final removeVoucherButton = find.byKey(const Key('checkout-remove-voucher'));
      expect(removeVoucherButton, findsOneWidget);
      await tester.tap(removeVoucherButton);
      await tester.pumpAndSettle();

      // Đã bỏ chọn: tổng tiền quay về 370.000đ
      expect(find.text('Ưu đãi thành viên'), findsNothing);
      expect(find.text('370.000 ₫'), findsWidgets);
    });

    testWidgets('checkout request includes voucherCode when voucher selected', (
      tester,
    ) async {
      CheckoutRequest? capturedRequest;
      final voucher = Voucher(
        code: 'HOA50K',
        type: 'FIXED',
        value: 50000,
        minOrderAmount: 300000,
        eligible: true,
        discountAmount: 50000,
      );

      final repository = _MockVoucherRepository(
        addresses: [_testAddress],
        vouchers: [voucher],
        onCheckout: (req, _) => capturedRequest = req,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CheckoutScreen(
            repository: repository,
            summary: _testSummary,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final selectVoucherButton = find.byKey(const Key('checkout-select-voucher'));
      await tester.ensureVisible(selectVoucherButton);
      await tester.tap(selectVoucherButton);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('voucher-item-HOA50K')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Thanh toán khi nhận hàng'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thanh toán khi nhận hàng'));
      await tester.pumpAndSettle();

      final placeOrderButton = find.byKey(const Key('checkout-place-order'));
      await tester.ensureVisible(placeOrderButton);
      // Key nằm ở cả thanh dưới, giữa thanh không trúng nút.
      await tester.tap(
        find.descendant(
          of: placeOrderButton,
          matching: find.text('Đặt hàng'),
        ),
      );
      await tester.pumpAndSettle();

      expect(capturedRequest?.voucherCode, 'HOA50K');
    });

    testWidgets('VOUCHER_* error shows message and clears selected voucher', (
      tester,
    ) async {
      final voucher = Voucher(
        code: 'HOA50K',
        type: 'FIXED',
        value: 50000,
        minOrderAmount: 300000,
        eligible: true,
        discountAmount: 50000,
      );

      final repository = _MockVoucherRepository(
        addresses: [_testAddress],
        vouchers: [voucher],
        checkoutError: const CheckoutFailure(
          code: CheckoutErrorCode.voucherUsageExceeded,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CheckoutScreen(
            repository: repository,
            summary: _testSummary,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Chọn voucher
      final selectVoucherButton = find.byKey(const Key('checkout-select-voucher'));
      await tester.ensureVisible(selectVoucherButton);
      await tester.tap(selectVoucherButton);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('voucher-item-HOA50K')));
      await tester.pumpAndSettle();
      expect(find.text('HOA50K'), findsOneWidget);

      // Chọn phương thức thanh toán COD
      await tester.ensureVisible(find.text('Thanh toán khi nhận hàng'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thanh toán khi nhận hàng'));
      await tester.pumpAndSettle();

      // Bấm đặt hàng
      final placeOrderButton = find.byKey(const Key('checkout-place-order'));
      await tester.ensureVisible(placeOrderButton);
      // Key nằm ở cả thanh dưới, giữa thanh không trúng nút.
      await tester.tap(
        find.descendant(
          of: placeOrderButton,
          matching: find.text('Đặt hàng'),
        ),
      );
      await tester.pumpAndSettle();

      // Thông báo lỗi xuất hiện
      expect(find.text('Voucher đã hết lượt sử dụng.'), findsOneWidget);

      // Voucher đã bị bỏ chọn
      expect(find.byKey(const Key('checkout-select-voucher')), findsOneWidget);
      expect(find.text('Ưu đãi thành viên'), findsNothing);
    });

    testWidgets('lấy tại quán chọn được voucher, không tính phí ship', (
      tester,
    ) async {
      final voucher = Voucher(
        code: 'HOA50K',
        type: 'FIXED',
        value: 50000,
        minOrderAmount: 300000,
        eligible: true,
        discountAmount: 50000,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CheckoutScreen(
            repository: _MockVoucherRepository(
              addresses: [_testAddress],
              vouchers: [voucher],
            ),
            summary: _testSummary,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lấy tại quán'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pickup-select-shipping-voucher')), findsNothing);
      expect(find.text('350.000 ₫'), findsWidgets);

      final select = find.byKey(const Key('pickup-select-voucher'));
      await tester.ensureVisible(select);
      await tester.tap(select);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('voucher-item-HOA50K')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pickup-selected-voucher')), findsOneWidget);
      expect(find.text('300.000 ₫'), findsWidgets); // 350k - 50k, không ship

      // Quay lại giao hàng vẫn giữ voucher đã chọn.
      await tester.ensureVisible(find.text('Giao tận nơi'));
      await tester.tap(find.text('Giao tận nơi'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('checkout-selected-voucher')), findsOneWidget);
      expect(find.text('320.000 ₫'), findsWidgets);
    });
  });
}
