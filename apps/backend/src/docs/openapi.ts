/**
 * Tài liệu OpenAPI 3 cho Swagger UI tại /api/docs.
 * Viết tay theo docs/spec.md và các Zod schema trong modules; khi thêm/sửa route
 * hãy cập nhật file này cùng lúc.
 */

type Schema = Record<string, unknown>;

interface Operation {
  tag: string;
  summary: string;
  description?: string;
  auth?: "user" | "admin" | "none" | "sepay";
  params?: string[];
  query?: Record<string, Schema & { description?: string }>;
  headers?: Record<string, Schema & { description?: string }>;
  body?: Schema;
  success?: number;
  errors?: number[];
}

const str = (extra: Schema = {}): Schema => ({ type: "string", ...extra });
const num = (extra: Schema = {}): Schema => ({ type: "number", ...extra });
const int = (extra: Schema = {}): Schema => ({ type: "integer", ...extra });
const bool = (extra: Schema = {}): Schema => ({ type: "boolean", ...extra });
const uuid = (extra: Schema = {}): Schema => str({ format: "uuid", ...extra });
const nullable = (schema: Schema): Schema => ({ ...schema, nullable: true });
const enumOf = (values: string[], extra: Schema = {}): Schema => str({ enum: values, ...extra });
const object = (properties: Record<string, Schema>, required: string[] = []): Schema => ({
  type: "object",
  properties,
  ...(required.length && { required }),
});

const ORDER_STATUS = ["PENDING", "CONFIRMED", "PREPARING", "SHIPPING", "COMPLETED", "CANCELLED"];
const PAYMENT_STATUS = ["PENDING", "PAID", "FAILED", "EXPIRED", "REVIEW"];
const INVOICE_STATUS = ["ISSUED", "PAID", "CANCELLED"];

const pageQuery = {
  page: int({ minimum: 1, default: 1, description: "Trang, bắt đầu từ 1." }),
  limit: int({ minimum: 1, maximum: 100, default: 20, description: "Số dòng mỗi trang." }),
};

const ERROR_DESCRIPTIONS: Record<number, string> = {
  400: "Query/payload sai định dạng (BAD_REQUEST)",
  401: "Thiếu hoặc sai token (AUTH_TOKEN_MISSING / AUTH_TOKEN_INVALID)",
  403: "Không đủ quyền hoặc tài khoản bị khóa (FORBIDDEN / ACCOUNT_DISABLED)",
  404: "Không tìm thấy tài nguyên",
  409: "Xung đột trạng thái/dữ liệu",
  422: "Body không hợp lệ (VALIDATION_ERROR)",
  429: "Gửi quá nhanh (RATE_LIMITED)",
  502: "Nhà cung cấp AI lỗi",
  503: "Dịch vụ phụ thuộc chưa sẵn sàng",
};

const SUCCESS_DESCRIPTIONS: Record<number, string> = {
  200: "Thành công",
  201: "Đã tạo",
  204: "Thành công, không có nội dung",
};

const buildOperation = (op: Operation) => {
  const auth = op.auth ?? "none";
  const errors = new Set(op.errors ?? []);
  if (auth === "user" || auth === "admin") {
    errors.add(401);
    errors.add(403);
  }
  if (op.params?.length) errors.add(404);
  if (op.body) errors.add(422);
  if (op.query) errors.add(400);

  const success = op.success ?? 200;
  const roleNote =
    auth === "admin"
      ? "Yêu cầu token của tài khoản **ADMIN** đang ACTIVE."
      : auth === "user"
        ? "Yêu cầu token của tài khoản **USER** đang ACTIVE."
        : auth === "sepay"
          ? "Gọi bởi SePay, xác thực bằng HMAC-SHA256 (không dùng Bearer token)."
          : undefined;

  return {
    tags: [op.tag],
    summary: op.summary,
    description: [op.description, roleNote].filter(Boolean).join("\n\n") || undefined,
    security: auth === "user" || auth === "admin" ? [{ bearerAuth: [] }] : [],
    parameters: [
      ...(op.params ?? []).map((name) => ({
        name,
        in: "path",
        required: true,
        schema: uuid(),
      })),
      ...Object.entries(op.query ?? {}).map(([name, { description, ...schema }]) => ({
        name,
        in: "query",
        required: false,
        description,
        schema,
      })),
      ...Object.entries(op.headers ?? {}).map(([name, { description, ...schema }]) => ({
        name,
        in: "header",
        required: false,
        description,
        schema,
      })),
    ],
    ...(op.body && {
      requestBody: {
        required: true,
        content: { "application/json": { schema: op.body } },
      },
    }),
    responses: {
      [success]: {
        description: SUCCESS_DESCRIPTIONS[success] ?? "Thành công",
        ...(success !== 204 && {
          content: { "application/json": { schema: { $ref: "#/components/schemas/Success" } } },
        }),
      },
      ...Object.fromEntries(
        [...errors]
          .sort()
          .map((status) => [
            status,
            {
              description: ERROR_DESCRIPTIONS[status] ?? "Lỗi",
              content: { "application/json": { schema: { $ref: "#/components/schemas/Error" } } },
            },
          ])
      ),
    },
  };
};

