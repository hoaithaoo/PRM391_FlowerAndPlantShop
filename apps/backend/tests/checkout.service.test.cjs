const assert = require("node:assert/strict");
const { test } = require("node:test");
const { PaymentMethod, Prisma } = require("@prisma/client");
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
        taxAmount: data.taxAmount,
        shippingFee: data.shippingFee,
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
    cartId: "cart-a",
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
