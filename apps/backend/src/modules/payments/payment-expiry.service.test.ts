import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { expireOverduePayments } from "./payment-expiry.service";

const NOW = new Date("2026-10-30T10:00:00Z");

type PaymentState = {
  id: string;
  status: string;
  invoiceStatus: string;
  orderStatus: string;
};

/** Fake Prisma đủ cho expireOverduePayments và cancelOrderInTransaction. */
const createFakeDb = (payments: PaymentState[], brokenId?: string) => {
  const stockIncrements: string[] = [];
  const messages: string[] = [];
  const byId = (id: string) => payments.find((item) => item.id === id)!;

  const tx = {
    payment: {
      updateMany: async ({ where, data }: any) => {
        if (!where.id) return { count: 0 };
        if (where.id === brokenId) throw new Error("db lỗi");
        const payment = byId(where.id);
        if (payment.status !== where.status) return { count: 0 };
        payment.status = data.status;
        return { count: 1 };
      },
      findUnique: async ({ where }: any) => {
        const payment = byId(where.id);
        return {
          invoice: {
            status: payment.invoiceStatus,
            order: { id: payment.id, status: payment.orderStatus },
          },
        };
      },
    },
    order: {
      findUnique: async ({ where }: any) => {
        const payment = byId(where.id);
        return {
          id: payment.id,
          userId: "user-a",
          orderNumber: `ORD-${payment.id}`,
          status: payment.orderStatus,
          items: [{ productId: `product-${payment.id}`, quantity: 1 }],
          invoice: { id: `invoice-${payment.id}`, status: payment.invoiceStatus },
        };
      },
      updateMany: async ({ where, data }: any) => {
        const payment = byId(where.id);
        if (!where.status.in.includes(payment.orderStatus)) return { count: 0 };
        payment.orderStatus = data.status;
        return { count: 1 };
      },
    },
    product: {
      update: async ({ where }: any) => {
        stockIncrements.push(where.id);
        return {};
      },
    },
    voucherRedemption: { findMany: async () => [], updateMany: async () => ({ count: 0 }) },
    invoice: { updateMany: async () => ({ count: 1 }) },
    notification: {
      create: async ({ data }: any) => {
        messages.push(data.message);
        return {};
      },
    },
  };

  const db = {
    payment: {
      findMany: async ({ where }: any) =>
        payments
          .filter((item) => item.status === where.status)
          .filter((item) => !where.id || item.id === where.id)
          .map(({ id }) => ({ id })),
    },
    $transaction: async (work: any) => work(tx),
  } as any;

  return { db, stockIncrements, messages };
};

const pending = (id: string, orderStatus = "PENDING"): PaymentState => ({
  id,
  status: "PENDING",
  invoiceStatus: "ISSUED",
  orderStatus,
});

describe("expireOverduePayments", () => {
  it("đơn PENDING: payment EXPIRED, hủy đơn, hoàn kho, báo tự hủy", async () => {
    const payment = pending("a");
    const { db, stockIncrements, messages } = createFakeDb([payment]);

    await expireOverduePayments({}, db, () => NOW);

    assert.equal(payment.status, "EXPIRED");
    assert.equal(payment.orderStatus, "CANCELLED");
    assert.deepEqual(stockIncrements, ["product-a"]);
    assert.deepEqual(messages, ["Đơn hàng ORD-a đã tự hủy vì quá hạn thanh toán."]);
  });

  it("đơn PREPARING: chỉ đổi payment, không hoàn kho", async () => {
    const payment = pending("a", "PREPARING");
    const { db, stockIncrements } = createFakeDb([payment]);

    await expireOverduePayments({}, db, () => NOW);

    assert.equal(payment.status, "EXPIRED");
    assert.equal(payment.orderStatus, "PREPARING");
    assert.deepEqual(stockIncrements, []);
  });

  it("invoice đã PAID: không hủy đơn", async () => {
    const payment = { ...pending("a"), invoiceStatus: "PAID" };
    const { db } = createFakeDb([payment]);

    await expireOverduePayments({}, db, () => NOW);

    assert.equal(payment.orderStatus, "PENDING");
  });

  it("chạy lại không hoàn kho lần hai", async () => {
    const { db, stockIncrements } = createFakeDb([pending("a")]);

    await expireOverduePayments({}, db, () => NOW);
    await expireOverduePayments({}, db, () => NOW);

    assert.equal(stockIncrements.length, 1);
  });

  it("lỗi một payment không chặn payment khác", async () => {
    const broken = pending("a");
    const healthy = pending("b");
    const { db } = createFakeDb([broken, healthy], "a");

    await expireOverduePayments({}, db, () => NOW);

    assert.equal(broken.status, "PENDING");
    assert.equal(healthy.status, "EXPIRED");
    assert.equal(healthy.orderStatus, "CANCELLED");
  });
});
