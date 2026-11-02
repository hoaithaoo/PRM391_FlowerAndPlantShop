# Task: Voucher cho checkout

Tài liệu này dành cho agent thực thi. Mọi quyết định bên dưới đã được chủ dự án chốt. Làm đúng phạm vi, không tự thêm tính năng. Nếu code thực tế khác với mô tả ở đây, dừng lại và báo cáo thay vì tự đoán.

## 1. Bối cảnh

- Monorepo: `apps/backend` (Express 5, Prisma, Zod, Supabase PostgreSQL), `apps/mobile` (Flutter), `packages/api_client`.
- Nhánh làm việc: `backend/feature/PFS-000-voucher`.
- Cửa hàng **chỉ bán hoa**. Dữ liệu demo, câu chữ và ví dụ phải nói về hoa, không nhắc cây cảnh hay phụ kiện.
- Đọc trước: `docs/team-conventions.md`.
- Toàn bộ text hiển thị cho người dùng và message lỗi viết bằng tiếng Việt.

### Quy tắc an toàn

- Working tree có thể đang chứa nhiều thay đổi chưa commit về checkout, chat, auth và giỏ hàng. Voucher phụ thuộc vào các thay đổi này. Không dùng `git stash`, `git reset`, `git checkout -- <file>` hay `git clean`.
- Không commit, không push nếu chủ dự án chưa yêu cầu.
- Không đọc và không in giá trị trong các file `.env`.
- **Không chạy `prisma migrate dev`, `prisma migrate reset`, `prisma db push`.** Database trong `.env` có thể là database dùng chung, các lệnh này có thể xóa dữ liệu hoặc đòi reset. Chỉ viết file migration SQL tay (mục 3) và dừng lại hỏi chủ dự án trước khi chạy `prisma migrate deploy`.
- Không sửa migration đã có. Không sửa file generated.

## 2. Quy tắc nghiệp vụ

| Quy tắc | Giá trị |
|---|---|
| Loại voucher | `PERCENT` (có thể có `maxDiscount`), `FIXED` |
| Số mã mỗi đơn | Một |
| Đối tượng giảm | Tiền hàng. Không giảm phí ship |
| Thuế | Tính trên phần tiền sau khi giảm |
| Hiển thị | `isPublic = true`: hiện trong danh sách. `isPublic = false`: chỉ nhập tay |
| Mã chưa đủ điều kiện | Vẫn hiện trong danh sách, bị mờ, kèm lý do, không chọn được |
| Nguồn sự thật | Backend tự tính. Mobile chỉ gửi `voucherCode`, không gửi số tiền giảm |
| Mã hết lượt lúc đặt | Checkout trả lỗi. Không tự bỏ mã và đặt tiếp |
| Đơn đã có | Không áp mã sau khi đã tạo đơn. Đơn cũ không bị đổi |

Bốn điều kiện áp mã, kiểm tra theo thứ tự này:

1. Voucher tồn tại và `isActive = true`, nếu không: `VOUCHER_NOT_FOUND`.
2. `startsAt <= now < endsAt`, nếu không: `VOUCHER_EXPIRED`. Chưa tới `startsAt` cũng dùng mã này.
3. `usageLimit` là null hoặc `usedCount < usageLimit`, và số redemption chưa trả của user nhỏ hơn `perUserLimit`, nếu không: `VOUCHER_USAGE_EXCEEDED`.
4. Tiền hàng trước thuế, chưa gồm phí ship, `>= minOrderAmount`, nếu không: `VOUCHER_MIN_ORDER_NOT_MET`.

**Không làm trong task này:** voucher freeship, ví lưu mã, tự áp mã tốt nhất, giới hạn theo sản phẩm/danh mục/phương thức thanh toán, chỉ cho đơn đầu tiên, giao diện admin.

## 3. Database

Thêm vào `apps/backend/prisma/schema.prisma`, theo đúng kiểu các model hiện có (`dbgenerated("gen_random_uuid()")`, `@map` snake_case, `@db.Timestamptz(3)`, `@db.Decimal(18, 0)`).

