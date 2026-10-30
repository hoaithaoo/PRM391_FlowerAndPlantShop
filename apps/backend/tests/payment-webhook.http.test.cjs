const assert = require("node:assert/strict");
const { createHmac } = require("node:crypto");
const { once } = require("node:events");
const { before, after, beforeEach, test } = require("node:test");

process.env.NODE_ENV = "test";
process.env.DATABASE_URL = "postgresql://test:test@127.0.0.1:1/payment_test";
process.env.SUPABASE_URL = "https://example.supabase.co";
process.env.SUPABASE_PUBLISHABLE_KEY = "test-publishable-key";
process.env.SEPAY_WEBHOOK_SECRET = "test-sepay-secret";

global.prisma = {
  profile: { async findUnique() { return null; } },
  async $disconnect() {},
};

const { createApp } = require("../dist/app");
const { prisma } = require("../dist/lib/prisma");
const { supabase } = require("../dist/lib/supabase");
const { paymentService } = require("../dist/modules/payments/payment.service");
const { sepayWebhookService } = require("../dist/modules/webhooks/sepay-webhook.service");

const userId = "11111111-1111-4111-8111-111111111111";
const paymentId = "33333333-3333-4333-8333-333333333333";
const paymentResult = {
  id: paymentId,
  invoiceId: "22222222-2222-4222-8222-222222222222",
  provider: "SEPAY",
  paymentCode: "PAY20261025ABCDEF123456",
  amount: 285000,
  status: "PENDING",
  paidAt: null,
};
const webhookPayload = {
  id: 92704,
  gateway: "Vietcombank",
  transferType: "in",
  transferAmount: 285000,
  code: "PAY20261025ABCDEF123456",
  content: "PAY20261025ABCDEF123456 chuyen tien",
};

let server;
let baseUrl;

before(async () => {
  server = createApp().listen(0, "127.0.0.1");
  await once(server, "listening");
  baseUrl = `http://127.0.0.1:${server.address().port}/api/v1`;
});

after(async () => {
  if (server) await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  await prisma.$disconnect();
});

beforeEach((t) => {
  t.mock.method(supabase.auth, "getUser", async () => ({
    data: { user: { id: userId, email: "test@example.com", user_metadata: {} } },
    error: null,
  }));
  t.mock.method(prisma.profile, "findUnique", async () => ({ id: userId, role: "USER", status: "ACTIVE" }));
  t.mock.method(paymentService, "getStatus", async () => paymentResult);
  t.mock.method(sepayWebhookService, "process", async (payload) => ({
    accepted: true,
    transactionId: payload.id,
  }));
});

test("payment status endpoint validates auth and ownership input", async () => {
  const missing = await fetch(`${baseUrl}/payments/${paymentId}/status`);
  assert.equal(missing.status, 401);
  assert.equal((await missing.json()).error.code, "AUTH_TOKEN_MISSING");

  const invalid = await fetch(`${baseUrl}/payments/not-a-uuid/status`, {
    headers: { Authorization: "Bearer valid-token" },
  });
  assert.equal(invalid.status, 422);
  assert.equal((await invalid.json()).error.code, "VALIDATION_ERROR");

  const response = await fetch(`${baseUrl}/payments/${paymentId}/status`, {
    headers: { Authorization: "Bearer valid-token" },
  });
  assert.equal(response.status, 200);
  assert.deepEqual((await response.json()).data, paymentResult);
  assert.deepEqual(paymentService.getStatus.mock.calls[0].arguments, [userId, paymentId]);
});

function signedWebhookRequest(body, { signature, timestamp } = {}) {
  const rawBody = JSON.stringify(body);
  const signedAt = timestamp ?? String(Math.floor(Date.now() / 1000));
  const digest = signature ?? `sha256=${createHmac("sha256", process.env.SEPAY_WEBHOOK_SECRET)
    .update(`${signedAt}.${rawBody}`)
    .digest("hex")}`;
  return fetch(`${baseUrl}/webhooks/sepay`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-SePay-Signature": digest,
      "X-SePay-Timestamp": signedAt,
    },
    body: rawBody,
  });
}

test("signed SePay webhook returns the provider-compatible success envelope", async () => {
  const response = await signedWebhookRequest(webhookPayload);
  assert.equal(response.status, 200);
  const body = await response.json();
  assert.equal(body.success, true);
  assert.deepEqual(body.data, { accepted: true, transactionId: "92704" });
  assert.equal(sepayWebhookService.process.mock.calls[0].arguments[0].transferType, "IN");
});

test("SePay webhook rejects invalid signatures before processing payload", async () => {
  const response = await signedWebhookRequest(webhookPayload, { signature: `sha256=${"0".repeat(64)}` });
  assert.equal(response.status, 401);
  assert.equal((await response.json()).error.code, "SEPAY_SIGNATURE_INVALID");
  assert.equal(sepayWebhookService.process.mock.callCount(), 0);
});

test("signed malformed SePay payload returns BAD_REQUEST", async () => {
  const response = await signedWebhookRequest({ ...webhookPayload, transferAmount: 0 });
  assert.equal(response.status, 400);
  assert.equal((await response.json()).error.code, "BAD_REQUEST");
  assert.equal(sepayWebhookService.process.mock.callCount(), 0);
});

test("SePay webhook rejects compressed bodies before signature processing", async () => {
  const rawBody = JSON.stringify(webhookPayload);
  const signedAt = String(Math.floor(Date.now() / 1000));
  const signature = `sha256=${createHmac("sha256", process.env.SEPAY_WEBHOOK_SECRET)
    .update(`${signedAt}.${rawBody}`)
    .digest("hex")}`;
  const response = await fetch(`${baseUrl}/webhooks/sepay`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Content-Encoding": "gzip",
      "X-SePay-Signature": signature,
      "X-SePay-Timestamp": signedAt,
    },
    body: rawBody,
  });

  assert.equal(response.status, 400);
  assert.equal((await response.json()).error.code, "BAD_REQUEST");
  assert.equal(sepayWebhookService.process.mock.callCount(), 0);
});
