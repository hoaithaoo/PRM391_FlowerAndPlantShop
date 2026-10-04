**PLANT & FLOWER STORE**

**Backend & REST API Technical Specification v1.2**

Flutter Mobile \+ Node.js \+ Express \+ Prisma \+ Supabase \+ SePay \+ OpenStreetMap \+ Chatbot

| Document version | 1.2 |
| :---- | :---- |
| Status | Revised API contract \- USER \+ ADMIN \+ CHATBOT |
| Backend | Node.js 24 LTS \+ Express 5 \+ TypeScript |
| Database / Auth | Supabase PostgreSQL \+ Supabase Auth |
| ORM | Prisma ORM 7.x |
| Payment | SePay |
| Map | OpenStreetMap \+ flutter\_map \+ geolocator |

*Mục tiêu: tài liệu dùng trực tiếp để chia task, tạo database, code Node.js, viết Swagger/Postman và tích hợp Flutter.*

**1\. Phạm vi hệ thống**  
Ứng dụng mobile bán cây, hoa và phụ kiện. Supabase đảm nhiệm PostgreSQL \+ Authentication; Flutter gọi Supabase Auth trực tiếp cho Google OAuth 2.0 / Email OTP. Sau khi login, Flutter gửi Supabase access token đến REST API Node.js. Backend verify token, đồng bộ profile, kiểm tra ACTIVE/DISABLED và phân quyền USER/ADMIN trước khi chạy business logic.

| Vai trò | Chức năng chính |
| :---- | :---- |
| USER | Xem sản phẩm, giỏ hàng, checkout, thanh toán SePay, xem đơn/hóa đơn/thông báo, dùng map và chatbot. |
| ADMIN | Quản lý category/product, người dùng, đơn hàng, hóa đơn, payment/SePay transaction và dashboard. |
| CHATBOT | Trợ lý trong app: hỏi về sản phẩm, cách chăm cây, chính sách cơ bản; không phải chat Customer ↔ Shop. |

**1.1 Kiến trúc**

| Flutter Mobile  ├─ Supabase Auth  │    ├─ Google OAuth 2.0  │    └─ Email OTP  ├─ flutter\_map \+ OpenStreetMap \+ geolocator  └─ HTTPS REST API         ↓Node.js 24 LTS \+ Express 5 \+ TypeScript  ├─ Supabase JWT authentication middleware  ├─ USER / ADMIN role guard  ├─ Zod validation  ├─ Controller → Service → Prisma  ├─ Global exception handler  ├─ Chatbot module  └─ SePay webhook         ↓Supabase PostgreSQL |
| :---- |

**2\. Technology baseline**

| Component | Version / branch | Decision |
| :---- | :---- | :---- |
| Node.js | 24.x LTS | Runtime backend. |
| Express | 5.2.x | REST routing \+ middleware. |
| TypeScript | 5.9+ | strict=true. |
| Prisma ORM | 7.x | Database ORM. |
| Supabase JS | 2.x | Verify auth/session where required. |
| Zod | 4.x | Request validation. |
| Helmet | 8.x | Security headers. |
| SePay | Webhook \+ QR | Payment confirmation. |
| Flutter map | flutter\_map | OSM map without Google billing. |

**3\. Authentication & authorization**  
Node.js không tạo endpoint /login. Login Google OAuth 2.0 và Email OTP do Flutter \+ Supabase Auth xử lý. Sau khi login, Flutter gửi access token vào header Authorization.

| Authorization: Bearer \<supabase\_access\_token\> |
| :---- |

| Case | HTTP | error.code |
| :---- | :---- | :---- |
| Thiếu token | 401 | AUTH\_TOKEN\_MISSING |
| Token sai / hết hạn | 401 | AUTH\_TOKEN\_INVALID |
| Đúng token nhưng thiếu role ADMIN | 403 | FORBIDDEN |
| Account bị khóa | 403 | ACCOUNT\_DISABLED |

**3.1 Role model**

| Field | Type | Example | Meaning |
| :---- | :---- | :---- | :---- |
| profiles.role | enum | USER / ADMIN | Quyền business. |
| profiles.status | enum | ACTIVE / DISABLED | Cho phép backend khóa account business. |
| profiles.id | uuid | same as auth.users.id | Liên kết Supabase Auth. |

3.2 Phân chia trách nhiệm Auth: Supabase vs Node.js  
Supabase chịu trách nhiệm xác thực danh tính (authentication). Node.js chịu trách nhiệm kiểm tra access token, đồng bộ hồ sơ ứng dụng, trạng thái tài khoản và phân quyền (authorization) trước khi cho phép truy cập business API.

| Hạng mục | Supabase Auth | Node.js Backend |
| :---- | :---- | :---- |
| Google OAuth 2.0 | Có \- xử lý đăng nhập Google và session | Không tự implement Google OAuth |
| Email OTP | Có \- gửi/verify OTP và tạo session | Không tự gửi/verify OTP |
| Access token / refresh session | Có | Chỉ nhận access token từ Flutter |
| Verify request đang đăng nhập | Cấp token | Có \- verify token cho API được bảo vệ |
| Lấy userId/email tin cậy | Có trong user/token | Có \- lấy từ token đã verify, không lấy từ body |
| profiles trong app DB | Không | Có \- find/create/sync profile |
| Trạng thái ACTIVE/DISABLED | Không phải business rule chính | Có \- chặn tài khoản DISABLED |
| Role USER/ADMIN | Có thể có metadata nhưng không dùng client tự quyết | Có \- kiểm tra role từ DB |
| Bảo vệ /api/v1/admin/\* | Không | Có \- role guard ADMIN |

3.3 Luồng đăng nhập Google / Email OTP

| Flutter Mobile   │   ├─ Google OAuth 2.0 hoặc Email OTP   ▼Supabase Auth   │  xác thực thành công   │  trả Session \+ access\_token   ▼Flutter   │   │ Authorization: Bearer \<supabase\_access\_token\>   ▼Node.js / Express   │   ├─ authMiddleware: verify token   ├─ profileMiddleware: find/create profile   ├─ accountStatusMiddleware: ACTIVE / DISABLED   ├─ roleMiddleware: USER / ADMIN (nếu endpoint yêu cầu)   ▼Controller → Service → Prisma → Supabase PostgreSQL |
| :---- |

Backend không có POST /login và không nhận Google password/OTP. Flutter chỉ gửi Supabase access token khi gọi REST API.

3.4 First-login profile synchronization  
Sau khi Supabase xác thực thành công, protected request đầu tiên (ví dụ GET /api/v1/profile) sẽ đi qua middleware. Backend lấy supabaseUser.id từ token. Nếu profiles chưa tồn tại, backend tạo hồ sơ mặc định với role=USER và status=ACTIVE. Nếu đã tồn tại, backend dùng hồ sơ hiện tại để kiểm tra quyền.

| Bước | Xử lý backend | Kết quả |
| :---- | :---- | :---- |
| 1 | Verify Supabase access token | Có user.id/email tin cậy |
| 2 | Prisma findUnique profiles.id \= user.id | Tìm profile ứng dụng |
| 3A | Không có profile → create | role=USER, status=ACTIVE |
| 3B | Đã có profile → giữ role/status từ DB | Không cho client tự đổi role |
| 4 | Check status | DISABLED → 403 ACCOUNT\_DISABLED |
| 5 | Check role nếu route yêu cầu | Sai role → 403 FORBIDDEN |
| 6 | Gắn req.auth / req.profile | Controller được phép chạy |

| // Pseudo-code: sync profile after token verificationconst user \= verifiedSupabaseUser;let profile \= await prisma.profile.findUnique({  where: { id: user.id }});if (\!profile) {  profile \= await prisma.profile.create({    data: {      id: user.id,      email: user.email,      role: "USER",      status: "ACTIVE"    }  });}req.auth \= { userId: user.id, email: user.email };req.profile \= profile; |
| :---- |

3.5 Middleware chain chuẩn

