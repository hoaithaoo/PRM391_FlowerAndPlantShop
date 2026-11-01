const assert = require("node:assert/strict");
const { test } = require("node:test");
const { CartController } = require("../dist/modules/carts/cart.controller");
const { cartService } = require("../dist/modules/carts/cart.service");

const cases = [
  { method: "getCart", status: 200, args: ["user-a"] },
  { method: "addItemToCart", status: 201, args: ["user-a", { quantity: 2 }] },
  { method: "updateCartItem", status: 200, args: ["user-a", "item-a", { quantity: 2 }] },
  { method: "removeCartItem", status: 204, args: ["user-a", "item-a"] },
];

function fixture() {
  const req = {
    auth: { userId: "user-a" },
    params: { id: "item-a" },
    body: { quantity: 2 },
    query: { userId: "user-b" },
    requestId: "request-a",
  };
  const res = {
    statusCode: 200,
    status(code) { this.statusCode = code; return this; },
    json(body) { this.body = body; return this; },
    send() { this.sent = true; return this; },
  };
  return { req, res, controller: new CartController() };
}

for (const { method, status, args } of cases) {
  test(`${method} passes authenticated identity and returns HTTP ${status}`, async (t) => {
    const { req, res, controller } = fixture();
    const result = { id: "result-a" };
    const serviceMock = t.mock.method(cartService, method, async () => result);
    await controller[method](req, res, (error) => { throw error; });
    assert.deepEqual(serviceMock.mock.calls[0].arguments, args);
    assert.equal(res.statusCode, status);
    if (status === 204) {
      assert.equal(res.sent, true);
      assert.equal(res.body, undefined);
    } else {
      assert.deepEqual(res.body.data, result);
      assert.equal(res.body.success, true);
      assert.equal(res.body.meta.requestId, "request-a");
    }
  });

  test(`${method} rejects missing identity before calling the service`, async (t) => {
    const { req, res, controller } = fixture();
    delete req.auth;
    const serviceMock = t.mock.method(cartService, method, async () => undefined);
    let received;
    await controller[method](req, res, (error) => { received = error; });
    assert.equal(received.statusCode, 401);
    assert.equal(received.code, "AUTH_TOKEN_MISSING");
    assert.equal(serviceMock.mock.callCount(), 0);
    assert.equal(res.body, undefined);
  });

  test(`${method} forwards service errors without sending a success response`, async (t) => {
    const { req, res, controller } = fixture();
    const failure = new Error("Service failed");
    t.mock.method(cartService, method, async () => { throw failure; });
    let received;
    await controller[method](req, res, (error) => { received = error; });
    assert.equal(received, failure);
    assert.equal(res.body, undefined);
    assert.equal(res.sent, undefined);
  });
}
