import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/products/state/price_range.dart';

void main() {
  group('parsePriceRange', () {
    test('cả hai ô trống là khoảng rỗng hợp lệ', () {
      final result = parsePriceRange('', '');
      expect(result.isValid, isTrue);
      expect(result.range!.isEmpty, isTrue);
      expect(result.error, isNull);
    });

    test('ô toàn khoảng trắng coi như trống', () {
      final result = parsePriceRange('   ', ' ');
      expect(result.isValid, isTrue);
      expect(result.range, const PriceRange());
    });

    test('chỉ nhập "từ"', () {
      final result = parsePriceRange('200000', '');
      expect(result.range, const PriceRange(min: 200000));
    });

    test('chỉ nhập "đến"', () {
      final result = parsePriceRange('', '500000');
      expect(result.range, const PriceRange(max: 500000));
    });

    test('nhập cả hai và trim khoảng trắng', () {
      final result = parsePriceRange(' 100000 ', ' 300000');
      expect(result.range, const PriceRange(min: 100000, max: 300000));
      expect(result.range!.isEmpty, isFalse);
    });

    test('từ bằng đến là hợp lệ', () {
      final result = parsePriceRange('250000', '250000');
      expect(result.isValid, isTrue);
      expect(result.range, const PriceRange(min: 250000, max: 250000));
    });

    test('giá 0 là hợp lệ', () {
      final result = parsePriceRange('0', '100');
      expect(result.range, const PriceRange(min: 0, max: 100));
    });

    test('từ lớn hơn đến là lỗi', () {
      final result = parsePriceRange('500000', '100000');
      expect(result.isValid, isFalse);
      expect(result.range, isNull);
      expect(result.error, contains('từ'));
    });

    test('không phải số nguyên không âm là lỗi', () {
      for (final bad in ['abc', '-5', '1.5', '1,5', '1e3', '12 34']) {
        expect(parsePriceRange(bad, '').isValid, isFalse, reason: 'min "$bad"');
        expect(parsePriceRange('', bad).isValid, isFalse, reason: 'max "$bad"');
      }
    });

    test('số quá lớn không parse được là lỗi', () {
      final result = parsePriceRange('9' * 40, '');
      expect(result.isValid, isFalse);
    });
  });

  group('priceRangeLabel', () {
    test('không có giới hạn thì chuỗi rỗng', () {
      expect(priceRangeLabel(null, null), '');
    });

    test('cả hai: rút gọn k và tr', () {
      expect(priceRangeLabel(500000, 1000000), '500k - 1tr');
    });

    test('chỉ có từ', () {
      expect(priceRangeLabel(200000, null), 'Từ 200k');
    });

    test('chỉ có đến', () {
      expect(priceRangeLabel(null, 350000), 'Đến 350k');
    });

    test('triệu lẻ dùng dấu phẩy', () {
      expect(priceRangeLabel(1500000, null), 'Từ 1,5tr');
      expect(priceRangeLabel(2300000, 10000000), '2,3tr - 10tr');
    });

    test('giá không tròn nghìn giữ nguyên số', () {
      expect(priceRangeLabel(150, null), 'Từ 150');
      expect(priceRangeLabel(1234, 999), '1234 - 999');
    });

    test('giá tròn nghìn nhưng không tròn trăm nghìn ở mức triệu', () {
      // 1.050.000 không rút gọn được bằng "tr" nên rơi về dạng nghìn
      expect(priceRangeLabel(1050000, null), 'Từ 1050k');
    });

    test('0 hiển thị là 0', () {
      expect(priceRangeLabel(0, 100000), '0 - 100k');
    });
  });

  group('PriceRange', () {
    test('so sánh theo giá trị', () {
      expect(const PriceRange(min: 1, max: 2), const PriceRange(min: 1, max: 2));
      expect(
        const PriceRange(min: 1).hashCode,
        const PriceRange(min: 1).hashCode,
      );
      expect(const PriceRange(min: 1) == const PriceRange(max: 1), isFalse);
    });
  });
}
