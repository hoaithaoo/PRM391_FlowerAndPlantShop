const assert = require("node:assert/strict");
const { test } = require("node:test");
const { notificationService } = require("../dist/modules/notifications/notification.service");

let NotificationController;
let loadError;
try {
  ({ NotificationController } = require("../dist/modules/notifications/notification.controller"));
} catch (error) {
  loadError = error;
}

function fixture() {
  assert.ifError(loadError);
  const req = {
    auth: { userId: "user-a" },
    params: { id: "33333333-3333-4333-8333-333333333333" },
    query: { page: 2, unreadOnly: true },
    requestId: "request-a",
  };
  const res = {
    statusCode: 200,
    status(code) { this.statusCode = code; return this; },
    json(body) { this.body = body; return this; },
  };
  return { req, res, controller: new NotificationController() };
}

test("list returns notification items and pagination metadata", async (t) => {
  const { req, res, controller } = fixture();
  const result = {
    items: [{ id: "notification-a" }],
    page: 2,
    total: 21,
    totalPages: 2,
    unreadCount: 3,
  };
  const serviceMock = t.mock.method(notificationService, "list", async () => result);

  await controller.list(req, res, (error) => { throw error; });

  assert.deepEqual(serviceMock.mock.calls[0].arguments, [
    "user-a",
    { page: 2, unreadOnly: true },
  ]);
  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.body.data, { items: result.items });
  assert.equal(res.body.meta.page, 2);
  assert.equal(res.body.meta.total, 21);
  assert.equal(res.body.meta.totalPages, 2);
  assert.equal(res.body.meta.unreadCount, 3);
  assert.equal(res.body.meta.requestId, "request-a");
});

test("markRead returns the updated read state", async (t) => {
  const { req, res, controller } = fixture();
  const result = {
    id: req.params.id,
    isRead: true,
    readAt: new Date("2026-10-21T08:00:00.000Z"),
  };
  const serviceMock = t.mock.method(notificationService, "markRead", async () => result);

  await controller.markRead(req, res, (error) => { throw error; });

  assert.deepEqual(serviceMock.mock.calls[0].arguments, ["user-a", req.params.id]);
  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.body.data, result);
});

test("markAllRead returns the number of updated notifications", async (t) => {
  const { req, res, controller } = fixture();
  const result = { updatedCount: 4 };
  const serviceMock = t.mock.method(notificationService, "markAllRead", async () => result);

  await controller.markAllRead(req, res, (error) => { throw error; });

  assert.deepEqual(serviceMock.mock.calls[0].arguments, ["user-a"]);
  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.body.data, result);
});

for (const method of ["list", "markRead", "markAllRead"]) {
  test(`${method} rejects missing identity before calling the service`, async (t) => {
    const { req, res, controller } = fixture();
    delete req.auth;
    const serviceMock = t.mock.method(notificationService, method, async () => undefined);
    let received;

    await controller[method](req, res, (error) => { received = error; });

    assert.equal(received.statusCode, 401);
    assert.equal(received.code, "AUTH_TOKEN_MISSING");
    assert.equal(serviceMock.mock.callCount(), 0);
    assert.equal(res.body, undefined);
  });

  test(`${method} forwards service errors without sending success`, async (t) => {
    const { req, res, controller } = fixture();
    const failure = new Error("Service failed");
    t.mock.method(notificationService, method, async () => { throw failure; });
    let received;

    await controller[method](req, res, (error) => { received = error; });

    assert.equal(received, failure);
    assert.equal(res.body, undefined);
  });
}
