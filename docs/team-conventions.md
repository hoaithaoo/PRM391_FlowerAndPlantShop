# Team conventions

Tài liệu này là quy ước mặc định cho toàn bộ team. Nếu một PR cần phá vỡ quy
ước, tác giả phải giải thích lý do và được reviewer đồng ý.

## 1. Công cụ và phiên bản

- Node.js: dùng phiên bản trong `.nvmrc`.
- JavaScript/TypeScript: chỉ dùng pnpm và lockfile ở root; không tạo
  `package-lock.json` hoặc `yarn.lock`.
- Dart/Flutter: dùng pub workspace ở root và Melos 7.
- Không sửa file generated bằng tay (`dist`, Prisma Client, Dart generated code).
- Không commit `.env`, token, password, private key hoặc dữ liệu production.

## 2. Git workflow

Nhánh bảo vệ: `main`. Không push trực tiếp lên `main`. Tên nhánh bắt đầu bằng
khu vực code để team nhận ra ngay app/module phụ trách. Mẫu chung:

```text
<area>/<kind>/<ticket>-<short-description>
<area>/<role>/<kind>/<ticket>-<short-description>
```

Dùng mẫu thứ hai khi một app có nhiều vai trò giao diện. Tên area và kind viết
thường; description dùng `kebab-case`. Ticket dùng mã `PFS`; kind gồm `feature`,
`fix`, `chore`, `docs` hoặc `refactor`.

Ví dụ:

```text
backend/feature/PFS-123-cart-api
backend/fix/PFS-234-payment-webhook
mobile/user/feature/PFS-345-product-list
mobile/user/fix/PFS-346-login-validation
mobile/admin/feature/PFS-347-order-management
admin/feature/PFS-348-dashboard-filter
landing/docs/PFS-349-deployment-guide
api-client/feature/PFS-350-auth-header
```

`mobile/user` và `mobile/admin` dùng cho hai luồng người dùng trong app mobile;
`admin` dùng cho app quản trị riêng. Nếu task ảnh hưởng nhiều khu vực, chọn khu
vực chính và ghi các khu vực còn lại trong mô tả PR.

Tạo branch bằng `git switch -c`. Chạy lệnh tương ứng với task và thay mã `PFS`
hoặc tên branch mẫu bằng ticket/nội dung công việc của bạn. Chỉ chạy một lệnh:

```bash
# Backend API
git switch -c backend/feature/PFS-123-cart-api

# Mobile app - luồng khách hàng
git switch -c mobile/user/feature/PFS-123-product-list

# Mobile app - luồng quản trị viên
git switch -c mobile/admin/feature/PFS-123-order-management

# Admin app riêng
git switch -c admin/feature/PFS-123-dashboard-filter

# Landing page
git switch -c landing/feature/PFS-123-home-page
```

Ví dụ: nếu đang làm API giỏ hàng cho ticket `PFS-123`, chọn lệnh đầu tiên.
Không gõ dấu `#` hoặc chạy tất cả các lệnh trong khối.

Commit dùng Conventional Commits:

```text
feat(cart): add item quantity validation
fix(auth): handle expired Supabase token
docs(team): document Render deployment
chore(ci): validate Prisma schema
```

Mỗi commit phải build được khi hợp lý. Không trộn refactor lớn với thay đổi hành
vi trong cùng commit nếu có thể tách ra.

## 3. Pull request

- Một PR giải quyết một mục tiêu rõ ràng và có ticket/issue liên quan.
- Mô tả: vấn đề, giải pháp, cách test, ảnh/video nếu đổi UI, migration nếu đổi DB.
- Tối thiểu một reviewer; phần auth, payment, migration cần reviewer backend.
- Không merge khi CI đỏ, còn unresolved comment hoặc có secret trong diff.
- Squash merge là mặc định; tiêu đề PR phải theo Conventional Commits.

Definition of Done:

- [ ] Code, typecheck/analyze và test liên quan pass.
- [ ] Input được validate; auth/role được kiểm tra ở server.
- [ ] API contract và error code nhất quán.
- [ ] Schema đổi kèm migration và đã review SQL.
- [ ] `.env.example` và docs được cập nhật nếu có config mới.
- [ ] Không log token, secret, password hoặc thông tin thanh toán nhạy cảm.

## 4. Backend convention

Mỗi domain nằm trong `apps/backend/src/modules/<domain>`:

