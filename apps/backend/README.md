# Plant & Flower Store - Backend REST API

Backend API xây dựng trên **Node.js 24 LTS + Express 5 + TypeScript + Prisma ORM + Supabase Auth & PostgreSQL** theo tài liệu kỹ thuật [`docs/spec.md`](../../docs/spec.md).

---

## 1. Cấu trúc thư mục (Folder Structure)

```
apps/backend/
├── prisma/
│   └── schema.prisma             # Định nghĩa toàn bộ Data Model (Profile, Product, Order, Invoice, SePay...)
├── src/
│   ├── config/
│   │   └── env.ts                # Validate biến môi trường bằng Zod
│   ├── lib/
│   │   ├── prisma.ts             # PrismaClient singleton
│   │   ├── supabase.ts           # Supabase Auth client (publishable key)
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
│   │   ├── auth/                 # Đăng nhập email/mật khẩu qua Supabase (admin app)
│   │   ├── dashboard/            # Thống kê cho admin
│   │   ├── users/                # Admin quản lý người dùng
│   │   ├── addresses/            # Sổ địa chỉ của user
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
   - Gọi Supabase Auth trực tiếp (Google OAuth 2.0, Email OTP hoặc
     Email/Password).
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

1. **Cài đặt thư viện** (chạy ở root repo, chỉ dùng pnpm):
   ```bash
   corepack enable
   pnpm install
   ```

2. **Cấu hình biến môi trường**:
   Sao chép `apps/backend/.env.example` thành `apps/backend/.env` và điền thông tin Supabase của bạn:
   ```env
   PORT=5000
   DATABASE_URL="postgresql://[DB-USER].[REF]:[PASSWORD]@[POOLER]:5432/postgres?sslmode=require"
   DIRECT_URL="postgresql://[DB-USER].[REF]:[PASSWORD]@[POOLER]:5432/postgres?sslmode=require"
   SUPABASE_URL="https://[REF].supabase.co"
   SUPABASE_PUBLISHABLE_KEY="sb_publishable_..."
   ```

3. **Sinh Prisma Client & Migration**:
   ```bash
   pnpm prisma:generate
   pnpm prisma:migrate:deploy
   pnpm prisma:seed
   ```

4. **Khởi chạy Development Server**:
   ```bash
   pnpm dev:backend
   ```

5. **Docker** (build từ root repo vì dùng chung `pnpm-lock.yaml`):
   ```bash
   docker build -f apps/backend/Dockerfile -t plant-flower-backend .
   ```

Xem hướng dẫn đầy đủ tại
[`docs/supabase-render-setup.md`](../../docs/supabase-render-setup.md) và
[`docs/supabase-auth.md`](../../docs/supabase-auth.md).

---

## 4. Chatbot tư vấn khách hàng (Gemini)

Chatbot là trợ lý AI giữa khách hàng và hệ thống, không phải chat trực tiếp với nhân viên cửa hàng. Backend giữ toàn bộ Gemini secret, xác minh dữ liệu thuộc người dùng và chỉ trả sản phẩm đang hoạt động, còn hàng từ PostgreSQL.

Thêm cấu hình sau vào `apps/backend/.env` (không commit file hoặc key thật):

```env
GEMINI_API_KEY="your_server_side_key"
GEMINI_MODEL="gemini-3.6-flash"
GEMINI_EMBEDDING_MODEL="gemini-embedding-2"
GEMINI_API_BASE_URL="https://generativelanguage.googleapis.com/v1beta"
GEMINI_TIMEOUT_MS=15000
CHATBOT_RATE_LIMIT_MS=1000
RAG_EMBEDDING_DIMENSIONS=768
RAG_MIN_SEMANTIC_SCORE=0.55
```

### Chuẩn bị dữ liệu Hybrid RAG

Chatbot tìm sản phẩm bằng hai đường: PostgreSQL Full-Text Search cho từ khóa/tên chính xác và `pgvector` cho câu hỏi cùng nghĩa hoặc khác ngôn ngữ. Kết quả được hợp nhất bằng Reciprocal Rank Fusion rồi mới gửi sang bước tạo câu trả lời.

Sau khi clone dự án hoặc khi `Product.description` thay đổi, chạy theo thứ tự:

```bash
pnpm install
pnpm prisma:generate
pnpm prisma:migrate:deploy
pnpm prisma:seed
pnpm rag:reindex
pnpm dev:backend
```

Hai migration `20261017_add_product_knowledge_vectors` và `20261017_z_add_product_knowledge_search_vector` tự bật extension `vector`, tạo bảng chunk, cột tìm kiếm toàn văn được sinh tự động, GIN index, HNSW index và RLS trên Supabase. Lệnh `pnpm rag:reindex` đọc mô tả tiếng Việt, chunk theo đoạn/câu hoàn chỉnh, tạo embedding rồi thay index trong một transaction. Nếu quá trình embedding lỗi giữa chừng, index đang dùng không bị xóa.

Lưu ý:

- Phải chạy lại `pnpm rag:reindex` sau khi seed, sửa mô tả hoặc đổi `GEMINI_EMBEDDING_MODEL`; các không gian embedding của hai model khác nhau không được trộn với nhau.
- `RAG_EMBEDDING_DIMENSIONS` phải giữ là `768` vì cột pgvector được tạo với đúng kích thước này.
- Giá, tồn kho và trạng thái đang bán luôn được lọc trực tiếp từ bảng `products`, không lấy từ nội dung do AI tạo.
- Nếu semantic embedding tạm lỗi, chatbot tự chuyển sang keyword search.
- Nếu không tìm thấy kiến thức đã xác minh, chatbot trả lời rằng dữ liệu chưa đủ thay vì sử dụng kiến thức bên ngoài.
- Supabase Advisor có thể báo `RLS Enabled No Policy` ở mức `INFO` cho `product_knowledge_chunks`; đây là chủ ý vì bảng chỉ dành cho backend, đồng thời quyền của `anon` và `authenticated` đã bị thu hồi.

Gửi tin nhắn tư vấn:

```bash
curl -X POST http://localhost:5000/api/v1/chatbot/messages \
  -H "Authorization: Bearer <supabase_access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Cây nào phù hợp để trên bàn và ít nắng?",
    "productId": null
  }'
```

Gửi lỗi thanh toán kèm context đã xác minh:

```bash
curl -X POST http://localhost:5000/api/v1/chatbot/messages \
  -H "Authorization: Bearer <supabase_access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "conversationId": null,
    "message": "Tôi đã thanh toán nhưng đơn hàng chưa cập nhật",
    "context": {
      "orderId": "<order_uuid>",
      "paymentId": "<payment_uuid>",
      "source": "checkout"
    }
  }'
```

Client hiển thị mỗi phần tử trong `suggestedProducts` thành product card và dùng `id` để mở màn hình chi tiết sản phẩm. Khi response có `action.type = "OPEN_INCIDENT_REPORT"`, client mở form báo cáo sự cố rồi điền các giá trị trong `action.draft`. Người dùng vẫn được sửa và xác nhận trước khi gửi; chatbot không tự tạo báo cáo, hoàn tiền hoặc đổi trạng thái đơn hàng.

Các endpoint còn lại:

```text
GET    /api/v1/chatbot/conversations/:id/messages?page=1
DELETE /api/v1/chatbot/conversations/:id
```
