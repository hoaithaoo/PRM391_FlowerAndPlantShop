import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { OrderStatus, PaymentStatus, Prisma } from "@prisma/client";
import { expireOverduePayments } from "../payments/payment-expiry.service";
import { cancelOrderInTransaction } from "./order-state";

describe("cancelOrderInTransaction voucher release", () => {
  const orderId = "order-123";
  const voucherId = "voucher-abc";
  const now = new Date("2026-11-02T10:00:00Z");

  it("releases voucher redemption and decrements usedCount exactly once", async () => {
    let unreleased = [{ voucherId }];
    let decrementCount = 0;

    const tx = {
      order: {
        findUnique: async () => ({
          id: orderId,
          userId: "user-1",
          orderNumber: "ORD-001",
          status: OrderStatus.PENDING,
          items: [],
          invoice: null,
        }),
        updateMany: async () => ({ count: 1 }),
      },
      product: { update: async () => ({}) },
      voucherRedemption: {
        updateMany: async (args: any) => {
          assert.equal(args.where.releasedAt, null);
          return { count: unreleased.length };
        },
        findMany: async () => unreleased,
      },
      voucher: {
        updateMany: async (args: any) => {
          assert.deepEqual(args.where.id, { in: [voucherId] });
          assert.deepEqual(args.data, { usedCount: { decrement: 1 } });
          decrementCount += 1;
          return { count: 1 };
        },
      },
      invoice: { updateMany: async () => ({ count: 1 }) },
      payment: { updateMany: async () => ({ count: 1 }) },
      notification: { create: async () => ({}) },
    } as any;

    await cancelOrderInTransaction(tx, orderId, {
      cancelledAt: now,
      byAdmin: false,
    });

    assert.equal(decrementCount, 1);

    // If released count is 0 (already released), voucher decrement is not called again
    unreleased = [];
    decrementCount = 0;
    // reset order mock for another call
    await cancelOrderInTransaction(tx, orderId, {
      cancelledAt: now,
      byAdmin: false,
    });
    assert.equal(decrementCount, 0);
  });
});

describe("expireOverduePayments", () => {
  const now = new Date("2026-11-02T10:00:00Z");

  it("expires overdue pending payments and cancels order in PENDING status", async () => {
    let orderCancelled = false;

    const fakeDb = {
      payment: {
        findMany: async () => [{ id: "pay-1" }],
      },
      $transaction: async (work: any) => {
        const tx = {
          payment: {
            updateMany: async () => ({ count: 1 }),
            findUnique: async () => ({
              invoice: {
                status: "ISSUED",
                order: { id: "ord-1", status: OrderStatus.PENDING },
              },
            }),
          },
          order: {
            findUnique: async () => ({
              id: "ord-1",
              userId: "user-1",
              orderNumber: "ORD-001",
              status: OrderStatus.PENDING,
              items: [],
              invoice: null,
            }),
            updateMany: async () => {
              orderCancelled = true;
              return { count: 1 };
            },
          },
          product: { update: async () => ({}) },
          voucherRedemption: {
            updateMany: async () => ({ count: 0 }),
          },
          notification: { create: async () => ({}) },
        };
        return work(tx);
      },
    } as any;

    await expireOverduePayments({}, fakeDb, () => now);
    assert.equal(orderCancelled, true);
  });

  it("does not cancel order if order status is PREPARING (only expires payment)", async () => {
    let orderCancelled = false;

    const fakeDb = {
      payment: {
        findMany: async () => [{ id: "pay-2" }],
      },
      $transaction: async (work: any) => {
        const tx = {
          payment: {
            updateMany: async () => ({ count: 1 }),
            findUnique: async () => ({
              invoice: {
                status: "ISSUED",
                order: { id: "ord-2", status: OrderStatus.PREPARING },
              },
            }),
          },
          order: {
            updateMany: async () => {
              orderCancelled = true;
              return { count: 1 };
            },
          },
        };
        return work(tx);
      },
    } as any;

    await expireOverduePayments({}, fakeDb, () => now);
    assert.equal(orderCancelled, false);
  });

  it("error on one payment does not block subsequent overdue payments", async () => {
    const executed: string[] = [];

    const fakeDb = {
      payment: {
        findMany: async () => [{ id: "pay-fail" }, { id: "pay-success" }],
      },
      $transaction: async (work: any) => {
        const tx = {
          payment: {
            updateMany: async (args: any) => {
              if (args.where.id === "pay-fail") throw new Error("DB Error");
              executed.push(args.where.id);
              return { count: 1 };
            },
            findUnique: async () => null,
          },
        };
        return work(tx);
      },
    } as any;

    await expireOverduePayments({}, fakeDb, () => now);
    assert.deepEqual(executed, ["pay-success"]);
  });
});

