abstract final class CheckoutValidators {
  static String? requiredText(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? recipientName(String? value) {
    final requiredError = requiredText(value, 'Vui lòng nhập họ và tên.');
    if (requiredError != null) return requiredError;
    final normalized = value!.trim();
    if (!RegExp(
      r'^[A-Za-zÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚĂĐĨŨƠƯẠ-Ỵàáâãèéêìíòóôõùúăđĩũơưạ-ỵ\s]+$',
      unicode: true,
    ).hasMatch(normalized)) {
      return 'Họ và tên không được chứa số hoặc ký tự đặc biệt.';
    }
    return null;
  }

  static String? vietnamesePhone(String? value) {
    final normalized = (value ?? '').trim();
    if (normalized.isEmpty) return 'Vui lòng nhập số điện thoại.';
    if (!RegExp(r'^0(3|5|7|8|9)\d{8}$').hasMatch(normalized)) {
      return 'Số điện thoại không hợp lệ.';
    }
    return null;
  }

  static String? deliveryAddress(String? value) {
    final requiredError = requiredText(
      value,
      'Vui lòng nhập địa chỉ nhận hàng.',
    );
    if (requiredError != null) return requiredError;
    if (value!.trim().length < 5) {
      return 'Vui lòng nhập địa chỉ nhận hàng.';
    }
    return null;
  }

  static String? detailedAddress(String? value) {
    return requiredText(value, 'Vui lòng nhập địa chỉ chi tiết.');
  }

  static String? province(String? value) {
    return requiredText(value, 'Vui lòng chọn Tỉnh/Thành phố.');
  }

  static String? district(String? value) {
    return requiredText(value, 'Vui lòng chọn Quận/Huyện.');
  }

  static String? ward(String? value) {
    return requiredText(value, 'Vui lòng chọn Phường/Xã.');
  }

  static String? limitedNote(
    String? value, {
    int maxLength = 300,
    String message = 'Ghi chú vượt quá số ký tự cho phép.',
  }) {
    if ((value ?? '').trim().length > maxLength) {
      return message;
    }
    return null;
  }

  static String? cardMessage(String? value, {int maxLength = 220}) {
    return limitedNote(
      value,
      maxLength: maxLength,
      message: 'Nội dung lời nhắn vượt quá số ký tự cho phép.',
    );
  }

  static String? selectedPayment(Object? value) {
    return value == null ? 'Vui lòng chọn phương thức thanh toán.' : null;
  }

  static String? selectedAddress(Object? value) {
    return value == null ? 'Vui lòng chọn địa chỉ nhận hàng.' : null;
  }

  static String? selectedBranch(Object? value) {
    return value == null ? 'Vui lòng chọn chi nhánh nhận hoa.' : null;
  }

  static String? pickupDate(DateTime? value) {
    if (value == null) return 'Vui lòng chọn ngày nhận hoa.';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(value.year, value.month, value.day);
    if (selected.isBefore(today)) return 'Vui lòng chọn ngày nhận hoa.';
    return null;
  }

  static String? pickupTime(String? value, List<String> availableTimes) {
    if (value == null || !availableTimes.contains(value)) {
      return 'Vui lòng chọn giờ nhận hoa.';
    }
    return null;
  }

  static String normalizeOptionalText(String value) {
    return value
        .split('\n')
        .map((line) => line.trim().replaceAll(RegExp(r'\s+'), ' '))
        .join('\n')
        .trim();
  }
}
