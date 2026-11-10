import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/checkout/checkout.dart';

class _CapturingRepository extends MockCheckoutRepository {
  _CapturingRepository() : super(delay: Duration.zero);

  CheckoutRequest? request;

  @override
  Future<CheckoutResult> checkout(
    CheckoutRequest request, {
    required String idempotencyKey,
  }) {
    this.request = request;
    return super.checkout(request, idempotencyKey: idempotencyKey);
  }
}

void main() {
  testWidgets('đặt nhận tại quán gửi cửa hàng, giờ nhận và không gửi địa chỉ', (
    tester,
  ) async {
    final repository = _CapturingRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: CheckoutScreen(
          repository: repository,
          summary: CheckoutMockData.summary,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lấy tại quán'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đặt đơn và lấy tại quán'));
    await tester.pumpAndSettle();

    final request = repository.request!;
    expect(request.pickupStoreId, CheckoutMockData.branches.first.id);
    expect(request.pickupAt!.isAfter(DateTime.now()), isTrue);
    expect(request.toJson().containsKey('address'), isFalse);
    expect(request.toJson().containsKey('latitude'), isFalse);
    expect(request.paymentMethod, PaymentMethod.cod);

    expect(find.byType(OrderSuccessScreen), findsOneWidget);
    expect(find.text('Thanh toán tại cửa hàng'), findsOneWidget);
  });
}
