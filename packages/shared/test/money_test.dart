import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:test/test.dart';

void main() {
  group('formatVnd', () {
    test('số 0', () => expect(formatVnd(0), '0 ₫'));

    test('dưới 1.000 không có dấu chấm', () {
      expect(formatVnd(5), '5 ₫');
      expect(formatVnd(999), '999 ₫');
    });

    test('đúng 1.000', () => expect(formatVnd(1000), '1.000 ₫'));

    test('hàng chục nghìn và trăm nghìn', () {
      expect(formatVnd(12000), '12.000 ₫');
      expect(formatVnd(490000), '490.000 ₫');
    });

    test('hàng triệu và tỷ', () {
      expect(formatVnd(1000000), '1.000.000 ₫');
      expect(formatVnd(12345678), '12.345.678 ₫');
      expect(formatVnd(1234567890), '1.234.567.890 ₫');
    });

    test('số âm giữ dấu trừ phía trước', () {
      expect(formatVnd(-1), '-1 ₫');
      expect(formatVnd(-1000), '-1.000 ₫');
      expect(formatVnd(-490000), '-490.000 ₫');
    });
  });
}
