enum PaymentMethod {
  cod,
  sepay;

  String get apiValue => switch (this) {
    PaymentMethod.cod => 'COD',
    PaymentMethod.sepay => 'SEPAY',
  };

  String get label => switch (this) {
    PaymentMethod.cod => 'Thanh toán khi nhận hàng',
    PaymentMethod.sepay => 'Chuyển khoản SePay',
  };
}