```prisma
enum VoucherType {
  PERCENT
  FIXED
}

model Voucher {
  id             String      @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  code           String      @unique
  type           VoucherType
  value          Decimal     @db.Decimal(18, 0)
  maxDiscount    Decimal?    @map("max_discount") @db.Decimal(18, 0)
  minOrderAmount Decimal     @default(0) @map("min_order_amount") @db.Decimal(18, 0)
  startsAt       DateTime    @map("starts_at") @db.Timestamptz(3)
  endsAt         DateTime    @map("ends_at") @db.Timestamptz(3)
  usageLimit     Int?        @map("usage_limit")
  perUserLimit   Int         @default(1) @map("per_user_limit")
  usedCount      Int         @default(0) @map("used_count")
  isPublic       Boolean     @default(true) @map("is_public")
  isActive       Boolean     @default(true) @map("is_active")
  createdAt      DateTime    @default(now()) @map("created_at") @db.Timestamptz(3)
  updatedAt      DateTime    @default(now()) @updatedAt @map("updated_at") @db.Timestamptz(3)

  redemptions VoucherRedemption[]

  @@index([isPublic, isActive, endsAt])
  @@map("vouchers")
}

model VoucherRedemption {
  id         String    @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  voucherId  String    @map("voucher_id") @db.Uuid
  userId     String    @map("user_id") @db.Uuid
  orderId    String    @unique @map("order_id") @db.Uuid
  code       String
  amount     Decimal   @db.Decimal(18, 0)
  releasedAt DateTime? @map("released_at") @db.Timestamptz(3)
  createdAt  DateTime  @default(now()) @map("created_at") @db.Timestamptz(3)

  voucher Voucher @relation(fields: [voucherId], references: [id])
  user    Profile @relation(fields: [userId], references: [id])
  order   Order   @relation(fields: [orderId], references: [id])

  @@index([voucherId, userId])
  @@index([userId])
  @@map("voucher_redemptions")
}
```

Thêm relation ngược: `Profile.voucherRedemptions VoucherRedemption[]`, `Order.voucherRedemption VoucherRedemption?`.

`invoices.discount_amount` và `invoice_items.discount_amount` đã tồn tại, không thêm cột. Redemption không bị xóa khi hủy đơn: `releasedAt` đánh dấu đã trả lượt, để giữ lịch sử và để replay idempotency vẫn so được mã.

### Migration

Tạo tay `apps/backend/prisma/migrations/20261101120000_add_vouchers/migration.sql`, gồm:

1. `CREATE TYPE`, `CREATE TABLE`, index, foreign key, khớp đúng schema.
2. CHECK constraint, cùng phong cách `20261004213000_constraints_and_security`:
   - `value > 0`
   - `type <> 'PERCENT' OR value <= 100`
   - `max_discount IS NULL OR max_discount > 0`
   - `min_order_amount >= 0`
   - `ends_at > starts_at`
   - `usage_limit IS NULL OR usage_limit > 0`
   - `per_user_limit > 0`
   - `used_count >= 0`
   - `amount >= 0`
3. Bảo mật giống `20261026203000_user_addresses/migration.sql`: `ENABLE ROW LEVEL SECURITY` cho cả 2 bảng, rồi `REVOKE ALL` từ `anon` và `authenticated` trong khối kiểm tra role tồn tại. Sao chép đúng mẫu đó, Supabase không tự chặn bảng mới.
4. Chốt dữ liệu cũ trước khi có bước tự hủy (mục 6), để đơn cũ không bị hủy hàng loạt:

```sql
UPDATE "payments"
SET "status" = 'EXPIRED'
WHERE "status" = 'PENDING' AND "expires_at" <= now();
```

Sau đó chạy `pnpm prisma:validate` và `pnpm prisma:generate`.

## 4. Backend: module voucher

Tạo `apps/backend/src/modules/vouchers/` theo quy ước: `voucher.routes.ts`, `voucher.schema.ts`, `voucher.controller.ts`, `voucher.service.ts`, `voucher.type.ts`, và file thuần `voucher-pricing.ts`.

Thêm vào `common/errors/error-codes.ts`:

| Code | HTTP | Khi nào |
|---|---|---|
| `VOUCHER_NOT_FOUND` | 404 | Không tồn tại hoặc không active |
| `VOUCHER_EXPIRED` | 422 | Ngoài thời hạn |
| `VOUCHER_USAGE_EXCEEDED` | 409 | Hết tổng lượt hoặc hết lượt của user |
| `VOUCHER_MIN_ORDER_NOT_MET` | 422 | Chưa đạt đơn tối thiểu |
| `VOUCHER_NOT_APPLICABLE` | 422 | Đơn SEPAY có `grandTotal = 0` (mục 5) |
| `VOUCHER_CODE_EXISTS` | 409 | Admin tạo trùng mã |
| `VOUCHER_IN_USE` | 409 | Admin xóa mã đã có redemption |

