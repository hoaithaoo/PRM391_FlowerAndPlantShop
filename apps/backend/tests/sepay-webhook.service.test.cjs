const assert = require("node:assert/strict");
const { test } = require("node:test");
const { Prisma } = require("@prisma/client");

let SepayWebhookService;
let loadError;
try {
  ({ SepayWebhookService } = require("../dist/modules/webhooks/sepay-webhook.service"));
} catch (error) {
  loadError = error;
}

const now = new Date("2026-10-25T08:00:00.000Z");
const payload = {
  id: "92704",
  gateway: "Vietcombank",
  transactionDate: "2026-10-25 14:30:00",
  accountNumber: "1017588888",
  code: "PAY20261025ABCDEF123456",
  content: "PAY20261025ABCDEF123456 chuyen tien",
  transferType: "IN",
  transferAmount: 285000,
  referenceCode: "FT24012345678",
};

function fixture(t) {
  assert.ifError(loadError);
  const payment = {
    id: "payment-a",
    invoiceId: "invoice-a",
    paymentCode: payload.code,
    amount: new Prisma.Decimal("285000"),
    status: "PENDING",
    expiresAt: new Date("2026-10-25T08:15:00.000Z"),
    invoice: {
      userId: "user-a",
      orderId: "order-a",
      invoiceNo: "INV-001",
      status: "ISSUED",
    },
  };
  const tx = {
    sepayTransaction: {
      findUnique: t.mock.fn(async () => null),
      create: t.mock.fn(async ({ data }) => ({
        id: "transaction-internal-a",
        sepayTransactionId: data.sepayTransactionId,
      })),
    },
    payment: {
      findUnique: t.mock.fn(async () => payment),
      updateMany: t.mock.fn(async () => ({ count: 1 })),
    },
    invoice: {
      updateMany: t.mock.fn(async () => ({ count: 1 })),
    },
    notification: {
      create: t.mock.fn(async ({ data }) => ({ id: "notification-a", ...data })),
    },
  };
  const db = {
    $transaction: t.mock.fn(async (operation) => operation(tx)),
  };
  return { tx, payment, service: new SepayWebhookService(db, () => now) };
}

test("matching incoming transfer atomically pays the invoice and notifies its owner", async (t) => {
  const { tx, service } = fixture(t);

  assert.deepEqual(await service.process(payload), {
    accepted: true,
    transactionId: "92704",
  });
  assert.equal(tx.sepayTransaction.create.mock.calls[0].arguments[0].data.paymentId, "payment-a");
  assert.deepEqual(tx.payment.updateMany.mock.calls[0].arguments[0], {
    where: { id: "payment-a", status: "PENDING" },
    data: { status: "PAID", paidAt: now },
  });
  assert.deepEqual(tx.invoice.updateMany.mock.calls[0].arguments[0], {
    where: { id: "invoice-a", status: "ISSUED" },
    data: { status: "PAID", paidAt: now },
  });
  assert.deepEqual(tx.notification.create.mock.calls[0].arguments[0].data, {
    userId: "user-a",
    type: "PAYMENT",
    title: "Thanh toán thành công",
    message: "Thanh toán cho hóa đơn INV-001 đã được xác nhận.",
    data: {
      paymentId: "payment-a",
      invoiceId: "invoice-a",
      orderId: "order-a",
      status: "PAID",
    },
  });
});

test("duplicate provider transaction is accepted without repeating side effects", async (t) => {
  const { tx, service } = fixture(t);
  tx.sepayTransaction.findUnique.mock.mockImplementation(async () => ({
    sepayTransactionId: payload.id,
  }));

  assert.deepEqual(await service.process(payload), {
    accepted: true,
    transactionId: "92704",
  });
  assert.equal(tx.sepayTransaction.create.mock.callCount(), 0);
  assert.equal(tx.payment.findUnique.mock.callCount(), 0);
  assert.equal(tx.notification.create.mock.callCount(), 0);
});

test("amount mismatch stores the transfer and puts the pending payment in review", async (t) => {
  const { tx, service } = fixture(t);
  await service.process({ ...payload, transferAmount: 280000 });

  assert.deepEqual(tx.payment.updateMany.mock.calls[0].arguments[0], {
    where: { id: "payment-a", status: "PENDING" },
    data: { status: "REVIEW" },
  });
  assert.equal(tx.invoice.updateMany.mock.callCount(), 0);
  assert.equal(tx.notification.create.mock.calls[0].arguments[0].data.data.status, "REVIEW");
});

test("payment for a cancelled invoice goes to review instead of paid", async (t) => {
  const { tx, payment, service } = fixture(t);
  payment.invoice.status = "CANCELLED";

  await service.process(payload);

  assert.deepEqual(tx.payment.updateMany.mock.calls[0].arguments[0], {
    where: { id: "payment-a", status: "PENDING" },
    data: { status: "REVIEW" },
  });
  assert.equal(tx.invoice.updateMany.mock.callCount(), 0);
  assert.equal(tx.notification.create.mock.calls[0].arguments[0].data.data.status, "REVIEW");
});

test("late incoming transfer moves an expired payment to review", async (t) => {
  const { tx, payment, service } = fixture(t);
  payment.status = "EXPIRED";
  payment.expiresAt = new Date("2026-10-25T07:59:00.000Z");

  await service.process(payload);

  assert.deepEqual(tx.payment.updateMany.mock.calls[0].arguments[0], {
    where: { id: "payment-a", status: "EXPIRED" },
    data: { status: "REVIEW" },
  });
  assert.equal(tx.invoice.updateMany.mock.callCount(), 0);
  assert.equal(tx.notification.create.mock.calls[0].arguments[0].data.data.status, "REVIEW");
});

test("invoice cancellation racing with payment confirmation downgrades payment to review", async (t) => {
  const { tx, service } = fixture(t);
  tx.invoice.updateMany.mock.mockImplementation(async () => ({ count: 0 }));

  await service.process(payload);

  assert.deepEqual(tx.payment.updateMany.mock.calls[1].arguments[0], {
    where: { id: "payment-a", status: "PAID", paidAt: now },
    data: { status: "REVIEW", paidAt: null },
  });
  assert.equal(tx.notification.create.mock.calls[0].arguments[0].data.data.status, "REVIEW");
});

test("unmatched payment code is stored for admin review without changing a payment", async (t) => {
  const { tx, service } = fixture(t);
  tx.payment.findUnique.mock.mockImplementation(async () => null);

  await service.process({ ...payload, code: null, content: "unknown transfer" });

  assert.equal(tx.sepayTransaction.create.mock.calls[0].arguments[0].data.paymentId, null);
  assert.equal(tx.payment.updateMany.mock.callCount(), 0);
  assert.equal(tx.invoice.updateMany.mock.callCount(), 0);
  assert.equal(tx.notification.create.mock.callCount(), 0);
});