// ---- Request bodies ----

const productBody = (forUpdate: boolean) =>
  object(
    {
      name: str({ maxLength: 200, example: "Lan hồ điệp trắng" }),
      description: nullable(str({ maxLength: 5000 })),
      price: int({ minimum: 1, example: 350000, description: "VND, số nguyên." }),
      stock: int({ minimum: 0, example: 10 }),
      categoryId: uuid(),
      sku: str({
        maxLength: 100,
        description: forUpdate ? "Bỏ trống để giữ SKU hiện tại." : "Bỏ trống để tự sinh.",
      }),
      taxRate: num({
        minimum: 0,
        maximum: 100,
        description: forUpdate ? "Phần trăm. Bỏ trống để giữ nguyên." : "Phần trăm, mặc định 0.",
      }),
      imageUrls: { type: "array", maxItems: 10, items: str({ format: "uri" }) },
      imageUrl: nullable(str({ format: "uri", description: "Alias một ảnh cho admin app." })),
      isActive: bool({ description: forUpdate ? "Bỏ trống để giữ nguyên." : "Mặc định true." }),
    },
    ["name", "price", "stock", "categoryId"]
  );

const categoryBody = (forUpdate: boolean) =>
  object(
    {
      name: str({ maxLength: 120, example: "Hoa tươi" }),
      slug: str({ pattern: "^[a-z0-9]+(?:-[a-z0-9]+)*$", example: "hoa-tuoi" }),
      imageUrl: nullable(str({ format: "uri" })),
      isActive: bool({ description: forUpdate ? "Bỏ trống để giữ nguyên." : "Mặc định true." }),
    },
    ["name", "slug"]
  );

const addressBody = (required: string[]) =>
  object(
    {
      recipientName: str({ maxLength: 100, example: "Nguyễn Minh Anh" }),
      recipientPhone: str({ example: "0901234567" }),
      addressLine: str({ example: "15 Nguyễn Thiện Thuật, Quận 3, TP.HCM" }),
      label: str({ maxLength: 50, example: "Nhà riêng" }),
      deliveryNote: str({ maxLength: 255 }),
      isDefault: bool(),
      latitude: num({ minimum: -90, maximum: 90 }),
      longitude: num({ minimum: -180, maximum: 180 }),
    },
    required
  );

// ---- Paths ----