Thêm `details: { missingAmount }` cho `VOUCHER_MIN_ORDER_NOT_MET`.

### Tính tiền (`voucher-pricing.ts`)

Hàm thuần dùng `Prisma.Decimal`, không dùng số thực JS:

- `calculateDiscount(voucher, subtotal)`:
  - `FIXED`: `value`.
  - `PERCENT`: `floor(subtotal * value / 100)`, sau đó chặn bởi `maxDiscount` nếu có.
  - Luôn chặn tối đa bằng `subtotal`.
- `allocateDiscount(discount, lineSubtotals)`: chia theo tỷ lệ bằng làm tròn cộng dồn. Với `cum_i` là tổng subtotal từ dòng đầu đến dòng i và `S` là tổng toàn bộ: `alloc_i = floor(D * cum_i / S) - floor(D * cum_(i-1) / S)`. Cách này đảm bảo tổng đúng bằng `D` và không dòng nào âm.

### `VoucherService`

Một hàm kiểm tra dùng chung cho `available`, `validate` và checkout, đặt trong service và nhận `tx` để chạy được trong transaction:

- Input: voucher, `userId`, `subtotal`, `now`.
- Output: `{ eligible, discountAmount, reasonCode, missingAmount }`.

Không nhân bản logic kiểm tra ở nhiều nơi.

### API khách

Router dùng chung `authMiddleware, profileMiddleware, accountStatusMiddleware` như `carts/cart.routes.ts`. Đăng ký trong `app.ts`: `app.use("/api/v1/vouchers", voucherRoutes)` và `app.use("/api/v1/admin/vouchers", adminVoucherRoutes)`.

`subtotal` luôn đọc từ giỏ hàng trên server, chỉ tính sản phẩm `isActive`. Giỏ trống thì `subtotal = 0`.

**`GET /api/v1/vouchers/available`**

Trả voucher có `isPublic`, `isActive`, còn hạn, còn tổng lượt và user chưa dùng hết lượt. Chưa đủ đơn tối thiểu thì vẫn trả với `eligible: false`. Sắp xếp: `eligible` trước, rồi `discountAmount` giảm dần, rồi `endsAt` tăng dần.

```json
{
  "items": [
    {
      "code": "HOA50K",
      "type": "FIXED",
      "value": 50000,
      "maxDiscount": null,
      "minOrderAmount": 300000,
      "endsAt": "2026-12-31T16:59:59.000Z",
      "eligible": true,
      "discountAmount": 50000,
      "ineligibleReason": null,
      "missingAmount": 0
    }
  ],
  "subtotal": 320000
}
```

`ineligibleReason` khi chưa đủ điều kiện dùng dạng: `"Mua thêm 50.000đ để dùng"`.

**`POST /api/v1/vouchers/validate`**

- Body: `{ "code": "hoa50k" }`, strict. Schema: `trim`, `toUpperCase`, 3-32 ký tự, `^[A-Z0-9_-]+$`.
- 200: `{ "code": "HOA50K", "discountAmount": 50000, "subtotal": 320000 }`.
- Không giữ lượt, không ghi database.
- Không tìm thấy hoặc không đủ điều kiện: trả lỗi theo bảng trên.
- Mã `isPublic = false` vẫn dùng được ở endpoint này.

### API admin

Chuỗi middleware giống `adminCategoryRoutes` trong `categories/category.routes.ts`, có `requireRole(Role.ADMIN)`.

| Method | Path | Ghi chú |
|---|---|---|
| GET | `/api/v1/admin/vouchers` | Phân trang, `search` theo code, lọc `isActive`, `isPublic` |
| GET | `/api/v1/admin/vouchers/:id` | |
| POST | `/api/v1/admin/vouchers` | Trùng code: `VOUCHER_CODE_EXISTS` |
| PUT | `/api/v1/admin/vouchers/:id` | Không cho đổi `code`, `usedCount`, `type` |
| DELETE | `/api/v1/admin/vouchers/:id` | Có redemption: `VOUCHER_IN_USE`, chỉ được tắt bằng `isActive = false` |

Zod: `PERCENT` có `value` 1-100, `FIXED` không được có `maxDiscount`, `endsAt > startsAt`, tiền là số nguyên, `code` chuẩn hóa như trên. `usedCount` không bao giờ nhận từ client.

## 5. Backend: checkout

File chính: `src/modules/checkout/checkout.service.ts`, `checkout.schema.ts`, `checkout.type.ts`.

