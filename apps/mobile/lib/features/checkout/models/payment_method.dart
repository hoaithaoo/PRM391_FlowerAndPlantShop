enum PaymentMethod {
  cod,
  sepay;

  String get apiValue => switch (this) {
    PaymentMethod.cod => 'COD',
    PaymentMethod.sepay => 'SEPAY',
  };

  String get label => switch (this) {
    PaymentMethod.cod => 'Cash on delivery',
    PaymentMethod.sepay => 'SePay bank transfer',
  };
}
