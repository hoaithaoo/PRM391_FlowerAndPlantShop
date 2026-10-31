import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { AppError } from "../../common/errors/app-error";
import { derivePaymentStatus } from "./order-state";
import { OrderService } from "./order.service";

const USER_ID = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
const ORDER_ID = "11111111-1111-4111-8111-111111111111";
const INVOICE_ID = "22222222-2222-4222-8222-222222222222";
const PRODUCT_A = "33333333-3333-4333-8333-333333333333";
const PRODUCT_B = "44444444-4444-4444-8444-444444444444";
const NOW = new Date("2026-10-30T10:00:00Z");

type OrderState = {
  status: string;
  paymentMethod: "SEPAY" | "COD";
  invoiceStatus: "ISSUED" | "PAID" | "CANCELLED";
};

/** Fake Prisma đủ cho các nhánh ghi của OrderService; ghi lại mọi lệnh ghi. */
const createFakeDb = (state: OrderState) => {
  const writes: Array<{ op: string; args: any }> = [];
  const order = {
    id: ORDER_ID,
    userId: USER_ID,
    orderNumber: "ORD-20261030-ABC",
    get status() {
      return state.status;
    },
    paymentMethod: state.paymentMethod,
    items: [
      { productId: PRODUCT_B, quantity: 1 },
      { productId: PRODUCT_A, quantity: 2 },
    ],
    get invoice() {
      return { id: INVOICE_ID, status: state.invoiceStatus };
    },
  };

  const tx = {
    order: {
      findFirst: async ({ where }: any) =>
        where.id === ORDER_ID && where.userId === USER_ID ? { id: ORDER_ID } : null,
      findUnique: async ({ where }: any) => (where.id === ORDER_ID ? order : null),
      updateMany: async (args: any) => {
        writes.push({ op: "order.updateMany", args });
        const allowed: string[] = args.where.status?.in ?? [args.where.status];
        if (!allowed.includes(state.status)) return { count: 0 };
        state.status = args.data.status;
        return { count: 1 };
      },
    },
    product: {
      update: async (args: any) => {
        writes.push({ op: "product.update", args });
        return {};
      },
    },
    invoice: {
      updateMany: async (args: any) => {
        writes.push({ op: "invoice.updateMany", args });
        if (args.where.status !== state.invoiceStatus) return { count: 0 };
        state.invoiceStatus = args.data.status;
        return { count: 1 };
      },
    },
    payment: {
      updateMany: async (args: any) => {
        writes.push({ op: "payment.updateMany", args });
        return { count: 1 };
      },
    },
    notification: {
      create: async (args: any) => {
        writes.push({ op: "notification.create", args });
        return {};
      },
    },
  };

  const db = {
    $transaction: async (work: any) => work(tx),
    order: tx.order,
  } as any;

  return { db, writes, state };
};

const assertAppError = async (promise: Promise<unknown>, status: number, code: string) => {
  await assert.rejects(promise, (error: unknown) => {
    assert.ok(error instanceof AppError);
    assert.equal(error.statusCode, status);
    assert.equal(error.code, code);
    return true;
  });
};

describe("OrderService.cancelMine", () => {
  it("hủy đơn PENDING: hoàn kho theo thứ tự productId, hủy invoice, FAILED payment chờ", async () => {
    const { db, writes, state } = createFakeDb({
      status: "PENDING",
      paymentMethod: "SEPAY",
      invoiceStatus: "ISSUED",
    });
    const service = new OrderService(db, () => NOW);

    const result = await service.cancelMine(USER_ID, ORDER_ID, { reason: "Đổi ý" });

    assert.deepEqual(result, { id: ORDER_ID, status: "CANCELLED", cancelledAt: NOW });
    assert.equal(state.status, "CANCELLED");
    assert.equal(state.invoiceStatus, "CANCELLED");
    const restocks = writes.filter((w) => w.op === "product.update");
    assert.deepEqual(
      restocks.map((w) => [w.args.where.id, w.args.data.stock.increment]),
      [
        [PRODUCT_A, 2],
        [PRODUCT_B, 1],
      ]
    );
    const payment = writes.find((w) => w.op === "payment.updateMany");
    assert.deepEqual(payment?.args.data, { status: "FAILED" });
    assert.ok(writes.some((w) => w.op === "notification.create"));
  });

  it("không cho hủy đơn đang SHIPPING và không hoàn kho", async () => {
    const { db, writes } = createFakeDb({
      status: "SHIPPING",
      paymentMethod: "COD",
      invoiceStatus: "ISSUED",
    });
    const service = new OrderService(db, () => NOW);

    await assertAppError(service.cancelMine(USER_ID, ORDER_ID, {}), 409, "ORDER_CANNOT_CANCEL");
    assert.equal(writes.filter((w) => w.op === "product.update").length, 0);
  });

  it("không cho hủy đơn đã thanh toán", async () => {
    const { db } = createFakeDb({
      status: "CONFIRMED",
      paymentMethod: "SEPAY",
      invoiceStatus: "PAID",
    });
    const service = new OrderService(db, () => NOW);

    await assertAppError(service.cancelMine(USER_ID, ORDER_ID, {}), 409, "ORDER_CANNOT_CANCEL");
  });

  it("trả 404 khi đơn không thuộc user", async () => {
    const { db } = createFakeDb({
      status: "PENDING",
      paymentMethod: "COD",
      invoiceStatus: "ISSUED",
    });
    const service = new OrderService(db, () => NOW);
    const otherUser = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";

    await assertAppError(service.cancelMine(otherUser, ORDER_ID, {}), 404, "ORDER_NOT_FOUND");
  });
});

