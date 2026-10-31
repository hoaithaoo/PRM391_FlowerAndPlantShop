import 'package:flutter/material.dart';

/// Design system color palette from docs/design-system.md
/// Dự án: Nhà Có Hoa • Flower & Plant Shop
class AppColors {
  AppColors._();

  // --- NỀN (BACKGROUND & SURFACES) ---
  static const Color background = Color(0xFFFFF8FA);       // Nền toàn app
  static const Color surfacePastel = Color(0xFFFFF5F7);    // Nền modal, bottom sheet
  static const Color border = Color(0xFFFCEEF2);           // Viền card & divider
  static const Color borderInactive = Color(0xFFF3DDE5);   // Viền input chưa focus

  // --- MÀU CHÍNH (PRIMARY FOREST) ---
  static const Color primary = Color(0xFF132B1E);          // Nút bấm chính
  static const Color primaryPressed = Color(0xFF193828);   // Nhấn nút chính
  static const Color primaryDark = Color(0xFF0D1E15);      // Nền tối cao cấp
  static const Color primaryLight = Color(0xFFE2F0E9);     // Nền chip tag xanh
  static const Color forest100 = Color(0xFFE2F0E9);        // Alias Forest 100

  // --- MÀU NHẤN (ACCENT PETAL) ---
  static const Color accent = Color(0xFFA84366);           // Điểm nhấn, nút phụ, tim
  static const Color petal500 = Color(0xFFA84366);         // Alias Petal 500
  static const Color accentLight = Color(0xFFFCEAF0);      // Nền tag hồng pastel
  static const Color accentBorder = Color(0xFFF6D6E1);     // Viền hồng nhẹ

  // --- MÀU CHỮ (TEXT CHARCOAL) ---
  static const Color textHeading = Color(0xFF171C19);      // Tiêu đề đậm
  static const Color textBody = Color(0xFF36403A);         // Chữ nội dung
  static const Color textMuted = Color(0xFF6B7770);        // Chú thích, placeholder
  static const Color textLight = Color(0xFFFFFFFF);        // Chữ trắng trên nền tối

  // --- TRẠNG THÁI (STATUS COLORS) ---
  static const Color statusPending = Color(0xFFD97706);    // Cam - Chờ duyệt
  static const Color statusConfirmed = Color(0xFF2563EB);  // Xanh dương - Đã xác nhận
  static const Color statusProcessing = Color(0xFF7C3AED); // Tím - Đang xử lý
  static const Color statusShipping = Color(0xFF0D9488);   // Xanh mòng két - Đang giao
  static const Color statusDelivered = Color(0xFF16A34A);  // Xanh lá - Giao thành công
  static const Color statusCancelled = Color(0xFFDC2626);  // Đỏ - Đã hủy
}
