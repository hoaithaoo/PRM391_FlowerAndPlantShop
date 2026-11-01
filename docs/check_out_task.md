# Tích hợp Giỏ hàng → Checkout → Thanh toán SePay (Mobile)

Tài liệu cho team mobile nối luồng mua hàng với backend thật. Mọi API dưới đây **đã chạy trên Render**.
Xem và gọi thử tất cả API tại Swagger: https://prm391-flowerandplantshop.onrender.com/api/docs

## 0. Thông tin chung

| Mục | Giá trị |
|---|---|
| Base URL | `https://prm391-flowerandplantshop.onrender.com/api/v1` |
| Chạy app | `flutter run --dart-define=API_BASE_URL=https://prm391-flowerandplantshop.onrender.com` |
| Xác thực | Header `Authorization: Bearer <Supabase access token>` (lấy từ `supabase.auth.currentSession?.accessToken`) |
| Content-Type | `application/json` |
| Tiền | Số nguyên VND (`350000`), không có phần thập phân |

Render gói free ngủ khi không có request: **lần gọi đầu có thể mất 30–60 giây**. Đặt timeout ≥ 60s, hoặc gọi `/health` khi mở app để đánh thức server.

### Dạng response

Thành công:
```json
{ "success": true, "data": { ... }, "meta": { "requestId": "req_...", "timestamp": "..." } }
```
Lỗi — **luôn đọc `error.code`** để quyết định hiển thị, không dựa vào `message`:
```json
{ "success": false, "error": { "code": "PRODUCT_OUT_OF_STOCK", "message": "...", "details": null }, "meta": { ... } }
```

| HTTP | `error.code` | Xử lý trên app |
|---|---|---|
| 401 | `AUTH_TOKEN_MISSING`, `AUTH_TOKEN_INVALID` | Token hết hạn → refresh session Supabase rồi gọi lại; vẫn lỗi thì về màn đăng nhập |
| 403 | `ACCOUNT_DISABLED` | Tài khoản bị khóa → đăng xuất, báo người dùng |
| 403 | `FORBIDDEN` | Đang đăng nhập tài khoản ADMIN (API user chỉ cho role USER) |
| 422 | `VALIDATION_ERROR` | Dữ liệu gửi sai; chi tiết trong `error.details.fieldErrors` |

---

## 1. Luồng tổng quát

```
Màn sản phẩm ── POST /cart/items ──► giỏ hàng lưu trên server
Màn giỏ hàng ── GET /cart, PUT/DELETE /cart/items/:id
Màn checkout ── GET /stores/shipping-estimate (xem trước phí ship)
             ── POST /checkout  ──► server tính tiền, trừ kho, tạo đơn, XÓA món đã đặt khỏi giỏ
                                    trả qrUrl + paymentCode (SEPAY) hoặc payment = null (COD)
Màn QR       ── hiển thị qrUrl, mỗi 3 giây GET /payments/:id/status
SePay        ── (khách chuyển khoản) ──► webhook ──► server đánh dấu PAID
Màn QR       ── thấy status = PAID ──► màn thành công
```

Quan trọng: **checkout không nhận danh sách sản phẩm hay tổng tiền từ app**. Server đọc giỏ hàng đã lưu qua API. Vì vậy mọi thao tác giỏ hàng phải đi qua API, không chỉ giữ local.

---

## 2. Giỏ hàng

### 2.1 Xem giỏ — `GET /cart`
```json
{
  "id": "cart-uuid",
  "items": [
    { "id": "cart-item-uuid", "productId": "product-uuid", "name": "Lan hồ điệp trắng",
"price": 350000, "quantity": 2, "subtotal": 700000 }
  ],
  "totalQuantity": 2,
  "subtotal": 700000
}
```
- Chưa có giỏ thì `items` rỗng, không lỗi.
- `items[].id` là **id dòng giỏ hàng** — dùng cho sửa/xóa. Khác với `productId`.
- Không có ảnh sản phẩm trong response; cần ảnh thì lấy từ `GET /products/:productId` (hoặc cache từ màn danh sách).

### 2.2 Thêm vào giỏ — `POST /cart/items` → `201`
```json
{ "productId": "product-uuid", "quantity": 1 }
```
- Sản phẩm đã có trong giỏ → **cộng dồn** số lượng.
- Response: `{ "id": "cart-item-uuid", "productId": "...", "quantity": 3, "subtotal": 1050000 }`

### 2.3 Đổi số lượng — `PUT /cart/items/:cartItemId`
```json
{ "quantity": 3 }
```
`quantity` là số lượng **mới** (không phải số cộng thêm), tối thiểu 1. Muốn về 0 thì gọi xóa.

### 2.4 Xóa — `DELETE /cart/items/:cartItemId` → `204` (không có body)

