const assert = require("node:assert/strict");
const { once } = require("node:events");
const { before, after, beforeEach, test } = require("node:test");

process.env.NODE_ENV = "test";
process.env.DATABASE_URL = "postgresql://test:test@127.0.0.1:1/notification_test";
process.env.SUPABASE_URL = "https://example.supabase.co";
process.env.SUPABASE_PUBLISHABLE_KEY = "test-publishable-key";

global.prisma = {
  profile: { async findUnique() { return null; } },
  async $disconnect() {},
};

const { createApp } = require("../dist/app");
const { prisma } = require("../dist/lib/prisma");
const { supabase } = require("../dist/lib/supabase");
const { notificationService } = require("../dist/modules/notifications/notification.service");

const userId = "11111111-1111-4111-8111-111111111111";
const notificationId = "33333333-3333-4333-8333-333333333333";
const createdAt = new Date("2026-10-20T08:00:00.000Z");
const readAt = new Date("2026-10-21T08:00:00.000Z");
const listResult = {
  items: [{
    id: notificationId,
    type: "ORDER",
    title: "Đơn hàng đã xác nhận",
    message: "Đơn hàng #1001 đã được xác nhận.",
    isRead: false,
    createdAt,
  }],
  page: 2,
  total: 21,
  totalPages: 2,
  unreadCount: 3,
};

let server;
let baseUrl;

before(async () => {
  server = createApp().listen(0, "127.0.0.1");
  await once(server, "listening");
  baseUrl = `http://127.0.0.1:${server.address().port}/api/v1/notifications`;
});

after(async () => {
  if (server) {
    await new Promise((resolve, reject) =>
      server.close((error) => (error ? reject(error) : resolve()))
    );
  }
  await prisma.$disconnect();
});

beforeEach((t) => {
  t.mock.method(supabase.auth, "getUser", async (token) => token === "valid-token"
    ? { data: { user: { id: userId, email: "test@example.com", user_metadata: {} } }, error: null }
    : { data: { user: null }, error: { status: 401, name: "AuthApiError" } });
  t.mock.method(prisma.profile, "findUnique", async () => ({
    id: userId,
    role: "USER",
    status: "ACTIVE",
  }));
  t.mock.method(notificationService, "list", async () => listResult);
  t.mock.method(notificationService, "markRead", async (_userId, id) => ({
    id,
    isRead: true,
    readAt,
  }));
  t.mock.method(notificationService, "markAllRead", async () => ({ updatedCount: 4 }));
});

async function request(path = "", { method = "GET", token = "valid-token" } = {}) {
  return fetch(`${baseUrl}${path}`, {
    method,
    headers: token === null ? {} : { Authorization: `Bearer ${token}` },
  });
}

test("all notification endpoints require a token", async () => {
  for (const [method, path] of [
    ["GET", ""],
    ["PATCH", `/${notificationId}/read`],
    ["PATCH", "/read-all"],
  ]) {
    const response = await request(path, { method, token: null });
    assert.equal(response.status, 401);
    assert.equal((await response.json()).error.code, "AUTH_TOKEN_MISSING");
  }
  assert.equal(notificationService.list.mock.callCount(), 0);
  assert.equal(notificationService.markRead.mock.callCount(), 0);
  assert.equal(notificationService.markAllRead.mock.callCount(), 0);
});

test("invalid tokens and disabled accounts cannot list notifications", async (t) => {
  const invalid = await request("", { token: "invalid-token" });
  assert.equal(invalid.status, 401);
  assert.equal((await invalid.json()).error.code, "AUTH_TOKEN_INVALID");

  prisma.profile.findUnique.mock.mockImplementation(async () => ({
    id: userId,
    role: "USER",
    status: "DISABLED",
  }));
  const disabled = await request();
  assert.equal(disabled.status, 403);
  assert.equal((await disabled.json()).error.code, "ACCOUNT_DISABLED");
  assert.equal(notificationService.list.mock.callCount(), 0);
});

test("GET validates filters and returns the standard pagination envelope", async () => {
  const response = await request("?page=2&unreadOnly=true");
  assert.equal(response.status, 200);
  const body = await response.json();
  assert.deepEqual(body.data, {
    items: [{ ...listResult.items[0], createdAt: createdAt.toISOString() }],
  });
  assert.equal(body.meta.page, 2);
  assert.equal(body.meta.total, 21);
  assert.equal(body.meta.totalPages, 2);
  assert.equal(body.meta.unreadCount, 3);
  assert.ok(body.meta.requestId);
  assert.ok(body.meta.timestamp);
  assert.deepEqual(notificationService.list.mock.calls[0].arguments, [
    userId,
    { page: 2, unreadOnly: true },
  ]);
});

test("GET rejects malformed or injected query fields", async () => {
  for (const query of [
    "?page=0",
    "?page=1.5",
    "?unreadOnly=1",
    "?userId=another-user",
  ]) {
    const response = await request(query);
    assert.equal(response.status, 400, query);
    assert.equal((await response.json()).error.code, "BAD_REQUEST");
  }
  assert.equal(notificationService.list.mock.callCount(), 0);
});

test("PATCH /:id/read validates the ID and uses the authenticated owner", async () => {
  const invalid = await request("/not-a-uuid/read", { method: "PATCH" });
  assert.equal(invalid.status, 422);
  assert.equal((await invalid.json()).error.code, "VALIDATION_ERROR");

  const response = await request(`/${notificationId}/read`, { method: "PATCH" });
  assert.equal(response.status, 200);
  assert.deepEqual((await response.json()).data, {
    id: notificationId,
    isRead: true,
    readAt: readAt.toISOString(),
  });
  assert.deepEqual(notificationService.markRead.mock.calls[0].arguments, [
    userId,
    notificationId,
  ]);
});

test("PATCH /read-all uses the authenticated owner and returns the update count", async () => {
  const response = await request("/read-all", { method: "PATCH" });
  assert.equal(response.status, 200);
  assert.deepEqual((await response.json()).data, { updatedCount: 4 });
  assert.deepEqual(notificationService.markAllRead.mock.calls[0].arguments, [userId]);
});

test("notification business errors reach the centralized error response", async (t) => {
  const { AppError } = require("../dist/common/errors/app-error");
  notificationService.markRead.mock.mockImplementation(async () => {
    throw new AppError(404, "NOTIFICATION_NOT_FOUND", "Không tìm thấy thông báo này.");
  });

  const response = await request(`/${notificationId}/read`, { method: "PATCH" });
  assert.equal(response.status, 404);
  assert.equal((await response.json()).error.code, "NOTIFICATION_NOT_FOUND");
});
