# Plant & Flower Store - Backend REST API

Backend API xây dựng trên **Node.js 24 LTS + Express 5 + TypeScript + Prisma ORM + Supabase Auth & PostgreSQL** theo tài liệu kỹ thuật `PLANT & FLOWER STORE.md`.

---

## 1. Cấu trúc thư mục (Folder Structure)

```
backend/
├── prisma/
│   └── schema.prisma             # Định nghĩa toàn bộ Data Model (Profile, Product, Order, Invoice, SePay...)
├── src/
│   ├── config/
│   │   └── env.ts                # Validate biến môi trường bằng Zod
│   ├── lib/
│   │   ├── prisma.ts             # PrismaClient singleton
│   │   ├── supabase.ts           # Supabase Client (Service Role)
│   │   └── logger.ts             # Structured Logger (Bảo mật, không log token/secrets)
│   ├── common/
│   │   ├── errors/
│   │   │   ├── app-error.ts      # Class AppError chuẩn (statusCode, error.code, message, details)
│   │   │   └── error-codes.ts    # Danh mục mã lỗi hệ thống (Exception Catalogue)
│   │   ├── types/
│   │   │   └── api-response.ts   # Interface chuẩn SuccessResponse và ErrorResponse
│   │   └── utils/
│   │       └── response.ts       # Helper functions: sendSuccess, toErrorBody
│   ├── middlewares/
│   │   ├── request-id.middleware.ts     # Gán requestId và header x-request-id
│   │   ├── auth.middleware.ts           # Verify Supabase Bearer JWT Token
│   │   ├── profile.middleware.ts        # First-login profile sync (Tạo profile nếu chưa có)
│   │   ├── account-status.middleware.ts # Chặn tài khoản DISABLED (403 ACCOUNT_DISABLED)
│   │   ├── role.middleware.ts           # Phân quyền USER / ADMIN (403 FORBIDDEN)
│   │   ├── validate.middleware.ts       # Validate req.body, query, params bằng Zod (422)
│   │   └── error-handler.ts             # Global exception handler
│   ├── modules/
│   │   ├── profiles/             # Quản lý hồ sơ người dùng (GET/PUT /api/v1/profile)
│   │   │   ├── profile.controller.ts
│   │   │   ├── profile.service.ts
│   │   │   ├── profile.schema.ts
│   │   │   └── profile.routes.ts
│   │   ├── categories/           # Danh mục sản phẩm
│   │   ├── products/             # Sản phẩm hoa & cây cảnh
│   │   ├── carts/                # Giỏ hàng
│   │   ├── orders/               # Đơn hàng
│   │   ├── invoices/             # Hóa đơn & tính thuế
│   │   ├── payments/             # Thanh toán & SePay QR
│   │   ├── notifications/        # Thông báo người dùng
│   │   ├── stores/               # Địa điểm cửa hàng & OpenStreetMap
│   │   ├── chatbot/              # Trợ lý AI chăm sóc cây
│   │   ├── admin/                # Quản trị viên
│   │   └── webhooks/             # Webhook xác thực SePay HMAC
│   ├── types/
│   │   └── express.d.ts          # Mở rộng Express Request (requestId, auth, profile)
│   ├── app.ts                    # Cấu hình Express app & middlewares
│   └── server.ts                 # Bootstrap server & graceful shutdown
├── .env.example
├── tsconfig.json
└── package.json
```

---

## 2. Cơ chế Xác thực & Phân quyền (Authentication & Authorization)

Hệ thống hoạt động theo mô hình **Supabase Auth + Node.js Backend Verification**:

1. **Flutter Mobile**:
   - Gọi Supabase Auth trực tiếp (Google OAuth 2.0 hoặc Email OTP).
   - Nhận về `access_token` từ Supabase Session.
2. **Gửi Request lên REST API**:
   - Flutter gắn header: `Authorization: Bearer <supabase_access_token>`.
3. **Middleware Chain trên Backend**:
   - `requestIdMiddleware`: Gán mã định danh `req_xxx`.
   - `authMiddleware`:
     - Kiểm tra Bearer token.
     - Gọi `supabase.auth.getUser(token)` để verify token và lấy `userId` / `email`.
     - Thất bại: trả `401 AUTH_TOKEN_MISSING` hoặc `401 AUTH_TOKEN_INVALID` (hoặc `503 AUTH_PROVIDER_UNAVAILABLE` nếu sự cố mạng).
   - `profileMiddleware`:
     - Tìm bản ghi `profiles` tương ứng `user.id`.
     - **First-login Sync**: Nếu chưa có profile trong database, tự động tạo mới với `role: "USER"`, `status: "ACTIVE"`.
     - Lưu profile vào `req.profile`.
   - `accountStatusMiddleware`:
     - Kiểm tra nếu `profile.status === "DISABLED"` -> trả `403 ACCOUNT_DISABLED`.
   - `requireRole("ADMIN")` (chỉ áp dụng cho các route admin):
     - Kiểm tra nếu `profile.role !== "ADMIN"` -> trả `403 FORBIDDEN`.

---

## 3. Hướng dẫn chạy (Getting Started)

1. **Cài đặt thư viện**:
   ```bash
   cd backend
   npm install
   ```

2. **Cấu hình biến môi trường**:
   Sao chép `.env.example` thành `.env` và điền thông tin Supabase của bạn:
   ```env
   PORT=5000
   DATABASE_URL="postgresql://postgres:[PASSWORD]@db.[REF].supabase.co:5432/postgres?pgbouncer=true"
   DIRECT_URL="postgresql://postgres:[PASSWORD]@db.[REF].supabase.co:5432/postgres"
   SUPABASE_URL="https://[REF].supabase.co"
   SUPABASE_ANON_KEY="..."
   SUPABASE_SERVICE_ROLE_KEY="..."
   ```

3. **Sinh Prisma Client & Migration**:
   ```bash
   npm run prisma:generate
   npm run prisma:migrate
   ```

4. **Khởi chạy Development Server**:
   ```bash
   npm run dev
   ```
