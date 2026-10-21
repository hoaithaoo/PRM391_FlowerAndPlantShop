import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bảng màu lấy trực tiếp từ thiết kế Penpot của 5 màn auth (Fleuré).
abstract final class AuthPalette {
  static const forest = Color(
    0xFF193023,
  ); // Màu thương hiệu, nút chính, tiêu đề
  static const forestButton = Color(0xFF2F4638); // Nút "Đăng nhập"/"Xác nhận"
  static const sage = Color(0xFF566252); // Icon và chữ phụ màu xanh xám
  static const sageSoft = Color(0xFFE4EBE4); // Nền pill "BOTANICAL", chip email
  static const ink = Color(0xFF242623); // Chữ chính, label
  static const inkSoft = Color(0xFF424843); // Đoạn văn trong thẻ ưu đãi
  static const muted = Color(0xFF77736D); // Chữ mô tả, placeholder, icon input
  static const gold = Color(0xFF8A6A32); // Badge vàng
  static const goldSoft = Color(0xFFF2E8D2); // Nền badge vàng
  static const rose = Color(0xFFB98286); // Chấm hồng cạnh logo FLEURÉ

  static const background = Color(0xFFFCF9F3); // Nền màn hình
  static const surface = Color(0xFFFFFDF9); // Nền input, nút Google, thẻ
  static const surfaceMuted = Color(0xFFF6F3ED); // Ghi chú bảo mật, ô nền nhạt
  static const surfaceStone = Color(0xFFF0EEE8); // Nền khung ảnh
  static const chipGrey = Color(0xFFEBE8E2); // Nút đóng tròn, divider
  static const divider = Color(0xFFE5E2DC);
  static const border = Color(0xFFE8E1D7);

  static const error = Color(0xFFBA1A1A);
  static const errorDeep = Color(0xFF93000A);
  static const errorSurface = Color(0xFFFFDAD6);

  /// Bóng nhẹ dùng chung cho input, nút Google, thẻ (0 1 2 0 #000 10%).
  static const softShadow = [
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 1), blurRadius: 2),
  ];

  /// Bóng của nút chính trên màn đăng ký/đăng nhập để tiếp tục.
  static const buttonShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];
}

/// Font của thiết kế: Playfair Display cho tiêu đề, Inter cho nội dung.
///
/// Test đặt [useGoogleFonts] = false để không tải font qua mạng.
abstract final class AuthFonts {
  static bool useGoogleFonts = true;

  static TextStyle serif({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w600,
    FontStyle fontStyle = FontStyle.normal,
    Color color = AuthPalette.forest,
    double? height,
    double? letterSpacing,
  }) {
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
    return useGoogleFonts
        ? GoogleFonts.playfairDisplay(textStyle: base)
        : base.copyWith(fontFamily: 'Playfair Display');
  }

  static TextStyle sans({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AuthPalette.ink,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      decorationColor: color,
    );
    return useGoogleFonts
        ? GoogleFonts.inter(textStyle: base)
        : base.copyWith(fontFamily: 'Inter');
  }
}

/// Các kiểu chữ lặp lại nhiều lần trong thiết kế.
abstract final class AuthTextStyles {
  /// Tiêu đề lớn 28px (Chào mừng bạn, Tạo tài khoản mới...).
  static TextStyle get heading1 =>
      AuthFonts.serif(fontSize: 28, height: 36 / 28, letterSpacing: -0.7);

  /// Tiêu đề trên thanh header 18px.
  static TextStyle get headerTitle =>
      AuthFonts.serif(fontSize: 18, height: 26 / 18, letterSpacing: -0.45);

  /// Đoạn mô tả 14px màu muted.
  static TextStyle get body =>
      AuthFonts.sans(fontSize: 14, color: AuthPalette.muted, height: 1.625);

  /// Nhãn input dạng chữ hoa 11px (màn đăng ký).
  static TextStyle get capsLabel => AuthFonts.sans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 16 / 11,
    letterSpacing: 0.275,
  );

  /// Chữ người dùng nhập và placeholder 14px.
  static TextStyle get input => AuthFonts.sans(fontSize: 14, height: 22 / 14);

  static TextStyle get placeholder => AuthFonts.sans(
    fontSize: 14,
    color: AuthPalette.muted.withValues(alpha: 0.7),
    height: 1.2,
  );

  /// Chữ trên nút chính 16px trắng.
  static TextStyle get button => AuthFonts.sans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.5,
  );

  /// Dòng báo lỗi 12px màu đỏ dưới input.
  static TextStyle get fieldError =>
      AuthFonts.sans(fontSize: 12, color: AuthPalette.error, height: 1.5);
}

/// Bọc các màn auth bằng theme Material khớp bảng màu thiết kế.
class AuthTheme extends StatelessWidget {
  const AuthTheme({super.key, required this.child});

  final Widget child;

  static ThemeData data(ThemeData base) {
    return base.copyWith(
      scaffoldBackgroundColor: AuthPalette.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AuthPalette.forest,
        onPrimary: Colors.white,
        secondary: AuthPalette.sage,
        surface: AuthPalette.surface,
        error: AuthPalette.error,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AuthPalette.forest,
        selectionHandleColor: AuthPalette.forest,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AuthPalette.forest,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(data: data(Theme.of(context)), child: child);
  }
}
