const assert = require("node:assert/strict");
const { test } = require("node:test");
const { Prisma } = require("@prisma/client");

let PaymentService;
let loadError;
try {
  ({ PaymentService } = require("../dist/modules/payments/payment.service"));
} catch (error) {
  loadError = error;
}

const now = new Date("2026-10-25T08:00:00.000Z");
const payment = {
  id: "payment-a",
  invoiceId: "invoice-a",
  provider: "SEPAY",
  paymentCode: "PAY20261025ABCDEF123456",
  amount: new Prisma.Decimal("285000"),
  status: "PENDING",
  paidAt: null,
  expiresAt: new Date("2026-10-25T07:59:00.000Z"),
};

function fixture(t) {
  assert.ifError(loadError);
  const tx = {
    payment: {
      updateMany: t.mock.fn(async () => ({ count: 1 })),
      // Đơn đã qua bước hủy được: test này chỉ kiểm tra đổi trạng thái payment.
      findUnique: t.mock.fn(async () => ({
        invoice: { status: "ISSUED", order: { id: "order-a", status: "PREPARING" } },
      })),
    },
  };
  const dbPayment = {
    findMany: t.mock.fn(async () => [{ id: "payment-a" }]),
    findFirst: t.mock.fn(async () => ({ ...payment, status: "EXPIRED" })),
  };
  const db = {
    payment: dbPayment,
    $transaction: t.mock.fn(async (operation) => operation(tx)),
  };
  return { tx, dbPayment, service: new PaymentService(db, () => now) };
}

const hasError = (statusCode, code) => (error) => {
  assert.equal(error.statusCode, statusCode);
  assert.equal(error.code, code);
  return true;
};

test("getStatus expires an overdue pending payment owned by the user", async (t) => {
  const { tx, dbPayment, service } = fixture(t);

  assert.deepEqual(await service.getStatus("user-a", "payment-a"), {
    id: "payment-a",
    invoiceId: "invoice-a",
    provider: "SEPAY",
    paymentCode: "PAY20261025ABCDEF123456",
    amount: 285000,
    status: "EXPIRED",
    paidAt: null,
  });
  assert.deepEqual(dbPayment.findMany.mock.calls[0].arguments[0].where, {
    id: "payment-a",
    status: "PENDING",
    expiresAt: { lte: now },
    invoice: { userId: "user-a" },
  });
  assert.deepEqual(tx.payment.updateMany.mock.calls[0].arguments[0], {
    where: { id: "payment-a", status: "PENDING" },
    data: { status: "EXPIRED" },
  });
  assert.deepEqual(dbPayment.findFirst.mock.calls[0].arguments[0].where, {
    id: "payment-a",
    invoice: { userId: "user-a" },
  });
});

test("getStatus hides a payment owned by another user", async (t) => {
  const { dbPayment, service } = fixture(t);
  dbPayment.findMany.mock.mockImplementation(async () => []);
  dbPayment.findFirst.mock.mockImplementation(async () => null);

  await assert.rejects(
    service.getStatus("user-b", "payment-a"),
    hasError(404, "PAYMENT_NOT_FOUND")
  );
});