const paths: Record<string, Record<string, Operation>> = {
  "/auth/login": {
    post: {
      tag: "Auth",
      summary: "Đăng nhập email/mật khẩu (Supabase)",
      description:
        "Trả `token` (access token) để dùng ở nút **Authorize**, kèm `refreshToken` và `profile`.",
      body: object(
        { email: str({ format: "email" }), password: str({ format: "password" }) },
        ["email", "password"]
      ),
      errors: [401, 403, 429, 503],
    },
  },
  "/auth/refresh": {
    post: {
      tag: "Auth",
      summary: "Đổi refresh token lấy access token mới",
      body: object({ refreshToken: str() }, ["refreshToken"]),
      errors: [401, 503],
    },
  },
  "/profile": {
    get: { tag: "Profile", summary: "Hồ sơ của tôi", auth: "user" },
    put: {
      tag: "Profile",
      summary: "Cập nhật hồ sơ",
      auth: "user",
      description: "USER hoặc ADMIN đều gọi được.",
      body: object({
        fullName: str({ maxLength: 100 }),
        phone: str({ example: "0901234567" }),
        avatarUrl: nullable(str({ format: "uri" })),
      }),
    },
  },
  "/categories": {
    get: {
      tag: "Catalog",
      summary: "Danh mục đang hiển thị",
      query: { search: str({ description: "Tìm theo tên." }) },
    },
  },
  "/products": {
    get: {
      tag: "Catalog",
      summary: "Danh sách sản phẩm đang bán",
      query: {
        ...pageQuery,
        search: str({ description: "Tìm theo tên hoặc SKU." }),
        categoryId: uuid(),
        minPrice: int({ minimum: 0 }),
        maxPrice: int({ minimum: 0 }),
        sort: enumOf(["newest", "price_asc", "price_desc"], { default: "newest" }),
      },
    },
  },
  "/products/{id}": {
    get: { tag: "Catalog", summary: "Chi tiết sản phẩm", params: ["id"] },
  },
  "/stores": {
    get: {
      tag: "Stores",
      summary: "Danh sách cửa hàng (kèm khoảng cách nếu gửi tọa độ)",
      query: { latitude: num(), longitude: num() },
    },
  },
  "/stores/shipping-estimate": {
    get: {
      tag: "Stores",
      summary: "Ước tính phí ship",
      query: { latitude: num(), longitude: num(), storeId: uuid() },
    },
    post: {
      tag: "Stores",
      summary: "Ước tính phí ship (body)",
      body: object(
        { latitude: num(), longitude: num(), storeId: uuid() },
        ["latitude", "longitude"]
      ),
    },
  },
  "/stores/{id}": {
    get: { tag: "Stores", summary: "Chi tiết cửa hàng", params: ["id"] },
  },
  "/cart": {
    get: { tag: "Cart", summary: "Giỏ hàng của tôi", auth: "user" },
  },
  "/cart/items": {
    post: {
      tag: "Cart",
      summary: "Thêm sản phẩm vào giỏ",
      auth: "user",
      success: 201,
      body: object({ productId: uuid(), quantity: int({ minimum: 1 }) }, ["productId", "quantity"]),
      errors: [404, 409],
    },
  },
  "/cart/items/{id}": {
    put: {
      tag: "Cart",
      summary: "Đổi số lượng",
      auth: "user",
      params: ["id"],
      body: object({ quantity: int({ minimum: 1 }) }, ["quantity"]),
      errors: [409],
    },
    delete: { tag: "Cart", summary: "Xóa khỏi giỏ", auth: "user", params: ["id"], success: 204 },
  },
  "/checkout": {
    post: {
      tag: "Checkout",
      summary: "Đặt hàng từ giỏ",
      description:
        "Tính tiền, thuế, phí ship ở server; trừ kho; tạo order + invoice và payment nếu SEPAY. " +
        "Với SEPAY, `payment.qrUrl` là ảnh VietQR (khi đã cấu hình SEPAY_BANK_ACCOUNT/SEPAY_BANK_CODE) " +
        "và `payment.paymentCode` là nội dung chuyển khoản.",
      auth: "user",
      success: 201,
      headers: {
        "Idempotency-Key": str({ description: "Chống bấm đặt hàng hai lần." }),
      },
      body: object(
        {
          receiverName: str({ example: "Pham Dinh" }),
          phone: str({ example: "0901234567" }),
          address: str({ example: "Ho Chi Minh City" }),
          latitude: num({ example: 10.762 }),
          longitude: num({ example: 106.682 }),
          paymentMethod: enumOf(["SEPAY", "COD"]),
          note: nullable(str({ maxLength: 500 })),
        },
        ["receiverName", "phone", "address", "latitude", "longitude", "paymentMethod"]
      ),
      errors: [404, 409],
    },
  },
  "/orders": {
    get: {
      tag: "Orders",
      summary: "Đơn hàng của tôi",
      auth: "user",
      query: { ...pageQuery, status: enumOf(ORDER_STATUS) },
    },
  },
  "/orders/{id}": {
    get: { tag: "Orders", summary: "Chi tiết đơn của tôi", auth: "user", params: ["id"] },
  },
  "/orders/{id}/cancel": {
    patch: {
      tag: "Orders",
      summary: "Hủy đơn (PENDING/CONFIRMED, chưa thanh toán)",
      description: "Hoàn kho, hủy invoice và payment đang chờ.",
      auth: "user",
      params: ["id"],
      body: object({ reason: nullable(str({ maxLength: 500 })) }),
      errors: [409],
    },
  },
  "/invoices": {
    get: {
      tag: "Invoices",
      summary: "Hóa đơn của tôi",
      auth: "user",
      query: { ...pageQuery, status: enumOf(INVOICE_STATUS) },
    },
  },
  "/invoices/{id}": {
    get: { tag: "Invoices", summary: "Chi tiết hóa đơn", auth: "user", params: ["id"] },
  },
  "/payments/{id}/status": {
    get: { tag: "Payments", summary: "Trạng thái thanh toán (để mobile polling)", auth: "user", params: ["id"] },
  },
  "/notifications": {
    get: {
      tag: "Notifications",
      summary: "Thông báo của tôi",
      auth: "user",
      query: { page: pageQuery.page, unreadOnly: enumOf(["true", "false"], { default: "false" }) },
    },
  },
  "/notifications/{id}/read": {
    patch: { tag: "Notifications", summary: "Đánh dấu đã đọc", auth: "user", params: ["id"] },
  },
  "/notifications/read-all": {
    patch: { tag: "Notifications", summary: "Đánh dấu tất cả đã đọc", auth: "user" },
  },
  "/addresses": {
    get: { tag: "Addresses", summary: "Sổ địa chỉ", auth: "user", description: "Alias: /user-addresses." },
    post: {
      tag: "Addresses",
      summary: "Thêm địa chỉ",
      auth: "user",
      success: 201,
      body: addressBody(["recipientName", "recipientPhone", "addressLine"]),
    },
  },
  "/addresses/{id}": {
    get: { tag: "Addresses", summary: "Chi tiết địa chỉ", auth: "user", params: ["id"] },
    put: { tag: "Addresses", summary: "Sửa địa chỉ", auth: "user", params: ["id"], body: addressBody([]) },
    delete: { tag: "Addresses", summary: "Xóa địa chỉ", auth: "user", params: ["id"] },
  },
  "/addresses/{id}/default": {
    patch: { tag: "Addresses", summary: "Đặt làm mặc định", auth: "user", params: ["id"] },
  },
  "/chatbot/messages": {
    post: {
      tag: "Chatbot",
      summary: "Gửi tin nhắn cho chatbot",
      auth: "user",
      body: object(
        {
          conversationId: nullable(uuid({ description: "Bỏ trống để mở cuộc trò chuyện mới." })),
          message: str({ minLength: 1, maxLength: 2000, example: "Cây kim tiền tưới mấy lần một tuần?" }),
          productId: nullable(uuid()),
          context: object({
            orderId: nullable(uuid()),
            paymentId: nullable(uuid()),
            source: nullable(str()),
          }),
        },
        ["message"]
      ),
      errors: [429, 502, 503],
    },
  },
  "/chatbot/conversations/{id}/messages": {
    get: {
      tag: "Chatbot",
      summary: "Lịch sử tin nhắn",
      auth: "user",
      params: ["id"],
      query: { page: pageQuery.page },
    },
  },
  "/chatbot/conversations/{id}": {
    delete: { tag: "Chatbot", summary: "Xóa cuộc trò chuyện", auth: "user", params: ["id"], success: 204 },
  },
  "/webhooks/sepay": {
    post: {
      tag: "Webhooks",
      summary: "Nhận giao dịch từ SePay",
      description:
        "Header `X-SePay-Signature: sha256=<hex>` và `X-SePay-Timestamp: <unix giây>`; " +
        "chữ ký = HMAC-SHA256(SEPAY_WEBHOOK_SECRET, `{timestamp}.{raw body}`). " +
        "Trả 503 khi chưa cấu hình SEPAY_WEBHOOK_SECRET.",
      auth: "sepay",
      body: object(
        {
          id: { oneOf: [str(), int()] },
          gateway: str({ example: "MBBank" }),
          transactionDate: str({ example: "2026-10-31 10:00:00" }),
          accountNumber: str(),
          code: nullable(str()),
          content: str({ example: "PAY20261031ABCDEF123456" }),
          transferType: enumOf(["in", "out"]),
          transferAmount: int({ minimum: 1 }),
          referenceCode: str(),
        },
        ["id", "transferType", "transferAmount"]
      ),
      errors: [400, 401, 503],
    },
  },

  // ---- Admin ----
  "/admin/dashboard": {
    get: {
      tag: "Admin · Dashboard",
      summary: "Thống kê tổng quan",
      description: "Không gửi from/to: doanh thu toàn thời gian, biểu đồ 30 ngày gần nhất (giờ VN).",
      auth: "admin",
      query: {
        from: str({ description: "YYYY-MM-DD hoặc ISO 8601.", example: "2026-10-01" }),
        to: str({ description: "YYYY-MM-DD (tính cả ngày đó) hoặc ISO 8601.", example: "2026-10-31" }),
      },
    },
  },
  "/admin/users": {
    get: {
      tag: "Admin · Users",
      summary: "Danh sách người dùng",
      auth: "admin",
      query: {
        ...pageQuery,
        search: str({ description: "Email, tên hoặc số điện thoại." }),
        role: enumOf(["USER", "ADMIN"]),
        status: enumOf(["ACTIVE", "DISABLED"]),
      },
    },
  },
  "/admin/users/{id}": {
    get: { tag: "Admin · Users", summary: "Chi tiết người dùng (kèm orderCount, totalPaid)", auth: "admin", params: ["id"] },
    patch: {
      tag: "Admin · Users",
      summary: "Đổi role/khóa tài khoản",
      description: "Không cho tự khóa/tự hạ quyền, không cho khóa admin ACTIVE cuối cùng.",
      auth: "admin",
      params: ["id"],
      body: object({ role: enumOf(["USER", "ADMIN"]), status: enumOf(["ACTIVE", "DISABLED"]) }),
      errors: [409],
    },
  },
  "/admin/categories": {
    get: { tag: "Admin · Catalog", summary: "Tất cả danh mục (cả đang ẩn)", auth: "admin", query: { search: str() } },
    post: {
      tag: "Admin · Catalog",
      summary: "Tạo danh mục",
      auth: "admin",
      success: 201,
      body: categoryBody(false),
      errors: [409],
    },
  },
  "/admin/categories/{id}": {
    put: {
      tag: "Admin · Catalog",
      summary: "Sửa danh mục (PATCH cũng được)",
      auth: "admin",
      params: ["id"],
      body: categoryBody(true),
      errors: [409],
    },
    delete: {
      tag: "Admin · Catalog",
      summary: "Xóa danh mục (409 nếu còn sản phẩm)",
      auth: "admin",
      params: ["id"],
      success: 204,
      errors: [409],
    },
  },
  "/admin/products": {
    get: {
      tag: "Admin · Catalog",
      summary: "Tất cả sản phẩm (cả đang ẩn)",
      auth: "admin",
      query: {
        ...pageQuery,
        search: str(),
        categoryId: uuid(),
        isActive: enumOf(["true", "false"]),
      },
    },
    post: {
      tag: "Admin · Catalog",
      summary: "Tạo sản phẩm",
      auth: "admin",
      success: 201,
      body: productBody(false),
      errors: [404, 409],
    },
  },
  "/admin/products/{id}": {
    get: { tag: "Admin · Catalog", summary: "Chi tiết sản phẩm", auth: "admin", params: ["id"] },
    put: {
      tag: "Admin · Catalog",
      summary: "Sửa sản phẩm",
      auth: "admin",
      params: ["id"],
      body: productBody(true),
      errors: [409],
    },
    delete: {
      tag: "Admin · Catalog",
      summary: "Xóa sản phẩm (409 nếu đã có trong đơn/hóa đơn — hãy ẩn bằng isActive=false)",
      auth: "admin",
      params: ["id"],
      success: 204,
      errors: [409],
    },
  },
  "/admin/orders": {
    get: {
      tag: "Admin · Orders",
      summary: "Danh sách đơn hàng (kèm items)",
      auth: "admin",
      query: {
        ...pageQuery,
        status: enumOf(ORDER_STATUS),
        paymentStatus: enumOf(PAYMENT_STATUS),
        search: str({ description: "Mã đơn, tên/SĐT người nhận, email khách." }),
      },
    },
  },
  "/admin/orders/{id}": {
    get: { tag: "Admin · Orders", summary: "Chi tiết đơn hàng", auth: "admin", params: ["id"] },
  },
  "/admin/orders/{id}/status": {
    patch: {
      tag: "Admin · Orders",
      summary: "Chuyển trạng thái đơn",
      description:
        "PENDING → CONFIRMED → PREPARING → SHIPPING → COMPLETED; PENDING/CONFIRMED → CANCELLED. " +
        "Đơn SEPAY phải được thanh toán trước khi xử lý tiếp. COD giao xong thì invoice thành PAID.",
      auth: "admin",
      params: ["id"],
      body: object(
        {
          status: enumOf(["CONFIRMED", "PREPARING", "SHIPPING", "COMPLETED", "CANCELLED"]),
          note: nullable(str({ maxLength: 500 })),
        },
        ["status"]
      ),
      errors: [409],
    },
  },
  "/admin/invoices": {
    get: {
      tag: "Admin · Billing",
      summary: "Danh sách hóa đơn",
      auth: "admin",
      query: {
        ...pageQuery,
        status: enumOf(INVOICE_STATUS),
        search: str({ description: "Số hóa đơn, mã đơn, tên/SĐT khách." }),
      },
    },
  },
  "/admin/invoices/{id}": {
    get: { tag: "Admin · Billing", summary: "Chi tiết hóa đơn", auth: "admin", params: ["id"] },
  },
  "/admin/payments": {
    get: {
      tag: "Admin · Billing",
      summary: "Danh sách thanh toán",
      auth: "admin",
      query: {
        ...pageQuery,
        status: enumOf(PAYMENT_STATUS),
        provider: enumOf(["SEPAY", "COD"]),
        search: str({ description: "Mã thanh toán, số hóa đơn, mã đơn." }),
      },
    },
  },
  "/admin/sepay-transactions": {
    get: {
      tag: "Admin · Billing",
      summary: "Giao dịch SePay đã nhận",
      auth: "admin",
      query: {
        ...pageQuery,
        matched: enumOf(["true", "false"], { description: "Đã ghép với thanh toán hay chưa." }),
        search: str(),
      },
    },
  },
  "/admin/sepay-transactions/{id}/match": {
    post: {
      tag: "Admin · Billing",
      summary: "Ghép thủ công giao dịch vào đơn hàng",
      description: "Dùng khi khách ghi sai nội dung chuyển khoản. Số tiền phải khớp chính xác.",
      auth: "admin",
      params: ["id"],
      body: object({ orderCode: str({ example: "ORD-20261031-ABCDEF123456" }) }, ["orderCode"]),
      errors: [409],
    },
  },
};