1. `checkoutSchema`: thêm `voucherCode` tùy chọn, cùng chuẩn hóa như `validate`, `.nullable().optional()`.
2. `checkoutOrderInclude`: thêm `voucherRedemption: { select: { code: true } }`.
3. `assertIdempotentReplay`: thêm so sánh `(order.voucherRedemption?.code ?? null) === (input.voucherCode ?? null)`.
4. `runCheckout`, giữ thứ tự sau:
   1. Đọc giỏ và kiểm tra tồn kho như hiện tại.
   2. Nếu có `voucherCode`: tìm voucher và kiểm tra bằng hàm dùng chung, sai thì ném lỗi.
   3. Tính giảm và chia cho từng dòng. Với mỗi dòng: `taxableAmount = subtotal - lineDiscount`, `taxAmount = taxable * taxRate / 100` làm tròn như hiện tại, `lineTotal = taxable + tax`.
   4. Tính phí ship như hiện tại.
   5. `grandTotal = subtotalAmount - discount + taxAmount + shippingFee`.
   6. Nếu `paymentMethod = SEPAY` và `grandTotal = 0`: ném `VOUCHER_NOT_APPLICABLE`. SePay không chuyển được 0đ.
   7. Trừ kho như hiện tại.
   8. **Sau khi trừ kho** mới giữ lượt:

      ```ts
      const claimed = await tx.voucher.updateMany({
        where: {
          id: voucher.id,
          isActive: true,
          OR: [{ usageLimit: null }, { usedCount: { lt: voucher.usageLimit ?? 0 } }],
        },
        data: { usedCount: { increment: 1 } },
      });
      if (claimed.count !== 1) throw /* VOUCHER_USAGE_EXCEEDED */;
      ```

      Giữ thứ tự kho rồi voucher, cùng thứ tự với luồng hủy, để hai transaction không khóa chéo nhau.
   9. Tạo order, sau đó tạo `VoucherRedemption` với `code`, `amount`, `orderId`, `userId`.
   10. `invoice.discountAmount` và `invoiceItem.discountAmount`, `taxableAmount`, `taxAmount`, `lineTotal` dùng số đã tính. `invoice.subtotalAmount` vẫn là tiền trước giảm.
5. Thêm `discountAmount` vào `CheckoutResponse.invoice`, vào `select` của `invoice.create`, và vào cả hai nơi map: cuối `runCheckout` và `mapExistingCheckout`.

Không có `voucherCode` thì kết quả phải y hệt hiện tại.

## 6. Backend: hủy đơn và thanh toán hết hạn

### Trả lượt khi hủy

Trong `src/modules/orders/order-state.ts`, hàm `cancelOrderInTransaction`, sau vòng lặp hoàn kho:

```ts
const released = await tx.voucherRedemption.updateMany({
  where: { orderId, releasedAt: null },
  data: { releasedAt: options.cancelledAt },
});
if (released.count > 0) {
  const redemption = await tx.voucherRedemption.findUnique({
    where: { orderId },
    select: { voucherId: true },
  });
  await tx.voucher.updateMany({
    where: { id: redemption!.voucherId, usedCount: { gt: 0 } },
    data: { usedCount: { decrement: 1 } },
  });
}
```

Điều kiện `releasedAt: null` đảm bảo không trả lượt hai lần.

### Tự hủy đơn khi thanh toán hết hạn

Hiện tại `payment.service.ts:32` và `payment-admin.service.ts:129` chỉ đổi status sang `EXPIRED`, không hủy đơn. Kho và lượt voucher vì thế bị giữ mãi. Trong repo cũng chưa có job chạy định kỳ.

1. Thêm option vào `cancelOrderInTransaction`: `bySystem?: boolean`. Khi `true`, nội dung thông báo là: `Đơn hàng ${order.orderNumber} đã tự hủy vì quá hạn thanh toán.`
2. Tạo `src/modules/payments/payment-expiry.service.ts` với `expireOverduePayments(where?)`:
   - Tìm payment `PENDING`, `expiresAt <= now`, tối đa 100 bản ghi mỗi lần.
   - Mỗi payment xử lý trong **một transaction riêng**: `updateMany` có điều kiện `status: PENDING` sang `EXPIRED`. Nếu `count = 1`, đọc order qua invoice. Chỉ khi order nằm trong `CANCELLABLE_STATUSES` và invoice chưa `PAID` thì gọi `cancelOrderInTransaction(tx, orderId, { cancelledAt, bySystem: true, byAdmin: false })`. Đơn ở trạng thái khác chỉ đổi payment sang `EXPIRED`.
   - Lỗi một payment thì log rồi xử lý tiếp, không làm hỏng request đang gọi.
