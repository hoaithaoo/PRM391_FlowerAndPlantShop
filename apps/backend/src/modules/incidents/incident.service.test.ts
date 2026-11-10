import assert from "node:assert/strict";
import { describe, test } from "node:test";
import type { PrismaClient } from "@prisma/client";
import { AppError } from "../../common/errors/app-error";
import { IncidentService } from "./incident.service";

const USER_ID = "11111111-1111-4111-8111-111111111111";
const ORDER_ID = "22222222-2222-4222-8222-222222222222";
const INCIDENT_ID = "33333333-3333-4333-8333-333333333333";

function fakeDb(state: { orderOwned?: boolean; status?: string }) {
  const notifications: unknown[] = [];
  const created: unknown[] = [];
  const db = {
    order: { findFirst: async () => (state.orderOwned ? { id: ORDER_ID } : null) },
    notification: { create: async (args: unknown) => notifications.push(args) },
    incidentReport: {
      create: async (args: { data: unknown }) => {
        created.push(args.data);
        return args.data;
      },
      findUnique: async () => (state.status ? { status: state.status } : null),
      update: async (args: { data: { status: string; adminNote?: string | null } }) => ({
        id: INCIDENT_ID,
        code: "SC-1",
        adminNote: args.data.adminNote ?? null,
        user: { id: USER_ID },
      }),
    },
  } as Record<string, unknown>;
  db.$transaction = async (fn: (tx: unknown) => unknown) => fn(db);
  return { db: db as unknown as PrismaClient, notifications, created };
}

describe("IncidentService", () => {
  test("rejects an order that does not belong to the user", async () => {
    const { db, created } = fakeDb({ orderOwned: false });
    await assert.rejects(
      new IncidentService(db).create(USER_ID, {
        category: "DELIVERY",
        title: "Chưa nhận",
        description: "Đã 3 ngày chưa nhận được hàng.",
        orderId: ORDER_ID,
      }),
      (error: unknown) => error instanceof AppError && error.statusCode === 404
    );
    assert.equal(created.length, 0);
  });

  test("notifies the customer only when the status changes", async () => {
    const same = fakeDb({ status: "IN_PROGRESS" });
    await new IncidentService(same.db).adminUpdate(INCIDENT_ID, { status: "IN_PROGRESS", adminNote: "Đang kiểm tra" });
    assert.equal(same.notifications.length, 0);

    const changed = fakeDb({ status: "OPEN" });
    await new IncidentService(changed.db).adminUpdate(INCIDENT_ID, { status: "RESOLVED", adminNote: "Đã gửi bù hoa" });
    assert.equal(changed.notifications.length, 1);
    assert.match(JSON.stringify(changed.notifications[0]), /SC-1 đã được giải quyết\. Đã gửi bù hoa/u);
  });

  test("returns 404 for a missing incident", async () => {
    const { db } = fakeDb({});
    await assert.rejects(new IncidentService(db).adminUpdate(INCIDENT_ID, { status: "OPEN" }), AppError);
  });
});
