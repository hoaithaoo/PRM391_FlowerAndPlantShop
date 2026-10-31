# ==============================================================================
# TÀI LIỆU HỆ THỐNG THIẾT KẾ GIAO DIỆN (UI/UX DESIGN SYSTEM SPECIFICATION)
# Dự án       : Nhà Có Hoa • Flower & Plant Shop (Mobile App)
# Người viết  : Đinh Phạm (DinhPham)
# Ngày tạo    : 05/10/2026
# Phiên bản   : v1.0.0 (Official Release)
# Đối tượng   : UI/UX Designer (Figma) & Mobile Developer (Flutter)
# Trạng thái  : Đã phê duyệt (Approved)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. BẢNG MÀU CHUẨN (COLOR PALETTE)
# ------------------------------------------------------------------------------

### 🌿 Nhóm 1: Xanh Rừng (Forest) — Màu Thương Hiệu & Nút Bấm Chính
| Tên màu     | Mã HEX   | Mã Flutter Color     | Mục đích sử dụng trên Mobile                          |
| :---------- | :------- | :------------------- | :---------------------------------------------------- |
| Forest 950  | #0D1E15  | Color(0xFF0D1E15)    | Nền banner tối cao cấp, card nổi bật                  |
| Forest 900  | #132B1E  | Color(0xFF132B1E)    | Nút bấm chính (Primary Button), Header tối            |
| Forest 800  | #193828  | Color(0xFF193828)    | Trạng thái nhấn (Pressed/Hover) của nút chính         |
| Forest 700  | #224A35  | Color(0xFF224A35)    | Icon thanh điều hướng (Active Bottom Nav), Tag xanh   |
| Forest 100  | #E2F0E9  | Color(0xFFE2F0E9)    | Nền badge tag thông tin, chip lọc                     |
| Forest 50   | #F1F7F4  | Color(0xFFF1F7F4)    | Nền khối xanh nhẹ                                     |

### 🌸 Nhóm 2: Hồng Cánh Hoa (Petal) — Màu Điểm Nhấn & Nữ Tính
| Tên màu     | Mã HEX   | Mã Flutter Color     | Mục đích sử dụng trên Mobile                          |
| :---------- | :------- | :------------------- | :---------------------------------------------------- |
| Petal 500   | #A84366  | Color(0xFFA84366)    | Màu nhấn chính (Accent / Highlight), Text link, Tim   |
| Petal 400   | #D982A0  | Color(0xFFD982A0)    | Nút phụ, icon thông báo                               |
| Petal 300   | #EFBACB  | Color(0xFFEFBACB)    | Thanh trượt (Slider), thanh tiến trình                |
| Petal 200   | #F6D6E1  | Color(0xFFF6D6E1)    | Nền highlight văn bản, viền card nổi bật nhẹ          |
| Petal 100   | #FCEAF0  | Color(0xFFFCEAF0)    | Nền thẻ tag hoa, nền khung thông báo dịu mắt          |
| Petal 50    | #FFF7FA  | Color(0xFFFFF7FA)    | Nền sáng phớt hồng nhẹ                                |

### 🥛 Nhóm 3: Nền Kem Phớt Hồng (Cream) — Background Toàn App
| Tên màu     | Mã HEX   | Mã Flutter Color     | Mục đích sử dụng trên Mobile                          |
| :---------- | :------- | :------------------- | :---------------------------------------------------- |
| Cream 100   | #FFF8FA  | Color(0xFFFFF8FA)    | Màu nền màn hình chính (App Scaffold Background)      |
| Cream Pastel| #FFF5F7  | Color(0xFFFFF5F7)    | Nền Bottom Sheet, Modal trượt lên, Card nổi bật       |
| Cream 200   | #FCEEF2  | Color(0xFFFCEEF2)    | Màu đường kẻ viền (Divider / Card Border)             |
| Cream 300   | #F3DDE5  | Color(0xFFF3DDE5)    | Viền ô nhập liệu khi chưa kích hoạt (Input Inactive)  |

### 🖋️ Nhóm 4: Màu Chữ Than (Charcoal) — Typography & Icon
| Tên màu     | Mã HEX   | Mã Flutter Color     | Mục đích sử dụng trên Mobile                          |
| :---------- | :------- | :------------------- | :---------------------------------------------------- |
| Charcoal 900| #171C19  | Color(0xFF171C19)    | Chữ tiêu đề chính (Heading 1, 2), chữ đậm             |
| Charcoal 700| #36403A  | Color(0xFF36403A)    | Chữ nội dung đọc chính (Body Text)                    |
| Charcoal 500| #6B7770  | Color(0xFF6B7770)    | Chữ chú thích phụ (Caption), Text placeholder         |
| Charcoal 400| #8E9993  | Color(0xFF8E9993)    | Icon chưa kích hoạt (Inactive Bottom Nav Icon)        |

