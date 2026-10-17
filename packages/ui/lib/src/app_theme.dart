import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bảng màu chuẩn theo `docs/DESIGN.md` mục 1 và 4.
abstract final class AppColors {
  // --- NỀN (BACKGROUND & SURFACES) ---
  static const Color background = Color(0xFFFFF8FA); // Cream 100: nền toàn app
  static const Color surfacePastel = Color(0xFFFFF5F7); // Cream Pastel: modal, bottom sheet, card nổi bật
  static const Color border = Color(0xFFFCEEF2); // Cream 200: viền card & divider
  static const Color borderInactive = Color(0xFFF3DDE5); // Cream 300: viền input chưa focus
  static const Color surface = Color(0xFFFFFFFF); // Nền card, input trên nền kem

  // --- MÀU CHÍNH (PRIMARY FOREST) ---
  static const Color primary = Color(0xFF132B1E); // Forest 900: nút bấm chính
  static const Color primaryPressed = Color(0xFF193828); // Forest 800: nhấn nút chính
  static const Color primaryDark = Color(0xFF0D1E15); // Forest 950: nền tối cao cấp
  static const Color primaryActive = Color(0xFF224A35); // Forest 700: icon nav đang chọn, tag xanh
  static const Color primaryLight = Color(0xFFE2F0E9); // Forest 100: nền chip, badge
  static const Color primarySoft = Color(0xFFF1F7F4); // Forest 50: nền khối xanh nhẹ

  // --- MÀU NHẤN (ACCENT PETAL) ---
  static const Color accent = Color(0xFFA84366); // Petal 500: điểm nhấn, text link, tim
  static const Color accentSoft = Color(0xFFD982A0); // Petal 400: icon thông báo
  static const Color accentBorder = Color(0xFFF6D6E1); // Petal 200: viền hồng nhẹ
  static const Color accentLight = Color(0xFFFCEAF0); // Petal 100: nền tag hồng pastel
  static const Color accentPale = Color(0xFFFFF7FA); // Petal 50: nền phớt hồng

  // --- MÀU CHỮ (TEXT CHARCOAL) ---
  static const Color textHeading = Color(0xFF171C19); // Charcoal 900: tiêu đề
  static const Color textBody = Color(0xFF36403A); // Charcoal 700: nội dung
  static const Color textMuted = Color(0xFF6B7770); // Charcoal 500: chú thích, placeholder
  static const Color iconInactive = Color(0xFF8E9993); // Charcoal 400: icon nav chưa chọn
  static const Color textLight = Color(0xFFFFFFFF); // Chữ trắng trên nền tối

  static const Color error = Color(0xFFBA1A1A);

  // Compatibility aliases and order status colors used by the admin app.
  static const Color forest100 = primaryLight;
  static const Color petal500 = accent;
  static const Color statusPending = Color(0xFFD97706);
  static const Color statusConfirmed = Color(0xFF2563EB);
  static const Color statusProcessing = Color(0xFF7C3AED);
  static const Color statusShipping = Color(0xFF0D9488);
  static const Color statusDelivered = Color(0xFF16A34A);
  static const Color statusCancelled = Color(0xFFDC2626);

  /// Bóng nhẹ cho card, chip, input.
  static const softShadow = [
    BoxShadow(color: Color(0x0D171C19), offset: Offset(0, 1), blurRadius: 2),
  ];

  /// Bóng cho khung ảnh sản phẩm và thanh điều hướng nổi.
  static const cardShadow = [
    BoxShadow(color: Color(0x0F171C19), offset: Offset(0, 2), blurRadius: 10),
  ];

  /// Bóng của nút chính.
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

/// Ba font của `docs/DESIGN.md` mục 2.
///
/// Test đặt [useGoogleFonts] = false để không tải font qua mạng.
abstract final class AppFonts {
  static bool useGoogleFonts = true;

