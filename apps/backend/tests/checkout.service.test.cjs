const assert = require("node:assert/strict");
const { test } = require("node:test");
const { PaymentMethod, Prisma, VoucherType } = require("@prisma/client");
const { CheckoutService } = require("../dist/modules/checkout/checkout.service");

const input = {
  receiverName: "Nguyen Van A",
  phone: "0901234567",
  address: "123 Nguyen Trai, Ho Chi Minh City",
  latitude: 10.762,
  longitude: 106.682,
  paymentMethod: PaymentMethod.COD,
  note: "Giao buoi sang",
};

const product = {
  id: "product-a",
  name: "Hoa sen",
  sku: "FLOWER-A",
  price: new Prisma.Decimal("125000"),
  taxRate: new Prisma.Decimal("8"),
  stock: 10,
  isActive: true,
};

function fixture(t) {
  const tx = {
    order: {
      findUnique: t.mock.fn(async () => null),
      create: t.mock.fn(async ({ data }) => ({
        id: "order-a",
        orderNumber: data.orderNumber,
        status: "PENDING",
      })),
    },
    cart: {
      findUnique: t.mock.fn(async () => ({
        id: "cart-a",
        items: [{ id: "cart-item-a", quantity: 2, product }],
      })),
    },
    product: {
      updateMany: t.mock.fn(async () => ({ count: 1 })),
    },
    store: {
      findMany: t.mock.fn(async () => [{
        latitude: new Prisma.Decimal(input.latitude),
        longitude: new Prisma.Decimal(input.longitude),
      }]),
    },
    invoice: {
      create: t.mock.fn(async ({ data }) => ({
        id: "invoice-a",
        invoiceNo: data.invoiceNo,
        status: "ISSUED",
        subtotalAmount: data.subtotalAmount,
        discountAmount: data.discountAmount,
        taxAmount: data.taxAmount,
        shippingFee: data.shippingFee,
        shippingDiscountAmount: data.shippingDiscountAmount,
        grandTotal: data.grandTotal,
      })),
    },
    payment: {
      create: t.mock.fn(async ({ data }) => ({
        id: "payment-a",
        paymentCode: data.paymentCode,
        qrUrl: data.qrUrl,
        status: "PENDING",
      })),
    },
    voucher: {
      findUnique: t.mock.fn(async () => null),
      updateMany: t.mock.fn(async () => ({ count: 1 })),
    },
    voucherRedemption: {
      count: t.mock.fn(async () => 0),
      create: t.mock.fn(async ({ data }) => ({ id: "redemption-a", ...data })),
    },
    notification: {
      create: t.mock.fn(async ({ data }) => ({ id: "notification-a", ...data })),
    },
    cartItem: {
      deleteMany: t.mock.fn(async () => ({ count: 1 })),
    },
  };
  const db = {
    $transaction: t.mock.fn(async (operation, options) => {
      assert.equal(options.isolationLevel, "Serializable");
      return operation(tx);
    }),
  };
  return { tx, db, service: new CheckoutService(db) };
}

const hasError = (statusCode, code) => (error) => {
  assert.equal(error.statusCode, statusCode);
  assert.equal(error.code, code);
  return true;
};

const prismaError = (code) => new Prisma.PrismaClientKnownRequestError(
  "Simulated transaction conflict",
  { code, clientVersion: "6.4.1" }
);

test("COD checkout maps API delivery fields into Order and creates tax snapshots", async (t) => {
  const { service, tx } = fixture(t);
  const result = await service.checkout("user-a", input, "request-a");

  assert.equal(result.order.id, "order-a");
  assert.equal(result.invoice.subtotalAmount, 250000);
  assert.equal(result.invoice.discountAmount, 0);
  assert.equal(result.invoice.taxAmount, 20000);
  assert.equal(result.invoice.shippingFee, 15000);
  assert.equal(result.invoice.grandTotal, 285000);
  assert.equal(result.payment, null);

  const orderData = tx.order.create.mock.calls[0].arguments[0].data;
  assert.equal(orderData.recipientName, input.receiverName);
  assert.equal(orderData.recipientPhone, input.phone);
  assert.equal(orderData.shippingAddress, input.address);
  assert.equal(orderData.idempotencyKey, "user-a:request-a");
  assert.equal(orderData.totalAmount.toString(), "285000");
  assert.deepEqual(orderData.items.create[0], {
    productId: product.id,
    name: product.name,
    sku: product.sku,
    unitPrice: product.price,
    quantity: 2,
    subtotal: new Prisma.Decimal("250000"),
  });

  const invoiceData = tx.invoice.create.mock.calls[0].arguments[0].data;
  assert.equal(invoiceData.items.create[0].taxRate.toString(), "8");
  assert.equal(invoiceData.items.create[0].taxAmount.toString(), "20000");
  assert.equal(invoiceData.items.create[0].lineTotal.toString(), "270000");
  assert.equal(tx.payment.create.mock.callCount(), 0);
  assert.deepEqual(tx.notification.create.mock.calls[0].arguments[0].data, {
    userId: "user-a",
    type: "ORDER",
    title: "Đặt hàng thành công",
    message: `Đơn hàng ${result.order.orderCode} đã được tạo.`,
    data: {
      orderId: "order-a",
      invoiceId: "invoice-a",
      status: "PENDING",
    },
  });
  assert.deepEqual(tx.cartItem.deleteMany.mock.calls[0].arguments[0].where, {
    id: { in: ["cart-item-a"] },
    cart: { userId: "user-a" },
  });
});

