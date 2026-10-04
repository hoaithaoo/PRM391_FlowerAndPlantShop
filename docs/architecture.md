# Kiến trúc tổng quan

## Thành phần

- `apps/mobile`: Flutter client cho khách hàng.
- `apps/admin`: Flutter client cho quản trị viên.
- `apps/landing`: website giới thiệu và SEO bằng Next.js.
- `apps/backend`: REST API Express, TypeScript, Prisma và Supabase Auth.
- `packages/shared` (`plant_flower_shared`): model và constant Dart thuần.
- `packages/api_client` (`plant_flower_api_client`): lớp giao tiếp REST API cho các app Dart.
- `packages/ui` (`plant_flower_ui`): theme và widget Flutter dùng chung.

## Quản lý workspace

- **pnpm** (duy nhất, một `pnpm-lock.yaml` ở root) quản lý các dự án
  JavaScript/TypeScript trong `apps/backend` và `apps/landing`.
- **Dart pub workspace + Melos 7** quản lý hai Flutter app và các package trong
  `packages`. Cấu hình nằm trong `pubspec.yaml` ở root, có một `pubspec.lock`
  chung. Mỗi member phải khai báo `resolution: workspace` và được liệt kê trong
  mục `workspace:` của `pubspec.yaml` ở root.
- **Docker Compose** chạy backend và PostgreSQL cho môi trường local. Supabase
  Auth vẫn cần thông tin project thật khi kiểm thử luồng đăng nhập.

## Quy ước phụ thuộc

```text
mobile ─┬─> ui ───────> shared
        └─> api_client -> shared

admin ──┬─> ui ───────> shared
        └─> api_client -> shared

landing ───────────────> backend REST API
```

Các package dùng chung không phụ thuộc ngược vào app. Backend không import mã
nguồn từ các Flutter package; hợp đồng API nên được ghi trong OpenAPI và sinh
client khi dự án bổ sung bước code generation.
