import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { AppError } from "../../common/errors/app-error";
import { UserService } from "./user.service";

const ADMIN_ID = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
const OTHER_ADMIN_ID = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";
const USER_ID = "cccccccc-cccc-4ccc-8ccc-cccccccccccc";

const createFakeDb = (
  users: Record<string, { role: "USER" | "ADMIN"; status: "ACTIVE" | "DISABLED" }>
) => {
  const updates: any[] = [];
  const profile = {
    findUnique: async ({ where }: any) =>
      users[where.id] ? { id: where.id, ...users[where.id] } : null,
    count: async ({ where }: any) =>
      Object.values(users).filter(
        (u) => u.role === where.role && u.status === where.status
      ).length,
    update: async (args: any) => {
      updates.push(args);
      return { id: args.where.id, ...users[args.where.id], ...args.data };
    },
  };
  const db = { $transaction: async (work: any) => work({ profile }), profile } as any;
  return { db, updates };
};

const assertConflict = async (promise: Promise<unknown>) => {
  await assert.rejects(promise, (error: unknown) => {
    assert.ok(error instanceof AppError);
    assert.equal(error.statusCode, 409);
    assert.equal(error.code, "ADMIN_SELF_LOCK_FORBIDDEN");
    return true;
  });
};

describe("UserService.adminUpdate", () => {
  it("không cho admin tự khóa hoặc tự hạ quyền", async () => {
    const { db, updates } = createFakeDb({
      [ADMIN_ID]: { role: "ADMIN", status: "ACTIVE" },
      [OTHER_ADMIN_ID]: { role: "ADMIN", status: "ACTIVE" },
    });
    const service = new UserService(db);

    await assertConflict(service.adminUpdate(ADMIN_ID, ADMIN_ID, { status: "DISABLED" }));
    await assertConflict(service.adminUpdate(ADMIN_ID, ADMIN_ID, { role: "USER" }));
    assert.equal(updates.length, 0);
  });

  it("không cho khóa admin ACTIVE cuối cùng", async () => {
    const { db } = createFakeDb({
      [ADMIN_ID]: { role: "ADMIN", status: "DISABLED" },
      [OTHER_ADMIN_ID]: { role: "ADMIN", status: "ACTIVE" },
    });
    const service = new UserService(db);

    await assertConflict(
      service.adminUpdate(ADMIN_ID, OTHER_ADMIN_ID, { status: "DISABLED" })
    );
  });

  it("khóa user thường bình thường", async () => {
    const { db, updates } = createFakeDb({
      [ADMIN_ID]: { role: "ADMIN", status: "ACTIVE" },
      [USER_ID]: { role: "USER", status: "ACTIVE" },
    });
    const service = new UserService(db);

    const result = await service.adminUpdate(ADMIN_ID, USER_ID, { status: "DISABLED" });

    assert.equal(result.status, "DISABLED");
    assert.deepEqual(updates[0].data, { status: "DISABLED" });
  });

  it("trả 404 khi user không tồn tại", async () => {
    const { db } = createFakeDb({ [ADMIN_ID]: { role: "ADMIN", status: "ACTIVE" } });
    const service = new UserService(db);

    await assert.rejects(service.adminUpdate(ADMIN_ID, USER_ID, { role: "ADMIN" }), (error: unknown) => {
      assert.ok(error instanceof AppError);
      assert.equal(error.code, "USER_NOT_FOUND");
      return true;
    });
  });
});