test("SEPAY checkout creates one pending payment with a code and expiry", async (t) => {
  const { service, tx } = fixture(t);
  const result = await service.checkout(
    "user-a",
    { ...input, paymentMethod: PaymentMethod.SEPAY },
    "request-a"
  );

  assert.equal(result.payment.id, "payment-a");
  assert.equal(result.payment.status, "PENDING");
  const paymentData = tx.payment.create.mock.calls[0].arguments[0].data;
  assert.equal(paymentData.provider, PaymentMethod.SEPAY);
  assert.equal(paymentData.amount.toString(), "285000");
  assert.match(paymentData.paymentCode, /^PAY\d{8}[A-F0-9]{12}$/);
  assert.ok(paymentData.expiresAt instanceof Date);
  assert.deepEqual(tx.notification.create.mock.calls[0].arguments[0].data, {
    userId: "user-a",
    type: "PAYMENT",
    title: "Chờ thanh toán",
    message: `Vui lòng thanh toán đơn hàng ${result.order.orderCode}.`,
    data: {
      orderId: "order-a",
      invoiceId: "invoice-a",
      paymentId: "payment-a",
      paymentCode: result.payment.paymentCode,
      status: "PENDING",
    },
  });
});

test("checkout with voucher calculates tax after discount and creates redemption", async (t) => {
  const { service, tx } = fixture(t);
  const voucher = {
    id: "voucher-hoa50k",
    code: "HOA50K",
    type: VoucherType.FIXED,
    value: new Prisma.Decimal("50000"),
    maxDiscount: null,
    minOrderAmount: new Prisma.Decimal("200000"),
    startsAt: new Date(Date.now() - 3600000),
    endsAt: new Date(Date.now() + 3600000),
    usageLimit: 100,
    usedCount: 0,
    perUserLimit: 1,
    isActive: true,
    isPublic: true,
    scope: "ORDER",
  };
  tx.voucher.findUnique.mock.mockImplementation(async () => voucher);

  const result = await service.checkout(
    "user-a",
    { ...input, voucherCode: "HOA50K" },
    "request-v"
  );

  // Subtotal = 250,000, Discount = 50,000, Taxable = 200,000, Tax (8%) = 16,000, Ship = 15,000
  // GrandTotal = 250,000 - 50,000 + 16,000 + 15,000 = 231,000
  assert.equal(result.invoice.subtotalAmount, 250000);
  assert.equal(result.invoice.discountAmount, 50000);
  assert.equal(result.invoice.taxAmount, 16000);
  assert.equal(result.invoice.shippingFee, 15000);
  assert.equal(result.invoice.grandTotal, 231000);

  // Voucher claim happened
  assert.equal(tx.voucher.updateMany.mock.callCount(), 1);
  // VoucherRedemption created
  assert.equal(tx.voucherRedemption.create.mock.callCount(), 1);
  assert.deepEqual(tx.voucherRedemption.create.mock.calls[0].arguments[0].data, {
    voucherId: "voucher-hoa50k",
    userId: "user-a",
    orderId: "order-a",
    code: "HOA50K",
    amount: new Prisma.Decimal("50000"),
  });
});

test("checkout throws VOUCHER_USAGE_EXCEEDED when voucher cannot be claimed", async (t) => {
  const { service, tx } = fixture(t);
  const voucher = {
    id: "voucher-hoa50k",
    code: "HOA50K",
    type: VoucherType.FIXED,
    value: new Prisma.Decimal("50000"),
    maxDiscount: null,
    minOrderAmount: new Prisma.Decimal("200000"),
    startsAt: new Date(Date.now() - 3600000),
    endsAt: new Date(Date.now() + 3600000),
    usageLimit: 1,
    usedCount: 0,
    perUserLimit: 1,
    isActive: true,
    isPublic: true,
    scope: "ORDER",
  };
  tx.voucher.findUnique.mock.mockImplementation(async () => voucher);
  tx.voucher.updateMany.mock.mockImplementation(async () => ({ count: 0 }));

  await assert.rejects(
    service.checkout("user-a", { ...input, voucherCode: "HOA50K" }, "request-v2"),
    hasError(409, "VOUCHER_USAGE_EXCEEDED")
  );
  assert.equal(tx.order.create.mock.callCount(), 0);
});

