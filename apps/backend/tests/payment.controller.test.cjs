const assert = require("node:assert/strict");
const { test } = require("node:test");

let PaymentController;
let paymentService;
let loadError;
try {
  ({ PaymentController } = require("../dist/modules/payments/payment.controller"));
  ({ paymentService } = require("../dist/modules/payments/payment.service"));
} catch (error) {
  loadError = error;
}

function fixture() {
  assert.ifError(loadError);
  const req = {
    auth: { userId: "user-a" },
    params: { id: "33333333-3333-4333-8333-333333333333" },
    requestId: "request-a",
  };
  const res = {
    statusCode: 200,
    status(code) { this.statusCode = code; return this; },
    json(body) { this.body = body; return this; },
  };
  return { req, res, controller: new PaymentController() };
}

test("getStatus uses the authenticated owner and returns payment data", async (t) => {
  const { req, res, controller } = fixture();
  const result = { id: req.params.id, amount: 285000, status: "PENDING" };
  const serviceMock = t.mock.method(paymentService, "getStatus", async () => result);

  await controller.getStatus(req, res, (error) => { throw error; });

  assert.deepEqual(serviceMock.mock.calls[0].arguments, ["user-a", req.params.id]);
  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.body.data, result);
});

test("getStatus rejects a missing authenticated identity", async (t) => {
  const { req, res, controller } = fixture();
  delete req.auth;
  const serviceMock = t.mock.method(paymentService, "getStatus", async () => undefined);
  let received;

  await controller.getStatus(req, res, (error) => { received = error; });

  assert.equal(received.statusCode, 401);
  assert.equal(received.code, "AUTH_TOKEN_MISSING");
  assert.equal(serviceMock.mock.callCount(), 0);
  assert.equal(res.body, undefined);
});
