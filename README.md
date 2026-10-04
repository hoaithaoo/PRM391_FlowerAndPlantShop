# Plant & Flower Shop

Monorepo cho hệ thống bán hoa và cây cảnh, gồm ứng dụng khách hàng, ứng dụng
quản trị, landing page, backend API và các package Dart dùng chung.

## Cấu trúc

```text
.
├── apps/
│   ├── mobile/          # Flutter app dành cho khách hàng
│   ├── admin/           # Flutter app dành cho quản trị viên
│   ├── landing/         # Landing page Next.js
│   └── backend/         # REST API Express + TypeScript + Prisma
├── packages/            # Package Dart dùng chung (pub workspace)
│   ├── shared/          # plant_flower_shared: model, enum, constant
│   ├── api_client/      # plant_flower_api_client: Dart API client
│   └── ui/              # plant_flower_ui: Flutter widgets dùng chung
├── docs/
│   ├── architecture.md  # Kiến trúc tổng quan
│   ├── system-overview.md # Luồng hệ thống và trạng thái hiện tại
│   ├── supabase-auth.md # Google OAuth, Email OTP, Email/Password
│   ├── supabase-render-setup.md # Onboarding Supabase + deploy Render
│   ├── team-conventions.md # Quy ước làm việc của team
│   └── spec.md          # Tài liệu nghiệp vụ & kỹ thuật
├── pubspec.yaml         # Dart pub workspace + cấu hình Melos 7
├── pnpm-workspace.yaml  # JS/TS workspace (backend, landing)
├── package.json
├── .nvmrc               # Phiên bản Node
└── docker-compose.yml
```

Các thư mục `mobile`, `admin` và `landing` đang là khung để phát triển tiếp.

## Bắt đầu nhanh

Yêu cầu: Node.js 24 (xem `.nvmrc`), pnpm (bật qua `corepack enable`),
Flutter stable (Dart ≥ 3.9) và Docker (nếu chạy PostgreSQL local).

```bash
# JavaScript/TypeScript (chỉ dùng pnpm, không dùng npm/yarn)
pnpm install
cp apps/backend/.env.example apps/backend/.env
pnpm prisma:generate
pnpm dev:backend

# Hoặc chạy PostgreSQL + backend bằng Docker
docker compose up --build

# Dart/Flutter
dart pub global activate melos ^7.0.0
melos bootstrap
melos run analyze
```

Xem thêm [tài liệu kiến trúc](docs/architecture.md) và
[hướng dẫn backend](apps/backend/README.md).

## Onboarding cho team

- [Hệ thống hoạt động như thế nào?](docs/system-overview.md)
- [Đăng nhập Supabase: Google, OTP và Email/Password](docs/supabase-auth.md)
- [Bắt đầu với Supabase và deploy Render](docs/supabase-render-setup.md)
- [Quản lý schema và dữ liệu mẫu](supabase/README.md)
- [Team conventions](docs/team-conventions.md)
- [Quy trình đóng góp](CONTRIBUTING.md)