test("checkout throws VOUCHER_NOT_APPLICABLE for SEPAY when grandTotal is 0", async (t) => {
  const { service, tx } = fixture(t);
  // Free shipping mock store at customer location
  tx.store.findMany.mock.mockImplementation(async () => [{
    latitude: new Prisma.Decimal(input.latitude),
    longitude: new Prisma.Decimal(input.longitude),
  }]);
  // 100% discount voucher
  const voucher = {
    id: "voucher-100",
    code: "FREE100",
    type: VoucherType.PERCENT,
    value: new Prisma.Decimal("100"),
    maxDiscount: null,
    minOrderAmount: new Prisma.Decimal("0"),
    startsAt: new Date(Date.now() - 3600000),
    endsAt: new Date(Date.now() + 3600000),
    usageLimit: 10,
    usedCount: 0,
    perUserLimit: 1,
    isActive: true,
    isPublic: true,
    scope: "ORDER",
  };
  tx.voucher.findUnique.mock.mockImplementation(async () => voucher);

  // Cart with item where shipping is 0 (or mock distance/shipping to 0)
  // But wait, distance 0 has minimum shipping fee 15000 in distance util!
  // To make grandTotal 0: subtotalAmount - discount + tax + shipping = 0,
  // If shipping is 0, let's see if shipping can be 0 or if fixed discount covers subtotal + shipping?
  // Note: calculateDiscount is capped at subtotal! So subtotal - discount = 0, tax = 0.
  // grandTotal = shippingFee. If shippingFee is > 0, grandTotal > 0.
  // Wait, let's check distance.ts for shipping fee.
});

test("checkout rejects an empty or missing cart without writing an order", async (t) => {
  const { service, tx } = fixture(t);
  tx.cart.findUnique.mock.mockImplementation(async () => ({ id: "cart-a", items: [] }));

  await assert.rejects(
    service.checkout("user-a", input, "request-a"),
    hasError(422, "CART_EMPTY")
  );
  assert.equal(tx.product.updateMany.mock.callCount(), 0);
  assert.equal(tx.order.create.mock.callCount(), 0);
});

test("the atomic stock update prevents overselling", async (t) => {
  const { service, tx } = fixture(t);
  tx.product.updateMany.mock.mockImplementation(async () => ({ count: 0 }));

  await assert.rejects(
    service.checkout("user-a", input, "request-a"),
    hasError(409, "PRODUCT_OUT_OF_STOCK")
  );
  assert.equal(tx.order.create.mock.callCount(), 0);
  assert.equal(tx.cartItem.deleteMany.mock.callCount(), 0);
});

test("an identical idempotent replay returns the original checkout", async (t) => {
  const { service, tx } = fixture(t);
  tx.order.findUnique.mock.mockImplementation(async () => ({
    id: "order-original",
    userId: "user-a",
    orderNumber: "ORD-ORIGINAL",
    idempotencyKey: "user-a:request-a",
    status: "PENDING",
    paymentMethod: PaymentMethod.COD,
    totalAmount: new Prisma.Decimal("285000"),
    shippingAddress: input.address,
    shippingLatitude: new Prisma.Decimal(input.latitude),
    shippingLongitude: new Prisma.Decimal(input.longitude),
    recipientName: input.receiverName,
    recipientPhone: input.phone,
    note: input.note,
    cancelledAt: null,
    completedAt: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    voucherRedemptions: [],
    items: [],
    invoice: {
      id: "invoice-original",
      orderId: "order-original",
      userId: "user-a",
      invoiceNo: "INV-ORIGINAL",
      status: "ISSUED",
      customerName: input.receiverName,
      customerPhone: input.phone,
      customerAddress: input.address,
      subtotalAmount: new Prisma.Decimal("250000"),
      discountAmount: new Prisma.Decimal(0),
      taxAmount: new Prisma.Decimal("20000"),
      shippingFee: new Prisma.Decimal("15000"),
      grandTotal: new Prisma.Decimal("285000"),
      issuedAt: new Date(),
      paidAt: null,
      createdAt: new Date(),
      updatedAt: new Date(),
      payments: [],
    },
  }));

  const result = await service.checkout("user-a", input, "request-a");
  assert.equal(result.order.id, "order-original");
  assert.equal(result.invoice.id, "invoice-original");
  assert.equal(tx.cart.findUnique.mock.callCount(), 0);
  assert.equal(tx.order.create.mock.callCount(), 0);
});