| Middleware | Nhiệm vụ | Nếu fail |
| :---- | :---- | :---- |
| authMiddleware | Đọc Bearer token và verify với Supabase | 401 AUTH\_TOKEN\_MISSING / AUTH\_TOKEN\_INVALID |
| profileMiddleware | Find/create profiles bằng UUID Supabase | 500 PROFILE\_SYNC\_FAILED |
| accountStatusMiddleware | Kiểm tra profile.status | 403 ACCOUNT\_DISABLED |
| requireRole("ADMIN") | Kiểm tra profile.role \=== ADMIN | 403 FORBIDDEN |
| validationMiddleware | Validate params/query/body bằng Zod | 400 VALIDATION\_ERROR |

| // USER routerouter.get(  "/profile",  authMiddleware,  profileMiddleware,  accountStatusMiddleware,  profileController.getMe);// ADMIN routerouter.get(  "/admin/products",  authMiddleware,  profileMiddleware,  accountStatusMiddleware,  requireRole("ADMIN"),  adminProductController.list); |
| :---- |

3.6 Contract của request có authentication

| Field | Vị trí | Bắt buộc | Ví dụ | Ghi chú |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Có với protected API | Bearer eyJhbGciOi... | Supabase access token |
| Content-Type | Header | Có khi gửi JSON | application/json | POST/PUT/PATCH |
| userId | Body | Không | \- | Không tin userId do client gửi; backend lấy từ token |
| role | Body | Không | \- | Không cho Flutter tự gửi role để nâng quyền |
| status | Body | Không | \- | Status tài khoản do backend/admin quản lý |

| GET /api/v1/profileAuthorization: Bearer \<supabase\_access\_token\>200 OK{  "success": true,  "data": {    "id": "2f0d...uuid",    "email": "user@example.com",    "fullName": "Nguyen Van A",    "avatarUrl": null,    "phone": null,    "role": "USER",    "status": "ACTIVE"  },  "meta": {    "requestId": "req\_...",    "timestamp": "2026-10-03T16:00:00.000Z"  }} |
| :---- |

3.7 Auth / authorization exceptions

| Case | HTTP | error.code | Khi nào xảy ra |
| :---- | :---- | :---- | :---- |
| Không có Authorization header | 401 | AUTH\_TOKEN\_MISSING | Protected API được gọi nhưng không có Bearer token |
| Token sai / hết hạn / không verify được | 401 | AUTH\_TOKEN\_INVALID | Supabase không xác nhận được user |
| Tài khoản ứng dụng bị khóa | 403 | ACCOUNT\_DISABLED | profile.status \= DISABLED |
| USER gọi ADMIN endpoint | 403 | FORBIDDEN | profile.role không đủ quyền |
| Không sync/tạo profile được | 500 | PROFILE\_SYNC\_FAILED | Lỗi DB khi first login/profile sync |
| Supabase Auth tạm thời không truy cập được | 503 | AUTH\_PROVIDER\_UNAVAILABLE | Provider/network lỗi và backend không verify được token |

| {  "success": false,  "error": {    "code": "AUTH\_TOKEN\_INVALID",    "message": "Invalid or expired access token"  },  "meta": {    "requestId": "req\_...",    "timestamp": "2026-10-03T16:00:00.000Z"  }} |
| :---- |

3.8 Quy tắc role ADMIN  
Tài khoản mới luôn được tạo với role=USER. Flutter không được gửi role=ADMIN khi đăng ký hoặc update profile. ADMIN phải được cấp quyền từ môi trường quản trị/DB hoặc một admin endpoint được bảo vệ. Backend luôn đọc role hiện tại từ profiles trước khi xử lý /api/v1/admin/\* để tránh privilege escalation.

| Route pattern | USER | ADMIN |
| :---- | :---- | :---- |
| /api/v1/profile, /products, /cart, /orders, /invoices, /chatbot/\* | Được phép (theo contract) | Được phép nếu dùng như user |
| /api/v1/admin/\* | 403 FORBIDDEN | Được phép |
| /api/v1/webhooks/sepay | Không dùng Bearer user token | Không dùng Bearer user token; xác thực webhook riêng |

3.9 Logout và token hết hạn  
Logout chủ yếu do Flutter gọi Supabase Auth signOut(). Khi access token hết hạn, Flutter/Supabase SDK xử lý refresh session theo cơ chế của Supabase. Nếu Flutter gửi token không còn hợp lệ, backend trả 401 AUTH\_TOKEN\_INVALID; Flutter phải refresh/re-login rồi gửi lại request. Backend không lưu password, OTP hoặc Google credential.

3.10 Security checklist cho auth  
• Không đặt Supabase service\_role key trong Flutter.

• Không tin userId, role, status do client gửi trong request body.

• Mọi protected API phải qua authMiddleware.

• Mọi /api/v1/admin/\* phải qua requireRole("ADMIN").

• Webhook SePay dùng cơ chế xác thực riêng; không dùng user JWT.

• Log requestId và error.code; không log access token, OTP hoặc secret.

• Không trả raw Supabase/Prisma exception trực tiếp cho Flutter.

**4\. Chuẩn response và exception**

**4.1 Success response**

| {  "success": true,  "data": { },  "meta": {    "requestId": "req\_...",    "timestamp": "2026-10-03T15:00:00.000Z"  }} |
| :---- |

**4.2 Error response**

| {  "success": false,  "error": {    "code": "PRODUCT\_NOT\_FOUND",    "message": "Không tìm thấy sản phẩm.",    "details": null  },  "meta": {    "requestId": "req\_...",    "timestamp": "2026-10-03T15:00:00.000Z",    "path": "/api/v1/products/..."  }} |
| :---- |

**Flutter xử lý theo HTTP status \+ error.code, không dựa vào text message.**

**4.3 HTTP statuses**

| HTTP | Use case | Example error.code |
| :---- | :---- | :---- |
| 200 | GET/PATCH thành công | \- |
| 201 | Tạo resource | \- |
| 204 | DELETE thành công, không body | \- |
| 400 | JSON/param/query malformed | BAD\_REQUEST |
| 401 | Chưa xác thực | AUTH\_TOKEN\_INVALID |
| 403 | Không đủ quyền / bị khóa | FORBIDDEN / ACCOUNT\_DISABLED |
| 404 | Resource không có | \*\_NOT\_FOUND |
| 409 | Conflict/duplicate/stock/state | DUPLICATE\_RESOURCE / INVALID\_STATE |
| 422 | Validation/business input | VALIDATION\_ERROR / CART\_EMPTY |
| 429 | Rate limit | RATE\_LIMITED |
| 500 | Unhandled backend | INTERNAL\_ERROR |
| 502 | Upstream provider error | UPSTREAM\_ERROR |
| 503 | Service/database unavailable | SERVICE\_UNAVAILABLE |
| 504 | Provider timeout | UPSTREAM\_TIMEOUT |

**4.4 AppError \+ global exception**

| export class AppError extends Error {  constructor(    public statusCode: number,    public code: string,    message: string,    public details?: unknown,  ) {    super(message);  }}// Examplethrow new AppError(  404,  'PRODUCT\_NOT\_FOUND',  'Không tìm thấy sản phẩm'); |
| :---- |

