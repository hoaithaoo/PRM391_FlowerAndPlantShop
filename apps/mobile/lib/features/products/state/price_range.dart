/// Khoảng giá (VND) do người dùng nhập ở bottom sheet "Lọc giá".
class PriceRange {
  const PriceRange({this.min, this.max});

  final int? min;
  final int? max;

  /// Không giới hạn nào: tương đương xoá lọc giá.
  bool get isEmpty => min == null && max == null;

  @override
  bool operator ==(Object other) =>
      other is PriceRange && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(min, max);
}

/// Kết quả phân tích hai ô nhập giá: hoặc [range], hoặc [error] tiếng Việt.
class PriceRangeParse {
  const PriceRangeParse.ok(PriceRange this.range) : error = null;
  const PriceRangeParse.error(String this.error) : range = null;

  final PriceRange? range;
  final String? error;

  bool get isValid => error == null;
}

/// Phân tích hai ô nhập "Từ" / "Đến". Ô trống nghĩa là không giới hạn.
///
/// Chỉ nhận số nguyên không âm; báo lỗi khi "từ" lớn hơn "đến".
PriceRangeParse parsePriceRange(String minText, String maxText) {
  final min = _parseAmount(minText);
  final max = _parseAmount(maxText);
  if (min.invalid || max.invalid) {
    return const PriceRangeParse.error('Giá phải là số nguyên không âm.');
  }
  final from = min.value;
  final to = max.value;
  if (from != null && to != null && from > to) {
    return const PriceRangeParse.error(
      'Giá "từ" phải nhỏ hơn hoặc bằng giá "đến".',
    );
  }
  return PriceRangeParse.ok(PriceRange(min: from, max: to));
}

({int? value, bool invalid}) _parseAmount(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return (value: null, invalid: false);
  if (!RegExp(r'^\d+$').hasMatch(trimmed)) return (value: null, invalid: true);
  final value = int.tryParse(trimmed);
  return (value: value, invalid: value == null);
}

/// Nhãn rút gọn hiển thị trên nút lọc giá, ví dụ `500k - 1tr`, `Từ 200k`.
String priceRangeLabel(int? min, int? max) {
  if (min != null && max != null) return '${_short(min)} - ${_short(max)}';
  if (min != null) return 'Từ ${_short(min)}';
  if (max != null) return 'Đến ${_short(max)}';
  return '';
}

String _short(int value) {
  if (value >= 1000000 && value % 100000 == 0) {
    final millions = value ~/ 1000000;
    if (value % 1000000 == 0) return '${millions}tr';
    final tenths = (value % 1000000) ~/ 100000;
    return '$millions,${tenths}tr';
  }
  if (value >= 1000 && value % 1000 == 0) return '${value ~/ 1000}k';
  return '$value';
}