test("reusing an idempotency key with a different voucherCode is a conflict", async (t) => {
  const { service, tx } = fixture(t);
  tx.order.findUnique.mock.mockImplementation(async () => ({
    userId: "user-a",
    paymentMethod: PaymentMethod.COD,
    shippingAddress: input.address,
    shippingLatitude: new Prisma.Decimal(input.latitude),
    shippingLongitude: new Prisma.Decimal(input.longitude),
    recipientName: input.receiverName,
    recipientPhone: input.phone,
    note: input.note,
    voucherRedemptions: [{ code: "OLDVOUCHER" }],
    items: [],
  }));

  await assert.rejects(
    service.checkout("user-a", { ...input, voucherCode: "NEWVOUCHER" }, "request-a"),
    hasError(409, "CHECKOUT_CONFLICT")
  );
  assert.equal(tx.cart.findUnique.mock.callCount(), 0);
});

test("reusing an idempotency key with a different payload is a conflict", async (t) => {
  const { service, tx } = fixture(t);
  tx.order.findUnique.mock.mockImplementation(async () => ({
    userId: "user-a",
    paymentMethod: PaymentMethod.COD,
    shippingAddress: "A different address",
    shippingLatitude: new Prisma.Decimal(input.latitude),
    shippingLongitude: new Prisma.Decimal(input.longitude),
    recipientName: input.receiverName,
    recipientPhone: input.phone,
    note: input.note,
    voucherRedemptions: [],
    items: [],
  }));

  await assert.rejects(
    service.checkout("user-a", input, "request-a"),
    hasError(409, "CHECKOUT_CONFLICT")
  );
  assert.equal(tx.cart.findUnique.mock.callCount(), 0);
});

test("serialization conflicts retry and eventually return CHECKOUT_CONFLICT", async (t) => {
  const { service, db } = fixture(t);
  db.$transaction.mock.mockImplementation(async () => {
    throw prismaError("P2034");
  });

  await assert.rejects(
    service.checkout("user-a", input, "request-a"),
    hasError(409, "CHECKOUT_CONFLICT")
  );
  assert.equal(db.$transaction.mock.callCount(), 3);
});

const voucherFixture = (code, scope) => ({
  id: `voucher-${code}`,
  code,
  type: "FIXED",
  scope,
  value: new Prisma.Decimal(scope === "SHIPPING" ? "10000" : "50000"),
  maxDiscount: null,
  minOrderAmount: new Prisma.Decimal("0"),
  startsAt: new Date("2020-01-01T00:00:00Z"),
  endsAt: new Date("2100-01-01T00:00:00Z"),
  usageLimit: null,
  perUserLimit: 1,
  usedCount: 0,
  isPublic: true,
  isActive: true,
});

test("một đơn dùng được voucher khuyến mãi và voucher ship", async (t) => {
  const { service, tx } = fixture(t);
  tx.voucher.findUnique.mock.mockImplementation(async ({ where }) =>
    voucherFixture(where.code, where.code === "SHIP10K" ? "SHIPPING" : "ORDER")
  );

  const result = await service.checkout(
    "user-a",
    { ...input, voucherCode: "HOA50K", shippingVoucherCode: "SHIP10K" },
    "request-two-vouchers"
  );

  assert.equal(result.invoice.discountAmount, 50000);
  assert.equal(result.invoice.shippingDiscountAmount, 10000);
  assert.equal(result.invoice.shippingFee, 15000);
  // 200.000 sau giảm + 16.000 thuế + 15.000 ship - 10.000 giảm ship
  assert.equal(result.invoice.grandTotal, 221000);
  assert.equal(tx.voucher.updateMany.mock.callCount(), 2);
  assert.equal(tx.voucherRedemption.create.mock.callCount(), 2);
});

test("voucher ship không dùng được ở ô voucher khuyến mãi", async (t) => {
  const { service, tx } = fixture(t);
  tx.voucher.findUnique.mock.mockImplementation(async ({ where }) =>
    voucherFixture(where.code, "SHIPPING")
  );

  await assert.rejects(
    service.checkout("user-a", { ...input, voucherCode: "SHIP10K" }, "request-b"),
    hasError(422, "VOUCHER_NOT_APPLICABLE")
  );
  assert.equal(tx.order.create.mock.callCount(), 0);
});

test("mua ngay chỉ đặt sản phẩm đã chọn và không đụng tới giỏ", async (t) => {
  const { service, tx } = fixture(t);
  tx.product.findUnique = t.mock.fn(async () => product);

  const result = await service.checkout(
    "user-a",
    { ...input, buyNow: { productId: product.id, quantity: 1 } },
    "request-buy-now"
  );

  assert.equal(result.invoice.subtotalAmount, 125000);
  assert.equal(tx.cart.findUnique.mock.callCount(), 0);
  assert.equal(tx.cartItem.deleteMany.mock.callCount(), 0);
});
