const assert = require("node:assert/strict");
const { test } = require("node:test");

let NotificationService;
let loadError;
try {
  ({ NotificationService } = require("../dist/modules/notifications/notification.service"));
} catch (error) {
  loadError = error;
}

const now = new Date("2026-10-21T08:00:00.000Z");
const firstCreatedAt = new Date("2026-10-20T08:00:00.000Z");
const secondCreatedAt = new Date("2026-10-19T08:00:00.000Z");

const notifications = [
  {
    id: "notification-a",
    type: "ORDER",
    title: "Đơn hàng đã xác nhận",
    message: "Đơn hàng #1001 đã được xác nhận.",
    isRead: false,
    createdAt: firstCreatedAt,
  },
  {
    id: "notification-b",
    type: "SYSTEM",
    title: "Chào mừng",
    message: "Chào mừng bạn đến với cửa hàng.",
    isRead: true,
    createdAt: secondCreatedAt,
  },
];

function fixture(t) {
  assert.ifError(loadError);
  const notification = {
    findMany: t.mock.fn(async () => notifications),
    count: t.mock.fn(async ({ where }) => (where.isRead === false ? 2 : 5)),
    updateMany: t.mock.fn(async () => ({ count: 1 })),
    findFirst: t.mock.fn(async () => null),
  };
  const db = {
    notification,
    $transaction: t.mock.fn(async (operations) => Promise.all(operations)),
  };
  return {
    db,
    notification,
    service: new NotificationService(db, () => now),
  };
}

const hasError = (statusCode, code) => (error) => {
  assert.equal(error.statusCode, statusCode);
  assert.equal(error.code, code);
  return true;
};

test("list returns one consistent snapshot with pagination and total unread count", async (t) => {
  const { db, service, notification } = fixture(t);

  assert.deepEqual(await service.list("user-a", { page: 2, unreadOnly: false }), {
    items: notifications,
    page: 2,
    total: 5,
    totalPages: 1,
    unreadCount: 2,
  });
  assert.deepEqual(notification.findMany.mock.calls[0].arguments[0], {
    where: { userId: "user-a" },
    orderBy: [{ createdAt: "desc" }, { id: "desc" }],
    skip: 20,
    take: 20,
    select: {
      id: true,
      type: true,
      title: true,
      message: true,
      isRead: true,
      createdAt: true,
    },
  });
  assert.deepEqual(db.$transaction.mock.calls[0].arguments[1], {
    isolationLevel: "RepeatableRead",
  });
});

test("list applies the unread filter without changing the unread meta count", async (t) => {
  const { service, notification } = fixture(t);

  await service.list("user-a", { page: 1, unreadOnly: true });

  assert.deepEqual(notification.findMany.mock.calls[0].arguments[0].where, {
    userId: "user-a",
    isRead: false,
  });
  assert.deepEqual(notification.count.mock.calls[0].arguments[0].where, {
    userId: "user-a",
    isRead: false,
  });
  assert.deepEqual(notification.count.mock.calls[1].arguments[0].where, {
    userId: "user-a",
    isRead: false,
  });
});

test("markRead updates only an unread notification owned by the user", async (t) => {
  const { service, notification } = fixture(t);

  assert.deepEqual(await service.markRead("user-a", "notification-a"), {
    id: "notification-a",
    isRead: true,
    readAt: now,
  });
  assert.deepEqual(notification.updateMany.mock.calls[0].arguments[0], {
    where: { id: "notification-a", userId: "user-a", isRead: false },
    data: { isRead: true, readAt: now },
  });
  assert.equal(notification.findFirst.mock.callCount(), 0);
});

test("markRead is idempotent for an already-read notification", async (t) => {
  const { service, notification } = fixture(t);
  const existingReadAt = new Date("2026-10-20T09:00:00.000Z");
  notification.updateMany.mock.mockImplementation(async () => ({ count: 0 }));
  notification.findFirst.mock.mockImplementation(async () => ({
    id: "notification-a",
    isRead: true,
    readAt: existingReadAt,
  }));

  assert.deepEqual(await service.markRead("user-a", "notification-a"), {
    id: "notification-a",
    isRead: true,
    readAt: existingReadAt,
  });
  assert.deepEqual(notification.findFirst.mock.calls[0].arguments[0], {
    where: { id: "notification-a", userId: "user-a" },
    select: { id: true, isRead: true, readAt: true },
  });
});

test("markRead hides notifications owned by another user", async (t) => {
  const { service, notification } = fixture(t);
  notification.updateMany.mock.mockImplementation(async () => ({ count: 0 }));

  await assert.rejects(
    service.markRead("user-b", "notification-a"),
    hasError(404, "NOTIFICATION_NOT_FOUND")
  );
});

test("markAllRead updates only unread notifications owned by the user", async (t) => {
  const { service, notification } = fixture(t);
  notification.updateMany.mock.mockImplementation(async () => ({ count: 3 }));

  assert.deepEqual(await service.markAllRead("user-a"), { updatedCount: 3 });
  assert.deepEqual(notification.updateMany.mock.calls[0].arguments[0], {
    where: { userId: "user-a", isRead: false },
    data: { isRead: true, readAt: now },
  });
});
