const assert = require("node:assert/strict");
const { test } = require("node:test");

let webhookSchemas;
let loadError;
try {
  webhookSchemas = require("../dist/modules/webhooks/sepay-webhook.schema");
} catch (error) {
  loadError = error;
}

const validPayload = {
  id: 92704,
  gateway: "Vietcombank",
  transactionDate: "2026-10-25 14:30:00",
  accountNumber: "1017588888",
  code: "PAY20261025ABCDEF123456",
  content: "PAY20261025ABCDEF123456 chuyen tien",
  transferType: "in",
  transferAmount: 285000,
  referenceCode: "FT24012345678",
  description: "A real SePay payload can contain additional fields",
};

test("SePay payload normalizes provider values and preserves documented extras", () => {
  assert.ifError(loadError);
  const result = webhookSchemas.sepayWebhookSchema.parse(validPayload);
  assert.equal(result.id, "92704");
  assert.equal(result.transferType, "IN");
  assert.equal(result.description, validPayload.description);
});

test("SePay payload rejects missing IDs, invalid direction, and non-positive amounts", () => {
  assert.ifError(loadError);
  for (const payload of [
    { ...validPayload, id: "" },
    { ...validPayload, transferType: "sideways" },
    { ...validPayload, transferAmount: 0 },
    { ...validPayload, transferAmount: 285000.5 },
    { ...validPayload, transferAmount: Number.MAX_SAFE_INTEGER + 1 },
    { ...validPayload, transferAmount: "285000" },
  ]) {
    assert.equal(webhookSchemas.sepayWebhookSchema.safeParse(payload).success, false);
  }
});
