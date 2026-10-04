# Supabase

Thư mục này không lưu database dump hoặc file SQL bootstrap. Schema ứng dụng
được quản lý bằng Prisma tại `apps/backend/prisma/schema.prisma` và lịch sử thay
đổi nằm trong `apps/backend/prisma/migrations`.

Khởi tạo database mới:

```bash
pnpm install --frozen-lockfile
pnpm prisma:validate
pnpm prisma:generate
pnpm prisma:migrate:deploy
pnpm prisma:seed
```

`prisma:seed` chỉ tạo category, product và store mẫu. User phải được tạo qua
Supabase Auth; seed không tạo tài khoản, password, OTP hoặc admin giả.

Xem [cấu hình đăng nhập](../docs/supabase-auth.md) và
[hướng dẫn Supabase/Render](../docs/supabase-render-setup.md).