### Lỗi giỏ hàng
| HTTP | `error.code` | Hiển thị |
|---|---|---|
| 404 | `PRODUCT_NOT_FOUND` | "Sản phẩm không còn bán" |
| 404 | `CART_ITEM_NOT_FOUND` | Tải lại giỏ (dòng đã bị xóa ở nơi khác) |
| 409 | `PRODUCT_OUT_OF_STOCK` | "Không đủ hàng" — tổng số lượng trong giỏ vượt tồn kho |

---

## 3. Phí ship (xem trước) — `GET /stores/shipping-estimate?latitude=..&longitude=..`

Không cần token.
```json
{
  "store": { "id": "...", "name": "Plant & Flower Shop - Quận 1", "address": "...", "latitude": 10.7756, "longitude": 106.7004 },
  "distanceKm": 1.6,
  "shippingFee": 15000,
  "estimatedDeliveryMinutes": 20,
  "currency": "VND"
}
```
Phí: 15.000đ cho 2 km đầu, mỗi km tiếp theo +5.000đ (tính từ cửa hàng gần nhất). Số tiền cuối cùng do `POST /checkout` quyết định.

---

## 4. Đặt hàng — `POST /checkout` → `201`

Header thêm: **`Idempotency-Key: <uuid>`** — sinh **một lần** khi mở màn checkout và giữ nguyên nếu người dùng bấm lại / mạng lỗi rồi gửi lại. Cùng key + cùng dữ liệu → server trả lại đúng đơn cũ, không tạo đơn thứ hai.

Body:
```json
{
  "receiverName": "Pham Dinh",
  "phone": "0901234567",
  "address": "15 Nguyễn Thiện Thuật, Quận 3, TP.HCM",
  "latitude": 10.7703,
  "longitude": 106.6822,
  "paymentMethod": "SEPAY",
  "note": "Giao giờ hành chính"
}
```
- `latitude`, `longitude` **bắt buộc** (thiếu → 422). Lấy từ địa chỉ đã lưu (`/addresses`) hoặc vị trí hiện tại.
- `phone`: số VN dạng `0xxxxxxxxx` hoặc `+84xxxxxxxxx`.
- `paymentMethod`: `SEPAY` hoặc `COD`.

Response:
```json
{
  "order":   { "id": "order-uuid", "orderCode": "ORD-20261101-ABCDEF123456", "status": "PENDING" },
  "invoice": { "id": "invoice-uuid", "invoiceNumber": "INV-...", "status": "ISSUED",
               "subtotalAmount": 700000, "taxAmount": 0, "shippingFee": 15000, "grandTotal": 715000 },
"payment": { "id": "payment-uuid", "paymentCode": "PAY20261101ABCDEF123456",
               "qrUrl": "https://qr.sepay.vn/img?acc=...&bank=...&amount=715000&des=PAY20261101ABCDEF123456&template=compact",
               "status": "PENDING" }
}
```
- COD → `payment: null`, chuyển thẳng sang màn đặt hàng thành công.
- Sau khi thành công, gọi lại `GET /cart`: các món vừa đặt đã bị xóa khỏi giỏ.
- App đã có sẵn `CheckoutRemoteDataSource`, `CheckoutRequest`, `CheckoutResult` khớp với API này — chỉ cần thay `CheckoutMockData` bằng dữ liệu thật.

### Lỗi checkout
| HTTP | `error.code` | Hiển thị |
|---|---|---|
| 422 | `CART_EMPTY` | "Giỏ hàng trống" |
| 409 | `PRODUCT_OUT_OF_STOCK` | "Một sản phẩm vừa hết hàng" — `error.details.productId` cho biết sản phẩm nào; tải lại giỏ |
| 409 | `CHECKOUT_CONFLICT` | Gửi lại sau 1–2 giây (giữ nguyên Idempotency-Key) |
| 404 | `STORE_NOT_FOUND` | "Hiện không có cửa hàng phục vụ" |

---

## 5. Màn QR và chờ thanh toán

Hiển thị:
```dart
Image.network(payment.qrUrl!)       // ảnh VietQR, khách quét bằng app ngân hàng
Text(payment.paymentCode!)           // nội dung chuyển khoản (nút "Sao chép")
Text(formatVnd(invoice.grandTotal))  // số tiền phải chuyển đúng tuyệt đối
Text(order.orderCode)
```
Nếu `qrUrl == null` (server chưa cấu hình tài khoản nhận) thì hiển thị `paymentCode` + số tiền để khách chuyển tay.

Khách phải chuyển **đúng số tiền** và **nội dung chứa `paymentCode`**. Mã có hiệu lực **15 phút**.

### Kiểm tra trạng thái — `GET /payments/:paymentId/status`
```json
{ "id": "payment-uuid", "invoiceId": "...", "provider": "SEPAY", "paymentCode": "PAY...",
  "amount": 715000, "status": "PENDING", "paidAt": null }
```

