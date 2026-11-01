const assert = require("node:assert/strict");
const { test } = require("node:test");

let paymentSchemas;
let loadError;
try {
  paymentSchemas = require("../dist/modules/payments/payment.schema");
} catch (error) {
  loadError = error;
}

test("payment status params accept only one UUID payment ID", () => {
  assert.ifError(loadError);
  const id = "33333333-3333-4333-8333-333333333333";
  assert.deepEqual(paymentSchemas.paymentIdParamsSchema.parse({ id }), { id });
  for (const params of [
    { id: "not-a-uuid" },
    { id, userId: "another-user" },
    {},
  ]) {
    assert.equal(paymentSchemas.paymentIdParamsSchema.safeParse(params).success, false);
  }
});