| export const errorHandler: ErrorRequestHandler \=(err, req, res, \_next) \=\> {  if (err instanceof AppError) {    return res.status(err.statusCode).json(toErrorBody(err, req));  }  if (err instanceof ZodError) {    return res.status(422).json(toErrorBody(      new AppError(        422,        'VALIDATION\_ERROR',        'Dữ liệu không hợp lệ',        err.flatten()      ),      req    ));  }  // Prisma known errors \-\> 404/409...  // Unknown errors \-\> 500 INTERNAL\_ERROR}; |
| :---- |

**5\. Data model MVP**

| Table | Role |
| :---- | :---- |
| profiles | User profile \+ role \+ status |
| categories | Danh mục |
| products | Cây / hoa / phụ kiện |
| carts | Giỏ hàng user |
| cart\_items | Item trong cart |
| orders | Đơn hàng |
| order\_items | Snapshot item khi order |
| invoices | Hóa đơn |
| invoice\_items | Snapshot giá \+ tax |
| payments | Yêu cầu thanh toán |
| sepay\_transactions | Webhook transaction từ SePay |
| notifications | Thông báo |
| stores | Vị trí cửa hàng |
| chatbot\_conversations | Phiên chatbot của user |
| chatbot\_messages | USER/ASSISTANT message |

**5.1 Invoice tax**

| Field | Type | Meaning |
| :---- | :---- | :---- |
| invoice\_items.unit\_price | decimal(18,0) | Đơn giá snapshot. |
| invoice\_items.quantity | int | Số lượng. |
| invoice\_items.discount\_amount | decimal(18,0) | Giảm giá dòng. |
| invoice\_items.taxable\_amount | decimal(18,0) | Tiền chịu thuế. |
| invoice\_items.tax\_rate | decimal(5,2) | Thuế suất snapshot. |
| invoice\_items.tax\_amount | decimal(18,0) | Tiền thuế dòng. |
| invoice\_items.line\_total | decimal(18,0) | Tổng dòng sau thuế. |
| invoices.tax\_amount | decimal(18,0) | Tổng thuế hóa đơn. |
| invoices.grand\_total | decimal(18,0) | Tổng cuối cùng. |

**6\. REST API summary \- USER \+ ADMIN \+ CHATBOT**

| Module | Method | Endpoint | Role | Main status |
| :---- | :---- | :---- | :---- | :---- |
| Profile | GET | /api/v1/profile | USER/ADMIN | 200,401,403 |
| Profile | PUT | /api/v1/profile | USER/ADMIN | 200,401,403,422 |
| Category | GET | /api/v1/categories | Public | 200 |
| Product | GET | /api/v1/products | Public | 200,400 |
| Product | GET | /api/v1/products/:id | Public | 200,404 |
| Cart | GET | /api/v1/cart | USER | 200,401 |
| Cart | POST | /api/v1/cart/items | USER | 201,401,404,409,422 |
| Cart | PUT | /api/v1/cart/items/:id | USER | 200,401,404,409,422 |
| Cart | DELETE | /api/v1/cart/items/:id | USER | 204,401,404 |
| Checkout | POST | /api/v1/checkout | USER | 201,401,409,422 |
| Order | GET | /api/v1/orders | USER | 200,401 |
| Order | GET | /api/v1/orders/:id | USER | 200,401,404 |
| Order | PATCH | /api/v1/orders/:id/cancel | USER | 200,401,404,409 |
| Invoice | GET | /api/v1/invoices | USER | 200,401 |
| Invoice | GET | /api/v1/invoices/:id | USER | 200,401,404 |
| Payment | GET | /api/v1/payments/:id/status | USER | 200,401,404 |
| Notification | GET | /api/v1/notifications | USER | 200,401 |
| Notification | PATCH | /api/v1/notifications/:id/read | USER | 200,401,404 |
| Notification | PATCH | /api/v1/notifications/read-all | USER | 200,401 |
| Store | GET | /api/v1/stores | Public | 200 |
| Chatbot | POST | /api/v1/chatbot/messages | USER | 200,401,422,429,502 |
| Chatbot | GET | /api/v1/chatbot/conversations/:id/messages | USER | 200,401,404 |
| Chatbot | DELETE | /api/v1/chatbot/conversations/:id | USER | 204,401,404 |
| Admin | GET | /api/v1/admin/dashboard | ADMIN | 200,401,403 |
| Admin User | GET | /api/v1/admin/users | ADMIN | 200,401,403 |
| Admin User | GET | /api/v1/admin/users/:id | ADMIN | 200,401,403,404 |
| Admin User | PATCH | /api/v1/admin/users/:id | ADMIN | 200,401,403,404,422 |
| Admin Category | POST | /api/v1/admin/categories | ADMIN | 201,401,403,409,422 |
| Admin Category | PUT | /api/v1/admin/categories/:id | ADMIN | 200,401,403,404,409,422 |
| Admin Category | DELETE | /api/v1/admin/categories/:id | ADMIN | 204,401,403,404,409 |
| Admin Product | POST | /api/v1/admin/products | ADMIN | 201,401,403,409,422 |
| Admin Product | PUT | /api/v1/admin/products/:id | ADMIN | 200,401,403,404,409,422 |
| Admin Product | DELETE | /api/v1/admin/products/:id | ADMIN | 204,401,403,404,409 |
| Admin Order | GET | /api/v1/admin/orders | ADMIN | 200,401,403 |
| Admin Order | PATCH | /api/v1/admin/orders/:id/status | ADMIN | 200,401,403,404,409,422 |
| Admin Invoice | GET | /api/v1/admin/invoices | ADMIN | 200,401,403 |
| Admin Payment | GET | /api/v1/admin/payments | ADMIN | 200,401,403 |
| Admin SePay | GET | /api/v1/admin/sepay-transactions | ADMIN | 200,401,403 |
| Webhook | POST | /api/v1/webhooks/sepay | SePay | 200,400,401,500 |

**7\. Detailed USER API contracts**

**7.1 GET Profile**

| Method | GET |
| :---- | :---- |
| Path | /api/v1/profile |
| Auth/Role | USER or ADMIN |
| Success | \[\['401', 'AUTH\_TOKEN\_MISSING', 'Không có Authorization header.'\], \['401', 'AUTH\_TOKEN\_INVALID', 'Token sai/hết hạn.'\], \['403', 'ACCOUNT\_DISABLED', 'Account bị admin khóa.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | Supabase access token. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| id | uuid | Profile ID \= Supabase auth user ID. |
| email | string|null | Email account. |
| fullName | string|null | Tên hiển thị. |
| avatarUrl | string|null | Avatar. |
| phone | string|null | Số điện thoại. |
| role | USER|ADMIN | Role hiện tại. |
| status | ACTIVE|DISABLED | Trạng thái account business. |
| createdAt | datetime | Ngày tạo profile. |

**Response example**

| {  "success": true,  "data": {    "id": "8d9d...uuid",    "email": "user@gmail.com",    "fullName": "Pham Dinh",    "avatarUrl": null,    "phone": "0901234567",    "role": "USER",    "status": "ACTIVE",    "createdAt": "2026-10-03T12:00:00.000Z"  }} |
| :---- |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 401 | AUTH\_TOKEN\_MISSING | Không có Authorization header. |
| 401 | AUTH\_TOKEN\_INVALID | Token sai/hết hạn. |
| 403 | ACCOUNT\_DISABLED | Account bị admin khóa. |

**7.2 Update Profile**

| Method | PUT |
| :---- | :---- |
| Path | /api/v1/profile |
| Auth/Role | USER or ADMIN |
| Success | \[\['401', 'AUTH\_TOKEN\_INVALID', 'Token không hợp lệ.'\], \['403', 'ACCOUNT\_DISABLED', 'Account bị khóa.'\], \['422', 'VALIDATION\_ERROR', 'Body không hợp lệ.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | Supabase access token. |
| fullName | Body | string | No | 1-100 ký tự. |
| phone | Body | string | No | SĐT; validate format. |
| avatarUrl | Body | string|null | No | URL ảnh từ Supabase Storage. |

**Request example**

| {  "fullName": "Pham Dinh",  "phone": "0901234567",  "avatarUrl": "https\://.../avatar.jpg"} |
| :---- |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| id | uuid | Profile ID. |
| fullName | string|null | Tên mới. |
| phone | string|null | SĐT mới. |
| avatarUrl | string|null | Avatar mới. |
| updatedAt | datetime | Thời điểm cập nhật. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 401 | AUTH\_TOKEN\_INVALID | Token không hợp lệ. |
| 403 | ACCOUNT\_DISABLED | Account bị khóa. |
| 422 | VALIDATION\_ERROR | Body không hợp lệ. |

**7.3 Get Categories**

| Method | GET |
| :---- | :---- |
| Path | /api/v1/categories |
| Auth/Role | Public |
| Success | \[\['400', 'BAD\_REQUEST', 'Query không đúng định dạng.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| search | Query | string | No | Tìm category theo tên. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| items\[\].id | uuid | Category ID. |
| items\[\].name | string | Tên danh mục. |
| items\[\].slug | string | Slug unique. |
| items\[\].imageUrl | string|null | Ảnh category. |
| items\[\].isActive | boolean | Có hiển thị hay không. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 400 | BAD\_REQUEST | Query không đúng định dạng. |

**7.4 Get Products**

| Method | GET |
| :---- | :---- |
| Path | /api/v1/products |
| Auth/Role | Public |
| Success | \[\['400', 'BAD\_REQUEST', 'Query/sort không hợp lệ.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| page | Query | int | No | Default 1\. |
| limit | Query | int | No | Default 20; max 100\. |
| search | Query | string | No | Search name/SKU. |
| categoryId | Query | uuid | No | Filter category. |
| minPrice | Query | number | No | Giá tối thiểu. |
| maxPrice | Query | number | No | Giá tối đa. |
| sort | Query | string | No | price\_asc, price\_desc, newest. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| items\[\].id | uuid | Product ID. |
| items\[\].sku | string | SKU. |
| items\[\].name | string | Tên sản phẩm. |
| items\[\].price | number | Giá hiện tại. |
| items\[\].stock | int | Tồn kho. |
| items\[\].imageUrl | string|null | Ảnh chính. |
| items\[\].category | object | id \+ name. |
| meta.page | int | Trang hiện tại. |
| meta.total | int | Tổng record. |
| meta.totalPages | int | Tổng trang. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 400 | BAD\_REQUEST | Query/sort không hợp lệ. |

**7.5 Get Product Detail**

| Method | GET |
| :---- | :---- |
| Path | /api/v1/products/:id |
| Auth/Role | Public |
| Success | \[\['404', 'PRODUCT\_NOT\_FOUND', 'Không có product hoặc product không active.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| id | Path | uuid | Yes | Product ID. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| id | uuid | Product ID. |
| sku | string | SKU unique. |
| name | string | Tên. |
| description | string|null | Mô tả. |
| price | number | Giá. |
| stock | int | Tồn kho. |
| taxRate | number | Thuế suất dùng khi checkout (server quyết định). |
| imageUrls | string\[\] | Danh sách ảnh. |
| category | object | Category. |
| isActive | boolean | Trạng thái bán. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 404 | PRODUCT\_NOT\_FOUND | Không có product hoặc product không active. |

**7.6 Get Cart**

| Method | GET |
| :---- | :---- |
| Path | /api/v1/cart |
| Auth/Role | USER |
| Success | \[\['401', 'AUTH\_TOKEN\_INVALID', 'Token invalid.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | User access token. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| id | uuid | Cart ID. |
| items\[\].id | uuid | Cart item ID. |
| items\[\].productId | uuid | Product ID. |
| items\[\].name | string | Product name. |
| items\[\].price | number | Current price. |
| items\[\].quantity | int | Quantity. |
| items\[\].subtotal | number | price \* quantity. |
| totalQuantity | int | Tổng quantity. |
| subtotal | number | Tổng trước checkout. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 401 | AUTH\_TOKEN\_INVALID | Token invalid. |

**7.7 Add Cart Item**

| Method | POST |
| :---- | :---- |
| Path | /api/v1/cart/items |
| Auth/Role | USER |
| Success | \[\['401', 'AUTH\_TOKEN\_INVALID', 'Token invalid.'\], \['404', 'PRODUCT\_NOT\_FOUND', 'Product không tồn tại.'\], \['409', 'PRODUCT\_OUT\_OF\_STOCK', 'Quantity vượt stock.'\], \['422', 'VALIDATION\_ERROR', 'quantity \<= 0 hoặc body sai.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | User token. |
| productId | Body | uuid | Yes | Product cần thêm. |
| quantity | Body | int | Yes | \>= 1\. |

**Request example**

| {  "productId": "product-uuid",  "quantity": 2} |
| :---- |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| id | uuid | Cart item ID. |
| productId | uuid | Product ID. |
| quantity | int | Quantity sau khi cộng. |
| subtotal | number | Current subtotal. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 401 | AUTH\_TOKEN\_INVALID | Token invalid. |
| 404 | PRODUCT\_NOT\_FOUND | Product không tồn tại. |
| 409 | PRODUCT\_OUT\_OF\_STOCK | Quantity vượt stock. |
| 422 | VALIDATION\_ERROR | quantity \<= 0 hoặc body sai. |

**7.8 Update Cart Item**

| Method | PUT |
| :---- | :---- |
| Path | /api/v1/cart/items/:id |
| Auth/Role | USER |
| Success | \[\['404', 'CART\_ITEM\_NOT\_FOUND', 'Không có item/không thuộc user.'\], \['409', 'PRODUCT\_OUT\_OF\_STOCK', 'Không đủ stock.'\], \['422', 'VALIDATION\_ERROR', 'Quantity không hợp lệ.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | User token. |
| id | Path | uuid | Yes | Cart item ID. |
| quantity | Body | int | Yes | \>= 1\. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| id | uuid | Cart item ID. |
| quantity | int | Quantity mới. |
| subtotal | number | Subtotal mới. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 404 | CART\_ITEM\_NOT\_FOUND | Không có item/không thuộc user. |
| 409 | PRODUCT\_OUT\_OF\_STOCK | Không đủ stock. |
| 422 | VALIDATION\_ERROR | Quantity không hợp lệ. |

**7.9 Delete Cart Item**

| Method | DELETE |
| :---- | :---- |
| Path | /api/v1/cart/items/:id |
| Auth/Role | USER |
| Success | \[\['404', 'CART\_ITEM\_NOT\_FOUND', 'Không có item/không thuộc user.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | User token. |
| id | Path | uuid | Yes | Cart item ID. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| \- | \- | 204 No Content \- không có response body. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 404 | CART\_ITEM\_NOT\_FOUND | Không có item/không thuộc user. |

**7.10 Checkout**

| Method | POST |
| :---- | :---- |
| Path | /api/v1/checkout |
| Auth/Role | USER |
| Success | \[\['409', 'PRODUCT\_OUT\_OF\_STOCK', 'Stock không đủ.'\], \['409', 'CHECKOUT\_CONFLICT', 'Transaction conflict/idempotency conflict.'\], \['422', 'CART\_EMPTY', 'Cart rỗng.'\], \['422', 'VALIDATION\_ERROR', 'Thông tin giao hàng sai.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | User token. |
| Idempotency-Key | Header | uuid/string | Recommended | Chống double submit. |
| receiverName | Body | string | Yes | Tên người nhận. |
| phone | Body | string | Yes | SĐT. |
| address | Body | string | Yes | Địa chỉ text. |
| latitude | Body | number | Yes | \-90..90. |
| longitude | Body | number | Yes | \-180..180. |
| paymentMethod | Body | SEPAY|COD | Yes | Phương thức thanh toán. |
| note | Body | string|null | No | Ghi chú giao hàng. |

**Request example**

| {  "receiverName": "Pham Dinh",  "phone": "0901234567",  "address": "Ho Chi Minh City",  "latitude": 10.762,  "longitude": 106.682,  "paymentMethod": "SEPAY",  "note": "Giao giờ hành chính"} |
| :---- |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| order.id | uuid | Order ID. |
| order.orderCode | string | Mã đơn. |
| order.status | string | PENDING/CONFIRMED... |
| invoice.id | uuid | Invoice ID. |
| invoice.invoiceNumber | string | Mã hóa đơn. |
| invoice.subtotalAmount | number | Tiền hàng. |
| invoice.taxAmount | number | Tổng thuế. |
| invoice.shippingFee | number | Phí ship. |
| invoice.grandTotal | number | Tổng cần trả. |
| payment.id | uuid|null | Payment ID nếu SEPAY. |
| payment.paymentCode | string|null | Nội dung CK. |
| payment.qrUrl | string|null | QR URL. |
| payment.status | string|null | PENDING. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 409 | PRODUCT\_OUT\_OF\_STOCK | Stock không đủ. |
| 409 | CHECKOUT\_CONFLICT | Transaction conflict/idempotency conflict. |
| 422 | CART\_EMPTY | Cart rỗng. |
| 422 | VALIDATION\_ERROR | Thông tin giao hàng sai. |

**7.11 List My Orders**

| Method | GET |
| :---- | :---- |
| Path | /api/v1/orders |
| Auth/Role | USER |
| Success | \[\['401', 'AUTH\_TOKEN\_INVALID', 'Token invalid.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | User token. |
| page | Query | int | No | Default 1\. |
| status | Query | string | No | Filter order status. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| items\[\].id | uuid | Order ID. |
| items\[\].orderCode | string | Mã đơn. |
| items\[\].status | string | Order status. |
| items\[\].grandTotal | number | Tổng tiền snapshot. |
| items\[\].paymentStatus | string | Payment status. |
| items\[\].createdAt | datetime | Ngày đặt. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 401 | AUTH\_TOKEN\_INVALID | Token invalid. |

**7.12 Get My Order Detail**

| Method | GET |
| :---- | :---- |
| Path | /api/v1/orders/:id |
| Auth/Role | USER |
| Success | \[\['404', 'ORDER\_NOT\_FOUND', 'Không có order hoặc không thuộc user.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | User token. |
| id | Path | uuid | Yes | Order ID. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| id | uuid | Order ID. |
| orderCode | string | Mã đơn. |
| status | string | Order status. |
| receiverName | string | Snapshot người nhận. |
| phone | string | Snapshot phone. |
| address | string | Snapshot address. |
| latitude | number | Delivery latitude. |
| longitude | number | Delivery longitude. |
| items | array | Order items snapshot. |
| invoiceId | uuid | Invoice liên quan. |
| paymentStatus | string | PENDING/PAID... |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 404 | ORDER\_NOT\_FOUND | Không có order hoặc không thuộc user. |

**7.13 Cancel My Order**

| Method | PATCH |
| :---- | :---- |
| Path | /api/v1/orders/:id/cancel |
| Auth/Role | USER |
| Success | \[\['404', 'ORDER\_NOT\_FOUND', 'Order không tồn tại.'\], \['409', 'ORDER\_CANNOT\_CANCEL', 'Order đã SHIPPING/COMPLETED hoặc trạng thái không cho phép.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | User token. |
| id | Path | uuid | Yes | Order ID. |
| reason | Body | string | No | Lý do cancel. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| id | uuid | Order ID. |
| status | CANCELLED | Trạng thái mới. |
| cancelledAt | datetime | Thời điểm hủy. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 404 | ORDER\_NOT\_FOUND | Order không tồn tại. |
| 409 | ORDER\_CANNOT\_CANCEL | Order đã SHIPPING/COMPLETED hoặc trạng thái không cho phép. |

**7.14 List My Invoices**

| Method | GET |
| :---- | :---- |
| Path | /api/v1/invoices |
| Auth/Role | USER |
| Success | \[\['401', 'AUTH\_TOKEN\_INVALID', 'Token invalid.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | User token. |
| page | Query | int | No | Pagination. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| items\[\].id | uuid | Invoice ID. |
| items\[\].invoiceNumber | string | Mã hóa đơn. |
| items\[\].grandTotal | number | Tổng tiền. |
| items\[\].taxAmount | number | Tổng thuế. |
| items\[\].status | string | ISSUED/PAID/CANCELLED. |
| items\[\].paymentStatus | string | PENDING/PAID... |
| items\[\].issuedAt | datetime | Ngày phát hành. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 401 | AUTH\_TOKEN\_INVALID | Token invalid. |

**7.15 Get Invoice Detail**

| Method | GET |
| :---- | :---- |
| Path | /api/v1/invoices/:id |
| Auth/Role | USER |
| Success | \[\['404', 'INVOICE\_NOT\_FOUND', 'Invoice không có/không thuộc user.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | User token. |
| id | Path | uuid | Yes | Invoice ID. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| id | uuid | Invoice ID. |
| invoiceNumber | string | Mã hóa đơn. |
| customerName | string | Snapshot customer. |
| subtotalAmount | number | Tiền trước thuế. |
| discountAmount | number | Discount. |
| taxAmount | number | Tổng tax. |
| shippingFee | number | Shipping. |
| grandTotal | number | Grand total. |
| items\[\].productName | string | Snapshot name. |
| items\[\].unitPrice | number | Snapshot unit price. |
| items\[\].quantity | int | Quantity. |
| items\[\].taxRate | number | Tax rate. |
| items\[\].taxAmount | number | Tax amount. |
| items\[\].lineTotal | number | Line total. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 404 | INVOICE\_NOT\_FOUND | Invoice không có/không thuộc user. |

**7.16 Get Payment Status**

| Method | GET |
| :---- | :---- |
| Path | /api/v1/payments/:id/status |
| Auth/Role | USER |
| Success | \[\['404', 'PAYMENT\_NOT\_FOUND', 'Payment không tồn tại/không thuộc user.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | User token. |
| id | Path | uuid | Yes | Payment ID. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| id | uuid | Payment ID. |
| invoiceId | uuid | Invoice ID. |
| provider | SEPAY|COD | Provider. |
| paymentCode | string|null | Mã chuyển khoản. |
| amount | number | Số tiền cần trả. |
| status | PENDING|PAID|FAILED|EXPIRED|REVIEW | Trạng thái. |
| paidAt | datetime|null | Đã thanh toán lúc. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 404 | PAYMENT\_NOT\_FOUND | Payment không tồn tại/không thuộc user. |

**7.17 List Notifications**

| Method | GET |
| :---- | :---- |
| Path | /api/v1/notifications |
| Auth/Role | USER |
| Success | \[\['401', 'AUTH\_TOKEN\_INVALID', 'Token invalid.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | User token. |
| page | Query | int | No | Pagination. |
| unreadOnly | Query | boolean | No | Chỉ unread. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| items\[\].id | uuid | Notification ID. |
| items\[\].type | string | ORDER/PAYMENT/PROMOTION/SYSTEM. |
| items\[\].title | string | Title. |
| items\[\].message | string | Message. |
| items\[\].isRead | boolean | Read state. |
| items\[\].createdAt | datetime | Created time. |
| meta.unreadCount | int | Tổng unread. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 401 | AUTH\_TOKEN\_INVALID | Token invalid. |

**7.18 Mark Notification Read**

| Method | PATCH |
| :---- | :---- |
| Path | /api/v1/notifications/:id/read |
| Auth/Role | USER |
| Success | \[\['404', 'NOTIFICATION\_NOT\_FOUND', 'Không có/không thuộc user.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | User token. |
| id | Path | uuid | Yes | Notification ID. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| id | uuid | Notification ID. |
| isRead | boolean | true. |
| readAt | datetime | Read time. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 404 | NOTIFICATION\_NOT\_FOUND | Không có/không thuộc user. |

**7.19 Mark All Notifications Read**

| Method | PATCH |
| :---- | :---- |
| Path | /api/v1/notifications/read-all |
| Auth/Role | USER |
| Success | \[\['401', 'AUTH\_TOKEN\_INVALID', 'Token invalid.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | User token. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| updatedCount | int | Số notification được update. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 401 | AUTH\_TOKEN\_INVALID | Token invalid. |

**7.20 List Stores**

| Method | GET |
| :---- | :---- |
| Path | /api/v1/stores |
| Auth/Role | Public |
| Success | \[\['400', 'BAD\_REQUEST', 'Lat/lng không hợp lệ.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| latitude | Query | number | No | Nếu có thì backend có thể tính distance. |
| longitude | Query | number | No | Đi cùng latitude. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| items\[\].id | uuid | Store ID. |
| items\[\].name | string | Tên store. |
| items\[\].address | string | Địa chỉ. |
| items\[\].latitude | number | Lat. |
| items\[\].longitude | number | Lng. |
| items\[\].phone | string|null | Phone. |
| items\[\].distanceKm | number|null | Khoảng cách nếu query có current location. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 400 | BAD\_REQUEST | Lat/lng không hợp lệ. |

**8\. Chatbot API contracts**  
Chat trong project được sửa thành chatbot. Không có conversation Customer ↔ Shop. Chatbot có thể dùng dữ liệu product/FAQ làm context; provider AI là lớp thay thế được, không để secret AI trong Flutter.

**8.1 Send Message to Chatbot**

| Method | POST |
| :---- | :---- |
| Path | /api/v1/chatbot/messages |
| Auth/Role | USER |
| Success | \[\['404', 'PRODUCT\_NOT\_FOUND', 'productId context không tồn tại.'\], \['422', 'VALIDATION\_ERROR', 'Message rỗng/quá dài.'\], \['429', 'CHATBOT\_RATE\_LIMITED', 'Gửi quá nhanh.'\], \['502', 'CHATBOT\_PROVIDER\_ERROR', 'Provider AI lỗi.'\], \['504', 'CHATBOT\_PROVIDER\_TIMEOUT', 'Provider AI timeout.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | User token. |
| conversationId | Body | uuid|null | No | Null \= tạo conversation mới. |
| message | Body | string | Yes | 1-2000 ký tự. |
| productId | Body | uuid|null | No | Context sản phẩm đang xem. |

**Request example**

| {  "conversationId": null,  "message": "Cây nào phù hợp để bàn và ít nắng?",  "productId": null} |
| :---- |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| conversationId | uuid | Conversation hiện tại. |
| messageId | uuid | Assistant message ID. |
| reply | string | Nội dung chatbot trả lời. |
| suggestedProducts | array | Danh sách product liên quan (optional). |
| createdAt | datetime | Thời điểm trả lời. |

**Response example**

| {  "success": true,  "data": {    "conversationId": "conv-uuid",    "messageId": "msg-uuid",    "reply": "Bạn có thể xem các dòng cây chịu bóng...",    "suggestedProducts": \[      {        "id": "product-uuid",        "name": "Cây Lưỡi Hổ Mini",        "price": 120000      }    \],    "createdAt": "2026-10-03T15:00:00.000Z"  }} |
| :---- |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 404 | PRODUCT\_NOT\_FOUND | productId context không tồn tại. |
| 422 | VALIDATION\_ERROR | Message rỗng/quá dài. |
| 429 | CHATBOT\_RATE\_LIMITED | Gửi quá nhanh. |
| 502 | CHATBOT\_PROVIDER\_ERROR | Provider AI lỗi. |
| 504 | CHATBOT\_PROVIDER\_TIMEOUT | Provider AI timeout. |

**8.2 Get Chatbot History**

| Method | GET |
| :---- | :---- |
| Path | /api/v1/chatbot/conversations/:id/messages |
| Auth/Role | USER |
| Success | \[\['404', 'CHATBOT\_CONVERSATION\_NOT\_FOUND', 'Không có hoặc không thuộc user.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | User token. |
| id | Path | uuid | Yes | Conversation ID. |
| page | Query | int | No | Pagination. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| conversation.id | uuid | Conversation ID. |
| conversation.title | string|null | Title generated/first message. |
| items\[\].id | uuid | Message ID. |
| items\[\].role | USER|ASSISTANT | Vai trò message. |
| items\[\].content | string | Nội dung. |
| items\[\].createdAt | datetime | Time. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 404 | CHATBOT\_CONVERSATION\_NOT\_FOUND | Không có hoặc không thuộc user. |

**8.3 Delete Chatbot Conversation**

| Method | DELETE |
| :---- | :---- |
| Path | /api/v1/chatbot/conversations/:id |
| Auth/Role | USER |
| Success | \[\['404', 'CHATBOT\_CONVERSATION\_NOT\_FOUND', 'Không có hoặc không thuộc user.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | User token. |
| id | Path | uuid | Yes | Conversation ID. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| \- | \- | 204 No Content. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 404 | CHATBOT\_CONVERSATION\_NOT\_FOUND | Không có hoặc không thuộc user. |

**9\. ADMIN API contracts**  
Tất cả /api/v1/admin/\* yêu cầu Bearer token hợp lệ, profiles.role \= ADMIN và profiles.status \= ACTIVE.

**9.1 Admin Dashboard**

| Method | GET |
| :---- | :---- |
| Path | /api/v1/admin/dashboard |
| Auth/Role | ADMIN |
| Success | \[\['401', 'AUTH\_TOKEN\_INVALID', 'Invalid token.'\], \['403', 'FORBIDDEN', 'Không phải ADMIN.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | Admin token. |
| from | Query | date | No | Start date. |
| to | Query | date | No | End date. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| totalUsers | int | Tổng user. |
| totalProducts | int | Tổng product active. |
| totalOrders | int | Tổng order trong range. |
| pendingOrders | int | Order PENDING. |
| paidRevenue | number | Doanh thu payment PAID trong range. |
| lowStockProducts | int | Số product dưới ngưỡng stock. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 401 | AUTH\_TOKEN\_INVALID | Invalid token. |
| 403 | FORBIDDEN | Không phải ADMIN. |

**9.2 Admin List Users**

| Method | GET |
| :---- | :---- |
| Path | /api/v1/admin/users |
| Auth/Role | ADMIN |
| Success | \[\['403', 'FORBIDDEN', 'Không phải admin.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | Admin token. |
| page | Query | int | No | Pagination. |
| search | Query | string | No | Search email/name/phone. |
| role | Query | USER|ADMIN | No | Filter role. |
| status | Query | ACTIVE|DISABLED | No | Filter status. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| items\[\].id | uuid | User ID. |
| items\[\].email | string|null | Email. |
| items\[\].fullName | string|null | Name. |
| items\[\].phone | string|null | Phone. |
| items\[\].role | USER|ADMIN | Role. |
| items\[\].status | ACTIVE|DISABLED | Status. |
| items\[\].createdAt | datetime | Created. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 403 | FORBIDDEN | Không phải admin. |

**9.3 Admin Get User Detail**

| Method | GET |
| :---- | :---- |
| Path | /api/v1/admin/users/:id |
| Auth/Role | ADMIN |
| Success | \[\['404', 'USER\_NOT\_FOUND', 'Không có user.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | Admin token. |
| id | Path | uuid | Yes | User ID. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| id | uuid | User ID. |
| email | string|null | Email. |
| fullName | string|null | Name. |
| phone | string|null | Phone. |
| role | USER|ADMIN | Role. |
| status | ACTIVE|DISABLED | Status. |
| orderCount | int | Số order. |
| totalPaid | number | Tổng payment PAID. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 404 | USER\_NOT\_FOUND | Không có user. |

**9.4 Admin Update User**

| Method | PATCH |
| :---- | :---- |
| Path | /api/v1/admin/users/:id |
| Auth/Role | ADMIN |
| Success | \[\['404', 'USER\_NOT\_FOUND', 'Không có user.'\], \['409', 'ADMIN\_SELF\_LOCK\_FORBIDDEN', 'Không cho tự khóa admin hiện tại.'\], \['422', 'VALIDATION\_ERROR', 'Body sai.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | Admin token. |
| id | Path | uuid | Yes | User ID. |
| role | Body | USER|ADMIN | No | Đổi role nếu project cho phép. |
| status | Body | ACTIVE|DISABLED | No | Khóa/mở account business. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| id | uuid | User ID. |
| role | USER|ADMIN | Role mới. |
| status | ACTIVE|DISABLED | Status mới. |
| updatedAt | datetime | Time. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 404 | USER\_NOT\_FOUND | Không có user. |
| 409 | ADMIN\_SELF\_LOCK\_FORBIDDEN | Không cho tự khóa admin hiện tại. |
| 422 | VALIDATION\_ERROR | Body sai. |

**9.5 Admin Create Category**

| Method | POST |
| :---- | :---- |
| Path | /api/v1/admin/categories |
| Auth/Role | ADMIN |
| Success | \[\['409', 'CATEGORY\_SLUG\_EXISTS', 'Slug trùng.'\], \['422', 'VALIDATION\_ERROR', 'Body sai.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | Admin token. |
| name | Body | string | Yes | Tên category. |
| slug | Body | string | Yes | Unique slug. |
| imageUrl | Body | string|null | No | Ảnh. |
| isActive | Body | boolean | No | Default true. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| id | uuid | Category ID. |
| name | string | Name. |
| slug | string | Slug. |
| isActive | boolean | Status. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 409 | CATEGORY\_SLUG\_EXISTS | Slug trùng. |
| 422 | VALIDATION\_ERROR | Body sai. |

**9.6 Admin Update Category**

| Method | PUT |
| :---- | :---- |
| Path | /api/v1/admin/categories/:id |
| Auth/Role | ADMIN |
| Success | \[\['404', 'CATEGORY\_NOT\_FOUND', 'Category không tồn tại.'\], \['409', 'CATEGORY\_SLUG\_EXISTS', 'Slug trùng.'\], \['422', 'VALIDATION\_ERROR', 'Body sai.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | Admin token. |
| id | Path | uuid | Yes | Category ID. |
| name | Body | string | Yes | Name. |
| slug | Body | string | Yes | Unique slug. |
| imageUrl | Body | string|null | No | Image. |
| isActive | Body | boolean | Yes | Status. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| id | uuid | Category ID. |
| name | string | Updated name. |
| slug | string | Updated slug. |
| isActive | boolean | Updated state. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 404 | CATEGORY\_NOT\_FOUND | Category không tồn tại. |
| 409 | CATEGORY\_SLUG\_EXISTS | Slug trùng. |
| 422 | VALIDATION\_ERROR | Body sai. |

**9.7 Admin Delete Category**

| Method | DELETE |
| :---- | :---- |
| Path | /api/v1/admin/categories/:id |
| Auth/Role | ADMIN |
| Success | \[\['404', 'CATEGORY\_NOT\_FOUND', 'Category không tồn tại.'\], \['409', 'CATEGORY\_IN\_USE', 'Category còn product.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | Admin token. |
| id | Path | uuid | Yes | Category ID. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| \- | \- | 204 No Content. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 404 | CATEGORY\_NOT\_FOUND | Category không tồn tại. |
| 409 | CATEGORY\_IN\_USE | Category còn product. |

**9.8 Admin Create Product**

| Method | POST |
| :---- | :---- |
| Path | /api/v1/admin/products |
| Auth/Role | ADMIN |
| Success | \[\['404', 'CATEGORY\_NOT\_FOUND', 'Category không tồn tại.'\], \['409', 'PRODUCT\_SKU\_EXISTS', 'SKU trùng.'\], \['422', 'VALIDATION\_ERROR', 'Body sai.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | Admin token. |
| sku | Body | string | Yes | Unique SKU. |
| name | Body | string | Yes | Product name. |
| description | Body | string|null | No | Description. |
| price | Body | number | Yes | \> 0\. |
| stock | Body | int | Yes | \>= 0\. |
| taxRate | Body | number | Yes | Tax config snapshot source. |
| categoryId | Body | uuid | Yes | Category. |
| imageUrls | Body | string\[\] | No | Ảnh. |
| isActive | Body | boolean | No | Default true. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| id | uuid | Product ID. |
| sku | string | SKU. |
| name | string | Name. |
| price | number | Price. |
| stock | int | Stock. |
| taxRate | number | Tax rate. |
| categoryId | uuid | Category. |
| isActive | boolean | State. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 404 | CATEGORY\_NOT\_FOUND | Category không tồn tại. |
| 409 | PRODUCT\_SKU\_EXISTS | SKU trùng. |
| 422 | VALIDATION\_ERROR | Body sai. |

**9.9 Admin Update Product**

| Method | PUT |
| :---- | :---- |
| Path | /api/v1/admin/products/:id |
| Auth/Role | ADMIN |
| Success | \[\['404', 'PRODUCT\_NOT\_FOUND', 'Product không tồn tại.'\], \['404', 'CATEGORY\_NOT\_FOUND', 'Category không tồn tại.'\], \['409', 'PRODUCT\_SKU\_EXISTS', 'SKU trùng product khác.'\], \['422', 'VALIDATION\_ERROR', 'Body sai.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | Admin token. |
| id | Path | uuid | Yes | Product ID. |
| sku | Body | string | Yes | SKU. |
| name | Body | string | Yes | Name. |
| description | Body | string|null | No | Description. |
| price | Body | number | Yes | Price. |
| stock | Body | int | Yes | Stock. |
| taxRate | Body | number | Yes | Tax rate. |
| categoryId | Body | uuid | Yes | Category. |
| imageUrls | Body | string\[\] | No | Images. |
| isActive | Body | boolean | Yes | State. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| id | uuid | Product ID. |
| sku | string | SKU. |
| name | string | Name. |
| price | number | Price. |
| stock | int | Stock. |
| updatedAt | datetime | Updated. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 404 | PRODUCT\_NOT\_FOUND | Product không tồn tại. |
| 404 | CATEGORY\_NOT\_FOUND | Category không tồn tại. |
| 409 | PRODUCT\_SKU\_EXISTS | SKU trùng product khác. |
| 422 | VALIDATION\_ERROR | Body sai. |

**9.10 Admin Delete Product**

| Method | DELETE |
| :---- | :---- |
| Path | /api/v1/admin/products/:id |
| Auth/Role | ADMIN |
| Success | \[\['404', 'PRODUCT\_NOT\_FOUND', 'Product không tồn tại.'\], \['409', 'PRODUCT\_IN\_USE', 'Product đã được tham chiếu; nên soft delete/isActive=false.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | Admin token. |
| id | Path | uuid | Yes | Product ID. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| \- | \- | 204 No Content. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 404 | PRODUCT\_NOT\_FOUND | Product không tồn tại. |
| 409 | PRODUCT\_IN\_USE | Product đã được tham chiếu; nên soft delete/isActive=false. |

**9.11 Admin List Orders**

| Method | GET |
| :---- | :---- |
| Path | /api/v1/admin/orders |
| Auth/Role | ADMIN |
| Success | \[\['403', 'FORBIDDEN', 'Not admin.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | Admin token. |
| page | Query | int | No | Pagination. |
| status | Query | string | No | Filter status. |
| paymentStatus | Query | string | No | Filter payment status. |
| search | Query | string | No | Search orderCode/customer. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| items\[\].id | uuid | Order ID. |
| items\[\].orderCode | string | Order code. |
| items\[\].customer | object | id \+ name \+ phone. |
| items\[\].status | string | Order status. |
| items\[\].paymentStatus | string | Payment state. |
| items\[\].grandTotal | number | Total. |
| items\[\].createdAt | datetime | Created. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 403 | FORBIDDEN | Not admin. |

**9.12 Admin Update Order Status**

| Method | PATCH |
| :---- | :---- |
| Path | /api/v1/admin/orders/:id/status |
| Auth/Role | ADMIN |
| Success | \[\['404', 'ORDER\_NOT\_FOUND', 'Order không có.'\], \['409', 'INVALID\_ORDER\_STATE\_TRANSITION', 'Transition không hợp lệ.'\], \['422', 'VALIDATION\_ERROR', 'Status sai.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | Admin token. |
| id | Path | uuid | Yes | Order ID. |
| status | Body | string | Yes | CONFIRMED/PREPARING/SHIPPING/COMPLETED/CANCELLED. |
| note | Body | string|null | No | Internal/admin note. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| id | uuid | Order ID. |
| status | string | Status mới. |
| updatedAt | datetime | Updated. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 404 | ORDER\_NOT\_FOUND | Order không có. |
| 409 | INVALID\_ORDER\_STATE\_TRANSITION | Transition không hợp lệ. |
| 422 | VALIDATION\_ERROR | Status sai. |

**9.13 Admin List Invoices**

| Method | GET |
| :---- | :---- |
| Path | /api/v1/admin/invoices |
| Auth/Role | ADMIN |
| Success | \[\['403', 'FORBIDDEN', 'Not admin.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | Admin token. |
| page | Query | int | No | Pagination. |
| status | Query | string | No | ISSUED/PAID/CANCELLED. |
| search | Query | string | No | invoiceNumber/orderCode/customer. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| items\[\].id | uuid | Invoice ID. |
| items\[\].invoiceNumber | string | Invoice number. |
| items\[\].orderId | uuid | Order ID. |
| items\[\].customerName | string | Customer snapshot. |
| items\[\].taxAmount | number | Tax. |
| items\[\].grandTotal | number | Total. |
| items\[\].paymentStatus | string | Payment state. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 403 | FORBIDDEN | Not admin. |

**9.14 Admin List Payments**

| Method | GET |
| :---- | :---- |
| Path | /api/v1/admin/payments |
| Auth/Role | ADMIN |
| Success | \[\['403', 'FORBIDDEN', 'Not admin.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | Admin token. |
| page | Query | int | No | Pagination. |
| status | Query | string | No | PENDING/PAID/FAILED/EXPIRED/REVIEW. |
| provider | Query | SEPAY|COD | No | Provider. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| items\[\].id | uuid | Payment ID. |
| items\[\].invoiceId | uuid | Invoice ID. |
| items\[\].paymentCode | string|null | Payment code. |
| items\[\].amount | number | Amount. |
| items\[\].provider | string | Provider. |
| items\[\].status | string | Payment state. |
| items\[\].paidAt | datetime|null | Paid time. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 403 | FORBIDDEN | Not admin. |

**9.15 Admin List SePay Transactions**

| Method | GET |
| :---- | :---- |
| Path | /api/v1/admin/sepay-transactions |
| Auth/Role | ADMIN |
| Success | \[\['403', 'FORBIDDEN', 'Not admin.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| Authorization | Header | Bearer token | Yes | Admin token. |
| page | Query | int | No | Pagination. |
| matched | Query | boolean | No | Matched payment hay chưa. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| items\[\].id | uuid | Internal transaction ID. |
| items\[\].sepayTransactionId | string | SePay transaction ID. |
| items\[\].paymentId | uuid|null | Matched payment. |
| items\[\].gateway | string|null | Bank gateway. |
| items\[\].transferAmount | number | Amount. |
| items\[\].paymentCode | string|null | Parsed payment code. |
| items\[\].referenceCode | string|null | Bank reference. |
| items\[\].receivedAt | datetime | Webhook received. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 403 | FORBIDDEN | Not admin. |

**10\. SePay webhook contract**

**10.1 SePay Webhook**

| Method | POST |
| :---- | :---- |
| Path | /api/v1/webhooks/sepay |
| Auth/Role | SePay provider |
| Success | \[\['400', 'BAD\_REQUEST', 'Payload JSON/required field sai.'\], \['401', 'SEPAY\_SIGNATURE\_INVALID', 'Signature/timestamp invalid.'\], \['500', 'INTERNAL\_ERROR', 'DB fail trước commit; provider được retry.'\]\] |

**Request fields**

| Field | Location | Type | Required | Description |
| :---- | :---- | :---- | :---- | :---- |
| X-SePay-Signature | Header | string | Yes | HMAC signature. |
| X-SePay-Timestamp | Header | string | Yes | Replay protection timestamp. |
| id | Raw JSON | string/number | Yes | SePay transaction ID. |
| gateway | Raw JSON | string | No | Bank/gateway. |
| transactionDate | Raw JSON | datetime | No | Transaction time. |
| accountNumber | Raw JSON | string | No | Receiving account. |
| code | Raw JSON | string|null | No | Payment code parsed. |
| content | Raw JSON | string|null | No | Transfer content. |
| transferType | Raw JSON | in|out | Yes | Money direction. |
| transferAmount | Raw JSON | number | Yes | Amount. |
| referenceCode | Raw JSON | string|null | No | Bank reference. |

**Response data fields**

| Field | Type | Description |
| :---- | :---- | :---- |
| accepted | boolean | true nếu webhook đã được xử lý/idempotent. |
| transactionId | string | Transaction ID. |

**Errors / states**

| HTTP | error.code | When |
| :---- | :---- | :---- |
| 400 | BAD\_REQUEST | Payload JSON/required field sai. |
| 401 | SEPAY\_SIGNATURE\_INVALID | Signature/timestamp invalid. |
| 500 | INTERNAL\_ERROR | DB fail trước commit; provider được retry. |

*Duplicate transaction đã tồn tại phải trả 200 idempotent, không trả 409\. Payment code không match hoặc amount lệch có thể lưu REVIEW nhưng vẫn trả 200 để tránh retry vô hạn.*

**11\. Business state rules**

| Entity | Allowed flow |
| :---- | :---- |
| Order | PENDING → CONFIRMED → PREPARING → SHIPPING → COMPLETED; PENDING/CONFIRMED có thể → CANCELLED theo rule. |
| Payment | PENDING → PAID | FAILED | EXPIRED | REVIEW. |
| Invoice | ISSUED → PAID | CANCELLED. |
| User | ACTIVE ↔ DISABLED. |

**12\. Exception catalogue**

| error.code | HTTP | Meaning |
| :---- | :---- | :---- |
| VALIDATION\_ERROR | 422 | Body/query/path validation fail. |
| AUTH\_TOKEN\_MISSING | 401 | No bearer token. |
| AUTH\_TOKEN\_INVALID | 401 | Invalid/expired token. |
| FORBIDDEN | 403 | Role insufficient. |
| ACCOUNT\_DISABLED | 403 | Business account locked. |
| USER\_NOT\_FOUND | 404 | User missing. |
| CATEGORY\_NOT\_FOUND | 404 | Category missing. |
| CATEGORY\_SLUG\_EXISTS | 409 | Duplicate category slug. |
| CATEGORY\_IN\_USE | 409 | Cannot delete category with products. |
| PRODUCT\_NOT\_FOUND | 404 | Product missing. |
| PRODUCT\_SKU\_EXISTS | 409 | Duplicate SKU. |
| PRODUCT\_OUT\_OF\_STOCK | 409 | Insufficient stock. |
| PRODUCT\_IN\_USE | 409 | Historical references prevent hard delete. |
| CART\_ITEM\_NOT\_FOUND | 404 | Cart item missing. |
| CART\_EMPTY | 422 | Checkout empty cart. |
| ORDER\_NOT\_FOUND | 404 | Order missing. |
| ORDER\_CANNOT\_CANCEL | 409 | Current state cannot cancel. |
| INVALID\_ORDER\_STATE\_TRANSITION | 409 | Admin state transition invalid. |
| INVOICE\_NOT\_FOUND | 404 | Invoice missing. |
| PAYMENT\_NOT\_FOUND | 404 | Payment missing. |
| PAYMENT\_AMOUNT\_MISMATCH | 409 | Payment mismatch for internal operations. |
| NOTIFICATION\_NOT\_FOUND | 404 | Notification missing. |
| CHATBOT\_CONVERSATION\_NOT\_FOUND | 404 | Conversation missing. |
| CHATBOT\_RATE\_LIMITED | 429 | Chat rate limit. |
| CHATBOT\_PROVIDER\_ERROR | 502 | AI provider error. |
| CHATBOT\_PROVIDER\_TIMEOUT | 504 | AI provider timeout. |
| SEPAY\_SIGNATURE\_INVALID | 401 | Webhook signature invalid. |
| TRANSACTION\_CONFLICT | 409 | Database transaction conflict. |
| RATE\_LIMITED | 429 | General rate limit. |
| INTERNAL\_ERROR | 500 | Unhandled error. |
| SERVICE\_UNAVAILABLE | 503 | DB/service unavailable. |

**13\. Folder structure**

| backend/├─ prisma/│  ├─ schema.prisma│  └─ migrations/├─ src/│  ├─ config/│  ├─ lib/│  │  ├─ prisma.ts│  │  ├─ supabase.ts│  │  └─ logger.ts│  ├─ common/│  │  └─ errors/│  ├─ middlewares/│  │  ├─ auth.middleware.ts│  │  ├─ role.middleware.ts│  │  ├─ validate.middleware.ts│  │  └─ error-handler.ts│  ├─ modules/│  │  ├─ profiles/│  │  ├─ categories/│  │  ├─ products/│  │  ├─ carts/│  │  ├─ orders/│  │  ├─ invoices/│  │  ├─ payments/│  │  ├─ notifications/│  │  ├─ stores/│  │  ├─ chatbot/│  │  └─ admin/│  ├─ app.ts│  └─ server.ts└─ package.json |
| :---- |

**14\. Implementation priority**

| Priority | Task |
| :---- | :---- |
| P0 | Bootstrap Node/Express/TS/Prisma \+ health check \+ env validation. |
| P0 | Supabase auth middleware \+ USER/ADMIN role guard \+ exception handler. |
| P0 | Profile \+ Category/Product public APIs \+ Admin Category/Product CRUD. |
| P0 | Cart \+ checkout transaction \+ Order/OrderItem \+ Invoice/InvoiceItem tax. |
| P0 | SePay payment \+ webhook HMAC \+ idempotency. |
| P1 | Admin order management \+ users \+ dashboard \+ invoice/payment views. |
| P1 | Notifications. |
| P1 | OpenStreetMap/store API. |
| P1 | Chatbot module \+ history \+ rate limit \+ provider adapter. |
| P2 | Swagger/OpenAPI docs \+ automated integration tests. |

**15\. Definition of Done**  
Backend được coi là sẵn sàng tích hợp Flutter khi: USER \+ ADMIN role chạy đúng; từng API có request/response contract cố định; Swagger/Postman test được; error.code nhất quán; checkout không tin total từ mobile; invoice item lưu tax\_rate \+ tax\_amount; SePay webhook idempotent và xác thực; chatbot là chatbot chứ không phải chat người-người; secrets không nằm trong Flutter.