3. Gọi hàm này ở:
   - `PaymentService.getStatus`, thay `updateMany` hiện tại, giới hạn theo `paymentId` và `userId`. `getStatus` vẫn phải trả `EXPIRED` ngay trong lần gọi đó.
   - `PaymentAdminService.listPayments`, thay `updateMany` hiện tại.
   - `src/server.ts`: `setInterval` mỗi 60 giây sau khi server listen, gọi `.unref()`, xóa timer khi shutdown. Bọc `catch` để không crash process.
4. Cập nhật test đang mock `tx.payment.updateMany` trong `tests/payment.service.test.cjs` nếu cần.

**Hệ quả đã chấp nhận:** khách chuyển khoản sau khi đơn tự hủy thì webhook đưa payment sang `REVIEW`, hóa đơn đã `CANCELLED` nên admin không ghép được giao dịch và phải hoàn tiền thủ công. Không tự thêm logic hoàn tiền.

## 7. Mobile

Thư mục: `apps/mobile/lib/features/checkout/`.

**Data**
- `models/checkout_request.dart`: thêm `voucherCode`, chỉ đưa vào `toJson` khi có giá trị. `CheckoutController` tính fingerprint từ `toJson()` nên đổi mã sẽ tự tạo `Idempotency-Key` mới, không cần sửa logic này.
- Model mới `models/voucher.dart`: `Voucher` map từ `available`, kèm `eligible`, `discountAmount`, `ineligibleReason`.
- `models/checkout_invoice.dart`: thêm `discountAmount`, mặc định 0 khi response thiếu.
- `data/checkout_remote_data_source.dart`: thêm `availableVouchers()` và `validateVoucher(code)`, dùng `_send` như các hàm hiện có.
- `data/checkout_repository.dart`, `checkout_repository_impl.dart`, `mock_checkout_repository.dart`: thêm 2 hàm tương ứng.
- `data/checkout_failure.dart`: thêm các mã `VOUCHER_*` khách có thể gặp.

**State**
- `state/checkout_controller.dart`, `_stateForFailure`: thêm message:
  - `VOUCHER_NOT_FOUND`: `Mã voucher không tồn tại.`
  - `VOUCHER_EXPIRED`: `Voucher đã hết hạn.`
  - `VOUCHER_USAGE_EXCEEDED`: `Voucher đã hết lượt sử dụng.`
  - `VOUCHER_MIN_ORDER_NOT_MET`: `Đơn hàng chưa đạt giá trị tối thiểu của voucher.`
  - `VOUCHER_NOT_APPLICABLE`: `Không thể thanh toán SePay cho đơn 0đ. Vui lòng chọn COD.`

**UI**
- `widgets/checkout_common.dart`: dòng giảm giá đã có ở dòng 577, không làm lại.
- `screens/checkout_screen.dart`:
  - Thêm dòng "Chọn voucher", dùng `CheckoutSurfaceCard`, đặt trước phần tóm tắt tiền.
  - Lưu `_voucher` trong state.
  - **Getter `_summary` hiện không truyền `discount`.** Phải truyền `discount: _voucher?.discountAmount ?? 0` và tính `grandTotal = subtotal - discount + tax + shipping`.
  - `_placeOrder` gửi `voucherCode`.
  - Checkout lỗi với mã `VOUCHER_*`: hiện message, bỏ chọn voucher, để khách bấm đặt lại. Không tự gửi lại.
  - Có nút bỏ chọn.
- Màn mới `screens/voucher_list_screen.dart`, mở bằng `Navigator.push`, trả về voucher đã chọn:
  - Ô nhập mã và nút "Áp dụng" ở trên, gọi `validateVoucher`.
  - Danh sách từ `availableVouchers`. Mã không đủ điều kiện thì mờ, không bấm được, hiện `ineligibleReason`.
  - Có trạng thái đang tải, lỗi có nút thử lại, và danh sách trống.
  - Tải lại mỗi lần mở màn.
- Dùng màu và kiểu chữ trong `utils/checkout_theme.dart`.
- Export màn và model mới trong `checkout.dart`.

