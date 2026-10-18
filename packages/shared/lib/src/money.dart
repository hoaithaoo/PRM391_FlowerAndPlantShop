/// Định dạng số tiền VND theo thiết kế: `490.000 ₫`.
String formatVnd(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer(amount < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  buffer.write(' ₫');
  return buffer.toString();
}
