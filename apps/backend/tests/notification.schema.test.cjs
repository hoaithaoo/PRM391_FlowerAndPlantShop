const assert = require("node:assert/strict");
const { test } = require("node:test");

let notificationSchemas;
let loadError;
try {
  notificationSchemas = require("../dist/modules/notifications/notification.schema");
} catch (error) {
  loadError = error;
}

test("notification list query defaults to the first page and includes read items", () => {
  assert.ifError(loadError);
  assert.deepEqual(notificationSchemas.listNotificationsQuerySchema.parse({}), {
    page: 1,
    unreadOnly: false,
  });
});

test("notification list query coerces supported HTTP query values", () => {
  assert.ifError(loadError);
  assert.deepEqual(
    notificationSchemas.listNotificationsQuerySchema.parse({
      page: "2",
      unreadOnly: "true",
    }),
    { page: 2, unreadOnly: true }
  );
});

test("notification list query rejects invalid pagination and unknown fields", () => {
  assert.ifError(loadError);
  for (const query of [
    { page: "0" },
    { page: "1.5" },
    { page: "1e100" },
    { unreadOnly: "1" },
    { limit: "500" },
  ]) {
    assert.equal(
      notificationSchemas.listNotificationsQuerySchema.safeParse(query).success,
      false,
      JSON.stringify(query)
    );
  }
});

test("notification ID params require a UUID", () => {
  assert.ifError(loadError);
  const validId = "33333333-3333-4333-8333-333333333333";
  assert.deepEqual(notificationSchemas.notificationIdParamsSchema.parse({ id: validId }), {
    id: validId,
  });
  assert.equal(
    notificationSchemas.notificationIdParamsSchema.safeParse({ id: "not-a-uuid" }).success,
    false
  );
});