| `status` | Ý nghĩa | App làm gì |
|---|---|---|
| `PENDING` | Chưa nhận tiền | Tiếp tục chờ |
| `PAID` | Đã nhận đủ tiền | Dừng polling → màn thành công |
| `EXPIRED` | Quá 15 phút chưa trả | Dừng → màn thất bại, có nút "Hủy đơn" |
| `FAILED` | Đơn đã bị hủy | Dừng → màn thất bại |
| `REVIEW` | Nhận tiền nhưng sai số tiền / trả trễ | Dừng → "Thanh toán đang được cửa hàng kiểm tra" |

```dart
Timer? _poll;

void _startPolling(String paymentId) {
  _poll = Timer.periodic(const Duration(seconds: 3), (_) async {
    final status = await paymentApi.getStatus(paymentId); // data.status
    if (!mounted) return;
    switch (status) {
      case 'PAID':
        _poll?.cancel();
        // → PaymentSuccessScreen
      case 'EXPIRED' || 'FAILED':
        _poll?.cancel();
        // → PaymentFailureScreen
      case 'REVIEW':
        _poll?.cancel();
        // → thông báo đang kiểm tra
      default:
        break; // PENDING
    }
  });
}

@override
void dispose() {
_poll?.cancel(); // bắt buộc, tránh timer chạy ngầm
  super.dispose();
}
```
Ngoài polling, server cũng tạo thông báo (`GET /notifications`) "Thanh toán thành công" khi nhận tiền.

### Hủy đơn chưa thanh toán — `PATCH /orders/:orderId/cancel`
Body (tùy chọn): `{ "reason": "Hết hạn thanh toán" }`. Hoàn kho, hủy hóa đơn. Chỉ hủy được đơn `PENDING`/`CONFIRMED` **chưa thanh toán** (ngược lại → 409 `ORDER_CANNOT_CANCEL`).
Backend **không tự hủy** đơn hết hạn, nên màn thất bại nên gọi API này để trả hàng về kho.

---

## 6. Sau khi đặt hàng

| API | Dùng cho |
|---|---|
| `GET /orders?page=1&status=PENDING` | Danh sách đơn của tôi (`data.items`, phân trang trong `meta`) |
| `GET /orders/:id` | Chi tiết đơn: `items`, `paymentStatus`, `paymentId`, `invoiceId` |
| `GET /invoices/:id` | Hóa đơn: từng dòng có `taxRate`, `taxAmount`, `lineTotal` |

---

## 7. Gọi thử bằng terminal (không cần app)

```bash
B=https://prm391-flowerandplantshop.onrender.com/api/v1

# 1) Đăng nhập lấy token (tài khoản USER)
TOKEN=$(curl -s -X POST $B/auth/login -H 'Content-Type: application/json' \
  -d '{"email":"user@example.com","password":"..."}' | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
H="Authorization: Bearer $TOKEN"

# 2) Lấy một sản phẩm và thêm vào giỏ
PID=$(curl -s "$B/products?limit=1" | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["items"][0]["id"])')
curl -s -X POST $B/cart/items -H "$H" -H 'Content-Type: application/json' -d "{\"productId\":\"$PID\",\"quantity\":1}"
curl -s $B/cart -H "$H"

# 3) Đặt hàng SEPAY
curl -s -X POST $B/checkout -H "$H" -H 'Content-Type: application/json' -H "Idempotency-Key: $(uuidgen)" \
  -d '{"receiverName":"Test","phone":"0901234567","address":"Quận 3, TP.HCM","latitude":10.7703,"longitude":106.6822,"paymentMethod":"SEPAY"}'

# 4) Kiểm tra trạng thái (thay PAYMENT_ID)
curl -s $B/payments/PAYMENT_ID/status -H "$H"
```

Lưu ý: bước 3 tạo đơn thật và trừ kho. Thử xong thì hủy: `curl -s -X PATCH $B/orders/ORDER_ID/cancel -H "$H"`.

### Thử thanh toán không cần chuyển tiền thật
Trên my.sepay.vn, dùng chức năng **giả lập giao dịch** cho tài khoản ngân hàng đã liên kết, với:
- Số tiền = `invoice.grandTotal`
- Nội dung = `payment.paymentCode`

Vài giây sau `GET /payments/:id/status` trả `PAID`, đơn và hóa đơn chuyển sang đã thanh toán.

---

## 8. Checklist cho mobile

- [ ] Có đăng nhập Supabase và lấy được access token (nhánh `mobile/user/feature/auth-screens` chưa merge)
- [ ] Lớp gọi API chung tự gắn `Authorization`, xử lý 401 (refresh token)
- [ ] Giỏ hàng: thêm / xem / sửa / xóa qua API
- [ ] Checkout: gửi tọa độ thật + `Idempotency-Key`
- [ ] Màn QR: dùng `qrUrl`, `paymentCode`, `grandTotal` thật (bỏ `CheckoutMockData`)
- [ ] Polling `/payments/:id/status` mỗi 3s, hủy timer trong `dispose`
- [ ] Màn thất bại có nút hủy đơn (`PATCH /orders/:id/cancel`)
- [ ] Tải lại giỏ sau khi đặt hàng thành công