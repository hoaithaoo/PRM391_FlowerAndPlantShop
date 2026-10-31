String formatVnd(num amount) {
  final roundedValue = amount.round();
  final isNegative = roundedValue < 0;
  final digits = roundedValue.abs().toString();
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[index]);
  }

  return '${isNegative ? '-' : ''}${buffer.toString()} ₫';
}