export const buildOpenApiDocument = (serverUrl = "/api/v1") => ({
  openapi: "3.0.3",
  info: {
    title: "Plant & Flower Shop API",
    version: "1.0.0",
    description:
      "REST API cho app mobile (USER) và app quản trị (ADMIN).\n\n" +
      "**Cách thử API cần đăng nhập:** gọi `POST /auth/login`, copy `data.token`, " +
      "bấm **Authorize** và dán token vào.\n\n" +
      "Mọi response có dạng `{ success, data, meta }` hoặc `{ success: false, error: { code, message, details } }`.",
  },
  servers: [{ url: serverUrl }],
  tags: [
    "Auth",
    "Profile",
    "Catalog",
    "Stores",
    "Cart",
    "Checkout",
    "Orders",
    "Invoices",
    "Payments",
    "Notifications",
    "Addresses",
    "Chatbot",
    "Webhooks",
    "Admin · Dashboard",
    "Admin · Users",
    "Admin · Catalog",
    "Admin · Orders",
    "Admin · Billing",
  ].map((name) => ({ name })),
  components: {
    securitySchemes: {
      bearerAuth: { type: "http", scheme: "bearer", bearerFormat: "JWT (Supabase access token)" },
    },
    schemas: {
      Success: object({
        success: bool({ example: true }),
        data: { description: "Dữ liệu trả về; danh sách nằm trong data.items." },
        meta: object({
          requestId: str(),
          timestamp: str({ format: "date-time" }),
          page: int(),
          limit: int(),
          total: int(),
          totalPages: int(),
        }),
      }),
      Error: object({
        success: bool({ example: false }),
        error: object({
          code: str({ example: "VALIDATION_ERROR" }),
          message: str(),
          details: nullable({ type: "object", description: "Chi tiết lỗi validate nếu có." }),
        }),
        meta: object({ requestId: str(), timestamp: str({ format: "date-time" }) }),
      }),
    },
  },
  paths: Object.fromEntries(
    Object.entries(paths).map(([path, methods]) => [
      path,
      Object.fromEntries(
        Object.entries(methods).map(([method, op]) => [method, buildOperation(op)])
      ),
    ])
  ),
});