```text
<domain>.routes.ts       # Khai báo URL và middleware chain
<domain>.schema.ts       # Zod input validation và inferred types
<domain>.controller.ts   # HTTP mapping; không chứa business logic dài
<domain>.service.ts      # Nghiệp vụ và Prisma transaction
```

Quy tắc:

- File: `kebab-case.ts`; class/type: `PascalCase`; biến/hàm: `camelCase`.
- Route dùng danh từ số nhiều, version dưới `/api/v1`.
- Controller chuyển lỗi cho global error handler bằng `next(error)`.
- Service không nhận `Request`/`Response`; chỉ nhận typed input và trusted actor.
- Không lấy `userId`, `role`, tổng tiền hoặc trạng thái thanh toán làm dữ liệu tin
  cậy từ client.
- Nghiệp vụ nhiều lần ghi phải dùng `prisma.$transaction`.
- Thời gian API dùng ISO 8601 UTC; tiền VND dùng integer/Prisma Decimal, không
  dùng JavaScript floating point.

Response thành công:

```json
{
  "success": true,
  "data": {},
  "meta": { "requestId": "req_xxx", "timestamp": "ISO-8601" }
}
```

Response lỗi:

```json
{
  "success": false,
  "error": { "code": "PRODUCT_NOT_FOUND", "message": "...", "details": null },
  "meta": { "requestId": "req_xxx", "timestamp": "ISO-8601", "path": "/api/v1/..." }
}
```

Không trả raw Prisma/Supabase error hoặc stack trace ra client. Error code là
`UPPER_SNAKE_CASE` và phải được khai báo trong `error-codes.ts`.

## 5. Auth và security

Middleware order cho protected route:

```text
authMiddleware -> profileMiddleware -> accountStatusMiddleware
               -> requireRole(...) -> validateRequest(...) -> controller
```

- Publishable key có thể dùng ở client; secret/service-role key chỉ được dùng
  trong backend secret store và không cần cho luồng hiện tại.
- Mặc định user mới luôn là `USER`; chỉ server/SQL quản trị được đổi role.
- Webhook phải xác minh chữ ký trên raw payload trước khi xử lý và phải
  idempotent theo provider transaction ID.
- Không log Authorization header, access token, API key hoặc webhook secret.
- `CORS_ORIGIN=*` chỉ dành cho local/non-cookie clients; production web phải
  liệt kê origin cụ thể.

## 6. Database và migration

- `schema.prisma` là nguồn schema ứng dụng; mọi thay đổi phải có migration.
- Không commit standalone SQL bootstrap, database dump hoặc dữ liệu production;
  Prisma migration SQL vẫn phải được commit và review.
- Seed chỉ chứa dữ liệu catalog/demo, không chứa user, password, OTP hoặc secret.
- Local development: `pnpm prisma:migrate -- --name descriptive_name`.
- Production/Render: chỉ dùng `pnpm prisma:migrate:deploy`.
- Không dùng `prisma db push` trên staging/production.
- Không sửa migration đã chạy ở môi trường dùng chung; tạo migration mới.
- Tên field Prisma dùng `camelCase`, tên database dùng `snake_case` qua `@map`.
- Foreign key thường xuyên join/filter phải có index.
- Migration xóa/đổi kiểu dữ liệu phải có kế hoạch backward-compatible và backup.

## 7. Flutter/Dart convention

- Feature-first: `lib/features/<feature>/{data,domain,presentation}` khi app lớn.
- `packages/shared` chỉ chứa Dart thuần; không import Flutter.
- `packages/api_client` chịu trách nhiệm HTTP, auth header và error mapping.
- `packages/ui` chứa theme/token/widget, không gọi API.
- Widget public có tên rõ nghĩa; ưu tiên immutable state và `const` constructor.
- Không hardcode API URL/key trong source; inject bằng `--dart-define` hoặc config
  theo environment. Publishable key được phép ship, secret key thì không.

## 8. Review ownership theo vùng

| Thay đổi | Reviewer bắt buộc |
| --- | --- |
| Auth, role, account status | Backend/security owner |
| Prisma schema/migration | Backend owner |
| Payment/SePay webhook | Backend owner + người hiểu payment flow |
| Shared Dart model/API client | Ít nhất một đại diện mobile và admin |
| CI/Render/environment | DevOps/repo maintainer |

## 9. Lệnh kiểm tra trước khi tạo PR

```bash
pnpm install --frozen-lockfile
pnpm prisma:validate
pnpm prisma:generate
pnpm typecheck:backend
pnpm build:backend

dart pub get
dart run melos run analyze
dart run melos run test
```
