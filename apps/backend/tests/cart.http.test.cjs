const assert = require("node:assert/strict");
const { once } = require("node:events");
const { before, after, beforeEach, test } = require("node:test");

// Explicit test configuration; no real database or Supabase requests are made.
process.env.NODE_ENV = "test";
process.env.DATABASE_URL = "postgresql://test:test@127.0.0.1:1/cart_test";
process.env.SUPABASE_URL = "https://example.supabase.co";
process.env.SUPABASE_PUBLISHABLE_KEY = "test-publishable-key";

// Prisma delegates are proxies, which node:test cannot reliably mock directly.
// Supply a plain client before the singleton is loaded; accidental real DB calls
// are impossible in this HTTP suite.
global.prisma = {
  profile: { async findUnique() { return null; } },
  async $disconnect() {},
};

const { createApp } = require("../dist/app");
const { prisma } = require("../dist/lib/prisma");
const { supabase } = require("../dist/lib/supabase");
const { cartService } = require("../dist/modules/carts/cart.service");

const userId = "11111111-1111-4111-8111-111111111111";
const productId = "22222222-2222-4222-8222-222222222222";
const itemId = "33333333-3333-4333-8333-333333333333";
const emptyCart = { id: "cart-a", items: [], totalQuantity: 0, subtotal: 0 };
let server;
let baseUrl;

before(async () => {
  server = createApp().listen(0, "127.0.0.1");
  await once(server, "listening");
  baseUrl = `http://127.0.0.1:${server.address().port}/api/v1/cart`;
});

after(async () => {
  if (server) await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  await prisma.$disconnect();
});

beforeEach((t) => {
  t.mock.method(supabase.auth, "getUser", async (token) => token === "valid-token"
    ? { data: { user: { id: userId, email: "test@example.com", user_metadata: {} } }, error: null }
    : { data: { user: null }, error: { status: 401, name: "AuthApiError" } });
  t.mock.method(prisma.profile, "findUnique", async () => ({ id: userId, role: "USER", status: "ACTIVE" }));
  t.mock.method(cartService, "getCart", async () => emptyCart);
  t.mock.method(cartService, "addItemToCart", async (_userId, input) => ({
    id: itemId, productId: input.productId, quantity: input.quantity, subtotal: 250000,
  }));
  t.mock.method(cartService, "updateCartItem", async (_userId, id, input) => ({
    id, quantity: input.quantity, subtotal: 125000,
  }));
  t.mock.method(cartService, "removeCartItem", async () => undefined);
});

async function request(path = "", { method = "GET", body, token = "valid-token" } = {}) {
  return fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      ...(token !== null && { Authorization: `Bearer ${token}` }),
      ...(body !== undefined && { "Content-Type": "application/json" }),
    },
    ...(body !== undefined && { body: JSON.stringify(body) }),
  });
}

test("all cart endpoints require a token", async () => {
  for (const [method, path] of [["GET", ""], ["POST", "/items"], ["PUT", `/items/${itemId}`], ["DELETE", `/items/${itemId}`]]) {
    const response = await request(path, { method, token: null });
    assert.equal(response.status, 401);
    assert.equal((await response.json()).error.code, "AUTH_TOKEN_MISSING");
  }
  assert.equal(cartService.getCart.mock.callCount(), 0);
});

test("invalid tokens and disabled accounts cannot read carts", async (t) => {
  const invalid = await request("", { token: "invalid-token" });
  assert.equal(invalid.status, 401);
  assert.equal((await invalid.json()).error.code, "AUTH_TOKEN_INVALID");
  prisma.profile.findUnique.mock.mockImplementation(async () => ({ id: userId, role: "USER", status: "DISABLED" }));
  const disabled = await request();
  assert.equal(disabled.status, 403);
  assert.equal((await disabled.json()).error.code, "ACCOUNT_DISABLED");
  assert.equal(cartService.getCart.mock.callCount(), 0);
});

test("GET uses the verified user ID and returns the standard response envelope", async () => {
  const response = await request("?userId=another-user");
  assert.equal(response.status, 200);
  const body = await response.json();
  assert.equal(body.success, true);
  assert.deepEqual(body.data, emptyCart);
  assert.ok(body.meta.requestId);
  assert.ok(body.meta.timestamp);
  assert.deepEqual(cartService.getCart.mock.calls[0].arguments, [userId]);
});

test("POST validates input and returns 201 with the verified owner", async () => {
  const response = await request("/items", { method: "POST", body: { productId, quantity: 2 } });
  assert.equal(response.status, 201);
  assert.equal((await response.json()).data.quantity, 2);
  assert.deepEqual(cartService.addItemToCart.mock.calls[0].arguments, [userId, { productId, quantity: 2 }]);
});

test("invalid quantities, UUIDs, and injected owner/price fields return 422", async () => {
  const invalidBodies = [
    {}, { productId }, { productId: "invalid", quantity: 1 },
    ...[0, -1, 1.5, "2", null, 2147483648].map((quantity) => ({ productId, quantity })),
    { productId, quantity: 1, userId: "another-user" },
    { productId, quantity: 1, price: 1 },
  ];
  for (const body of invalidBodies) {
    const response = await request("/items", { method: "POST", body });
    assert.equal(response.status, 422, JSON.stringify(body));
    assert.equal((await response.json()).error.code, "VALIDATION_ERROR");
  }
  assert.equal(cartService.addItemToCart.mock.callCount(), 0);
});

test("PUT validates the item ID and replaces quantity", async () => {
  const invalidId = await request("/items/not-a-uuid", { method: "PUT", body: { quantity: 1 } });
  assert.equal(invalidId.status, 422);
  await invalidId.json();
  const invalidQuantity = await request(`/items/${itemId}`, { method: "PUT", body: { quantity: 0 } });
  assert.equal(invalidQuantity.status, 422);
  await invalidQuantity.json();
  const response = await request(`/items/${itemId}`, { method: "PUT", body: { quantity: 1 } });
  assert.equal(response.status, 200);
  assert.equal((await response.json()).data.quantity, 1);
  assert.deepEqual(cartService.updateCartItem.mock.calls[0].arguments, [userId, itemId, { quantity: 1 }]);
});

test("DELETE validates the item ID and returns an empty 204 response", async () => {
  const invalid = await request("/items/not-a-uuid", { method: "DELETE" });
  assert.equal(invalid.status, 422);
  await invalid.json();
  const response = await request(`/items/${itemId}`, { method: "DELETE" });
  assert.equal(response.status, 204);
  assert.equal(await response.text(), "");
  assert.deepEqual(cartService.removeCartItem.mock.calls[0].arguments, [userId, itemId]);
});

test("business errors reach the centralized error response", async () => {
  const { AppError } = require("../dist/common/errors/app-error");
  cartService.addItemToCart.mock.mockImplementation(async () => {
    throw new AppError(409, "PRODUCT_OUT_OF_STOCK", "Không đủ tồn kho.");
  });
  const response = await request("/items", { method: "POST", body: { productId, quantity: 2 } });
  assert.equal(response.status, 409);
  assert.equal((await response.json()).error.code, "PRODUCT_OUT_OF_STOCK");
});