describe("OrderService.adminUpdateStatus", () => {
  it("từ chối transition nhảy cóc PENDING → SHIPPING", async () => {
    const { db } = createFakeDb({
      status: "PENDING",
      paymentMethod: "COD",
      invoiceStatus: "ISSUED",
    });
    const service = new OrderService(db, () => NOW);

    await assertAppError(
      service.adminUpdateStatus(ORDER_ID, { status: "SHIPPING" }),
      409,
      "INVALID_ORDER_STATE_TRANSITION"
    );
  });

  it("không cho xử lý tiếp đơn SePay chưa thanh toán", async () => {
    const { db, state } = createFakeDb({
      status: "PENDING",
      paymentMethod: "SEPAY",
      invoiceStatus: "ISSUED",
    });
    const service = new OrderService(db, () => NOW);

    await assertAppError(
      service.adminUpdateStatus(ORDER_ID, { status: "CONFIRMED" }),
      409,
      "INVALID_ORDER_STATE_TRANSITION"
    );
    assert.equal(state.status, "PENDING");
  });

  it("COD giao xong (SHIPPING → COMPLETED) thì invoice chuyển PAID", async () => {
    const { db, writes, state } = createFakeDb({
      status: "SHIPPING",
      paymentMethod: "COD",
      invoiceStatus: "ISSUED",
    });
    const service = new OrderService(db, () => NOW);
    // adminGet sau khi cập nhật đọc lại order; trả lỗi có chủ đích để chỉ kiểm tra phần ghi.
    db.order.findUnique = async ({ select }: any) => {
      if (select?.items?.select?.product) throw new Error("READ_BACK");
      return {
        id: ORDER_ID,
        userId: USER_ID,
        orderNumber: "ORD-1",
        status: state.status,
        paymentMethod: "COD",
        invoice: { id: INVOICE_ID, status: state.invoiceStatus },
      };
    };

    await assert.rejects(service.adminUpdateStatus(ORDER_ID, { status: "COMPLETED" }), /READ_BACK/);
    assert.equal(state.status, "COMPLETED");
    assert.equal(state.invoiceStatus, "PAID");
    const orderWrite = writes.find((w) => w.op === "order.updateMany");
    assert.deepEqual(orderWrite?.args.data, { status: "COMPLETED", completedAt: NOW });
  });
});

describe("derivePaymentStatus", () => {
  const invoice = (status: "ISSUED" | "PAID" | "CANCELLED", payments: any[] = []) => ({
    status,
    payments,
  });

  it("COD chưa giao là PENDING, invoice PAID là PAID, invoice hủy là FAILED", () => {
    assert.equal(derivePaymentStatus({ paymentMethod: "COD", invoice: invoice("ISSUED") }), "PENDING");
    assert.equal(derivePaymentStatus({ paymentMethod: "COD", invoice: invoice("PAID") }), "PAID");
    assert.equal(derivePaymentStatus({ paymentMethod: "COD", invoice: invoice("CANCELLED") }), "FAILED");
  });

  it("SePay lấy theo payment mới nhất", () => {
    assert.equal(
      derivePaymentStatus({
        paymentMethod: "SEPAY",
        invoice: invoice("ISSUED", [{ status: "EXPIRED" }]),
      }),
      "EXPIRED"
    );
  });
});
