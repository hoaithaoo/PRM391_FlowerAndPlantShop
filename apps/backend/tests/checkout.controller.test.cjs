const assert = require("node:assert/strict");
const { test } = require("node:test");
const {
  CheckoutController,
} = require("../dist/modules/checkout/checkout.controller");
const {
  checkoutService,
} = require("../dist/modules/checkout/checkout.service");

function fixture() {
  const req = {
    auth: { userId: "user-a" },
    body: { receiverName: "Nguyen Van A" },
    requestId: "request-a",
    get(name) {
      return name.toLowerCase() === "idempotency-key" ? " checkout-a " : undefined;
    },
  };
  const res = {
    statusCode: 200,
    status(code) { this.statusCode = code; return this; },
    json(body) { this.body = body; return this; },
  };
  return { req, res, controller: new CheckoutController() };
}

test("checkout controller passes authenticated identity and idempotency key", async (t) => {
  const { req, res, controller } = fixture();
  const result = { order: { id: "order-a" } };
  const serviceMock = t.mock.method(checkoutService, "checkout", async () => result);

  await controller.checkout(req, res, (error) => { throw error; });

  assert.deepEqual(serviceMock.mock.calls[0].arguments, [
    "user-a",
    req.body,
    "checkout-a",
  ]);
  assert.equal(res.statusCode, 201);
  assert.equal(res.body.success, true);
  assert.deepEqual(res.body.data, result);
});

test("checkout controller rejects a missing authenticated identity", async (t) => {
  const { req, res, controller } = fixture();
  delete req.auth;
  const serviceMock = t.mock.method(checkoutService, "checkout", async () => undefined);
  let received;

  await controller.checkout(req, res, (error) => { received = error; });

  assert.equal(received.statusCode, 401);
  assert.equal(received.code, "AUTH_TOKEN_MISSING");
  assert.equal(serviceMock.mock.callCount(), 0);
  assert.equal(res.body, undefined);
});

test("checkout controller forwards service errors", async (t) => {
  const { req, res, controller } = fixture();
  const failure = new Error("Checkout failed");
  t.mock.method(checkoutService, "checkout", async () => { throw failure; });
  let received;

  await controller.checkout(req, res, (error) => { received = error; });

  assert.equal(received, failure);
  assert.equal(res.body, undefined);
});