# ------------------------------------------------------------------------------
# 2. BỘ FONT CHỮ CHUẨN (TYPOGRAPHY)
# ------------------------------------------------------------------------------

1. Font App Chính (Body, Button, Form, Tab): Plus Jakarta Sans
   - Đặc tính: Sans-serif hiện đại, nét thoáng, chuẩn tỷ lệ hiển thị trên mobile (iOS & Android), hỗ trợ tiếng Việt 100%.
   - Phạm vi dùng: Toàn bộ nội dung bài viết, mô tả hoa, nút bấm, ô nhập liệu, Bottom Navigation Bar.
   - Link tải: https://fonts.google.com/specimen/Plus+Jakarta+Sans
   - Weight cần dùng: Regular (400), Medium (500), SemiBold (600), Bold (700).

2. Font Tiêu Đề Bộ Sưu Tập / Banner Nghệ Thuật: Cormorant Garamond
   - Đặc tính: Serif cổ điển mang phong cách tạp chí cao cấp, nét thanh nét đậm sang trọng.
   - Phạm vi dùng: Tiêu đề bộ sưu tập đặc biệt ("Vẻ Đẹp Hoa Sen", "Ký Ức Sen Hồng Tháp Mười"), trích dẫn nghệ thuật, tên tác phẩm.
   - Link tải: https://fonts.google.com/specimen/Cormorant+Garamond
   - Weight cần dùng: Regular (400), Medium (500), SemiBold (600), Italic (400i).

3. Font Logo & Tên Thương Hiệu: Dancing Script
   - Đặc tính: Chữ viết tay mềm mại, uốn lượn tự nhiên.
   - Phạm vi dùng: Logo "Nhà Có Hoa" trên thanh AppBar / Splash Screen, thiệp chúc mừng hoặc chữ ký nghệ nhân.
   - Link tải: https://fonts.google.com/specimen/Dancing+Script
   - Weight cần dùng: SemiBold (600), Bold (700).

# ------------------------------------------------------------------------------
# 3. QUY CHUẨN CỠ CHỮ CHO MOBILE (TYPOGRAPHY SCALE)
# ------------------------------------------------------------------------------

| Kiểu Style               | Font Family                 | Size (px)    | Weight         | Line Height |
| :----------------------- | :-------------------------- | :----------- | :------------- | :---------- |
| Display / Hero Title     | Cormorant Garamond          | 32px – 36px  | 600 (SemiBold) | 1.2         |
| Headline 1               | Cormorant Garamond          | 24px – 28px  | 600 (SemiBold) | 1.3         |
| Headline 2 (Section)     | Cormorant Garamond          | 20px – 22px  | 600 (SemiBold) | 1.3         |
| Brand Logo               | Dancing Script              | 26px – 30px  | 700 (Bold)     | 1.2         |
| Subtitle / Quote         | Cormorant Garamond (Italic) | 16px – 18px  | 400 (Italic)   | 1.4         |
| Body Large               | Plus Jakarta Sans           | 15px – 16px  | 400 (Regular)  | 1.5         |
| Body Medium (Chuẩn)      | Plus Jakarta Sans           | 14px         | 400 (Regular)  | 1.5         |
| Button Text              | Plus Jakarta Sans           | 14px – 15px  | 600 (SemiBold) | 1.0         |
| Caption / Badge Tag      | Plus Jakarta Sans           | 11px – 12px  | 500 (Medium)   | 1.4         |

# ------------------------------------------------------------------------------
# 4. CODE FLUTTER MẪU (lib/core/theme/app_colors.dart)
# ------------------------------------------------------------------------------

```dart
import 'package:flutter/material.dart';

class AppColors {
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

  // --- MÀU NHẤN (ACCENT PETAL) ---
  static const Color accent = Color(0xFFA84366);           // Điểm nhấn, nút phụ, tim
  static const Color accentLight = Color(0xFFFCEAF0);      // Nền tag hồng pastel
  static const Color accentBorder = Color(0xFFF6D6E1);     // Viền hồng nhẹ

  // --- MÀU CHỮ (TEXT CHARCOAL) ---
  static const Color textHeading = Color(0xFF171C19);      // Tiêu đề đậm
  static const Color textBody = Color(0xFF36403A);         // Chữ nội dung
  static const Color textMuted = Color(0xFF6B7770);        // Chú thích, placeholder
  static const Color textLight = Color(0xFFFFFFFF);        // Chữ trắng trên nền tối
}
```