**Sửa theo thay đổi ở mục 6**
- `screens/sepay_qr_screen.dart:96`: đổi `canCancel: status == 'EXPIRED'` thành `canCancel: false`. Đơn đã tự hủy phía server, gọi hủy nữa sẽ nhận `ORDER_CANNOT_CANCEL`. Sửa comment dòng 95 cho đúng.
- `screens/payment_failure_screen.dart`:
  - Dòng 9: comment "Backend không tự hủy đơn hết hạn" không còn đúng, sửa lại.
  - Dòng 126: đổi câu mời hủy đơn khi hết hạn thành: `Mã thanh toán đã hết hạn. Đơn hàng đã tự hủy, hàng và voucher đã được trả lại.`
  - Giữ nguyên nhánh `canCancel` ở `sepay_qr_screen.dart:125`, dùng cho lỗi không lấy được trạng thái.
- Màn QR, màn thành công và `OrderSuccessScreen` vẫn lấy số tiền từ `result.invoice`.

## 8. Seed

Trong `apps/backend/prisma/seed.ts`, `upsert` theo `code`. `startsAt` là thời điểm chạy seed, `endsAt` là 90 ngày sau. Sản phẩm hoa trong seed có giá 250.000đ và 320.000đ.

| Code | Type | Value | Max | Min | Limit | Public |
|---|---|---|---|---|---|---|
| `HOA50K` | FIXED | 50000 | | 300000 | 100 | Có |
| `HOA20` | PERCENT | 20 | 100000 | 200000 | 100 | Có |
| `HOAVIP` | FIXED | 100000 | | 500000 | 10 | Không |

## 9. Test

Backend dùng `node:test`. Đặt test mới cạnh code (`*.test.ts`), hoặc trong `tests/*.test.cjs` nếu sửa test có sẵn. Phải có:

- `voucher-pricing`: percent, cap `maxDiscount`, fixed lớn hơn subtotal, chia nhiều dòng có tổng đúng bằng `D`, không dòng nào âm, tiền lẻ.
- `VoucherService`: từng lý do không đủ điều kiện, `perUserLimit` không tính redemption đã `releasedAt`, sắp xếp `available`.
- Checkout:
  - Không voucher: kết quả không đổi so với trước.
  - Có voucher: thuế tính sau giảm, `grandTotal` đúng, `invoice` và `invoiceItem` đúng.
  - `updateMany` trả `count = 0`: báo `VOUCHER_USAGE_EXCEEDED`, không tạo đơn.
  - Replay cùng key khác `voucherCode`: `CHECKOUT_CONFLICT`.
  - SEPAY với `grandTotal = 0`: `VOUCHER_NOT_APPLICABLE`.
- Hủy đơn: trả lượt đúng một lần khi hủy hai lần, đơn không voucher không lỗi.
- Hết hạn: order `PENDING` bị hủy và hoàn kho, order `PREPARING` chỉ đổi payment, lỗi một payment không chặn payment khác.
- Admin route: USER nhận 403, xóa mã đã dùng nhận `VOUCHER_IN_USE`.

Mobile, trong `test/features/checkout/`:

- `CheckoutRequest.toJson` có và không có `voucherCode`.
- Đổi voucher tạo `Idempotency-Key` mới.
- Dòng giảm giá và tổng tiền đúng sau khi chọn mã.
- Mã không đủ điều kiện không bấm được.
- Lỗi `VOUCHER_*` khi đặt: hiện message và bỏ chọn mã.
- **Sửa test có sẵn** `EXPIRED leads to failure and the order can be cancelled` trong `checkout_flow_test.dart`: `EXPIRED` không còn nút hủy.

## 10. Kiểm tra trước khi báo xong

Chạy và dán kết quả thật. Không được báo pass nếu chưa chạy.

```bash
pnpm prisma:validate
pnpm prisma:generate
pnpm typecheck:backend
pnpm --filter @plant-flower/backend test
pnpm --filter @plant-flower/backend test:checkout
pnpm --filter @plant-flower/backend test:payment

cd apps/mobile
flutter analyze
flutter test
```

Báo cáo cuối gồm: file đã đổi, kết quả từng lệnh, những gì chưa kiểm chứng được, và lệnh `prisma migrate deploy` đang chờ chủ dự án cho phép.

## 11. Cập nhật tài liệu

`docs/spec.md`: thêm mục voucher (bảng, API, error code, quy tắc) nếu tài liệu này có phần tương ứng. Nếu API có Swagger trong backend, cập nhật theo cách các module khác đang làm.

## 12. Thứ tự làm

1. Schema, migration, generate.
2. Error code, `voucher-pricing.ts` và test.
3. `VoucherService`, API khách.
4. Checkout.
5. Trả lượt khi hủy, tự hủy khi hết hạn.
6. API admin.
7. Seed.
8. Mobile.
9. Chạy mục 10.