  /// Plus Jakarta Sans: nội dung, nút, form, tab.
  static TextStyle sans({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textBody,
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
        ? GoogleFonts.plusJakartaSans(textStyle: base)
        : base.copyWith(fontFamily: 'Plus Jakarta Sans');
  }

  /// Cormorant Garamond: tiêu đề bộ sưu tập, tên tác phẩm, trích dẫn.
  static TextStyle serif({
    double fontSize = 22,
    FontWeight fontWeight = FontWeight.w600,
    FontStyle fontStyle = FontStyle.normal,
    Color color = AppColors.textHeading,
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
        ? GoogleFonts.cormorantGaramond(textStyle: base)
        : base.copyWith(fontFamily: 'Cormorant Garamond');
  }

  /// Dancing Script: logo "Nhà Có Hoa".
  static TextStyle script({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.primary,
  }) {
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: 1.2,
    );
    return useGoogleFonts
        ? GoogleFonts.dancingScript(textStyle: base)
        : base.copyWith(fontFamily: 'Dancing Script');
  }
}

/// Thang cỡ chữ theo `docs/DESIGN.md` mục 3.
abstract final class AppTextStyles {
  /// Display / Hero Title: Cormorant 32px.
  static TextStyle get display =>
      AppFonts.serif(fontSize: 32, height: 1.2, color: AppColors.textLight);

  /// Headline 1: Cormorant 26px (tên sản phẩm ở trang chi tiết).
  static TextStyle get headline1 => AppFonts.serif(fontSize: 26, height: 1.3);

  /// Headline 2 (Section): Cormorant 22px.
  static TextStyle get headline2 => AppFonts.serif(fontSize: 22, height: 1.3);

  /// Tiêu đề trên header: Cormorant 20px.
  static TextStyle get headerTitle => AppFonts.serif(fontSize: 20, height: 1.3);

  /// Tên tác phẩm trên thẻ: Cormorant 18px.
  static TextStyle get cardTitle => AppFonts.serif(fontSize: 18, height: 1.2);

  /// Brand Logo: Dancing Script 28px.
  static TextStyle get brandLogo => AppFonts.script();

  /// Subtitle / Quote: Cormorant Italic 17px.
  static TextStyle get quote => AppFonts.serif(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    height: 1.4,
    color: AppColors.textBody,
  );

  /// Body Large: Jakarta 15px.
  static TextStyle get bodyLarge => AppFonts.sans(fontSize: 15, height: 1.5);

  /// Body Medium (chuẩn): Jakarta 14px.
  static TextStyle get body => AppFonts.sans(fontSize: 14, height: 1.5);

  /// Button Text: Jakarta 15px SemiBold.
  static TextStyle get button => AppFonts.sans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.0,
    color: AppColors.textLight,
  );

  /// Caption / Badge Tag: Jakarta 12px Medium.
  static TextStyle get caption => AppFonts.sans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textMuted,
  );

  /// Badge, chip, nhãn tab: Jakarta 11px Medium.
  static TextStyle get badge => AppFonts.sans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.3,
    color: AppColors.primaryActive,
  );

  /// Nhãn chữ hoa nhỏ (TUYỂN CHỌN MÙA NÀY, MÔ TẢ TÁC PHẨM).
  static TextStyle get overline => AppFonts.sans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 1.1,
    color: AppColors.primaryActive,
  );

  /// Giá trên thẻ sản phẩm: Jakarta 14px SemiBold.
  static TextStyle get price => AppFonts.sans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.primary,
  );
}

/// ThemeData nền cho app khách hàng.
abstract final class AppTheme {
  static ThemeData data([ThemeData? base]) {
    final theme = base ?? ThemeData(useMaterial3: true);
    return theme.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: theme.colorScheme.copyWith(
        primary: AppColors.primary,
        onPrimary: AppColors.textLight,
        secondary: AppColors.accent,
        onSecondary: AppColors.textLight,
        surface: AppColors.surface,
        onSurface: AppColors.textBody,
        outline: AppColors.borderInactive,
        outlineVariant: AppColors.border,
        error: AppColors.error,
      ),
      textTheme: theme.textTheme.apply(
        fontFamily: AppFonts.sans().fontFamily,
        bodyColor: AppColors.textBody,
        displayColor: AppColors.textHeading,
      ),
      dividerColor: AppColors.border,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfacePastel,
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        contentTextStyle: AppFonts.sans(color: AppColors.textLight),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }
}
