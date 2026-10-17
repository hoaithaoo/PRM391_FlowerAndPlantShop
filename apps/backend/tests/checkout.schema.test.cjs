const assert = require("node:assert/strict");
const { test } = require("node:test");
const { PaymentMethod } = require("@prisma/client");
const {
  checkoutSchema,
  idempotencyKeySchema,
} = require("../dist/modules/checkout/checkout.schema");

const validCheckout = {
  receiverName: "Nguyen Van A",
  phone: "0901234567",
  address: "123 Nguyen Trai, Ho Chi Minh City",
  latitude: 10.762,
  longitude: 106.682,
  paymentMethod: PaymentMethod.COD,
};

test("checkout accepts COD and SEPAY from the Prisma enum", () => {
  for (const paymentMethod of [PaymentMethod.COD, PaymentMethod.SEPAY]) {
    const result = checkoutSchema.parse({ ...validCheckout, paymentMethod });
    assert.equal(result.paymentMethod, paymentMethod);
  }
});

test("checkout rejects ONLINE, missing, and malformed payment methods with a useful error", () => {
  for (const paymentMethod of ["ONLINE", "cod", "", undefined, null, 1]) {
    const result = checkoutSchema.safeParse({ ...validCheckout, paymentMethod });
    assert.equal(result.success, false);
    assert.ok(result.error.issues.some(issue =>
      issue.path[0] === "paymentMethod" && issue.message.includes("COD hoặc SEPAY")
    ));
  }
});

test("checkout accepts Vietnamese mobile numbers in local and international form", () => {
  for (const phone of ["0901234567", "+84901234567", " 0901234567 "]) {
    assert.equal(checkoutSchema.parse({ ...validCheckout, phone }).phone, phone.trim());
  }
  for (const phone of ["0|12345678", "0201234567", "090123456", "09012345678", "+840901234567", "090 123 4567", "", 901234567]) {
    assert.equal(checkoutSchema.safeParse({ ...validCheckout, phone }).success, false, String(phone));
  }
});

test("checkout uses the phone contract field and rejects legacy phoneNumber", () => {
  const { phone, ...withoutPhone } = validCheckout;
  assert.equal(checkoutSchema.safeParse(withoutPhone).success, false);
  assert.equal(checkoutSchema.safeParse({ ...withoutPhone, phoneNumber: phone }).success, false);
});

test("checkout permits omitted, null, and trimmed notes", () => {
  assert.equal(checkoutSchema.parse(validCheckout).note, undefined);
  assert.equal(checkoutSchema.parse({ ...validCheckout, note: null }).note, null);
  assert.equal(checkoutSchema.parse({ ...validCheckout, note: " Giao buoi sang " }).note, "Giao buoi sang");
  assert.equal(checkoutSchema.safeParse({ ...validCheckout, note: "a".repeat(501) }).success, false);
});

test("checkout trims recipient and address and rejects empty or oversized values", () => {
  const result = checkoutSchema.parse({ ...validCheckout, receiverName: " Nguyen Van A ", address: " 123 Nguyen Trai " });
  assert.equal(result.receiverName, "Nguyen Van A");
  assert.equal(result.address, "123 Nguyen Trai");
  for (const field of ["receiverName", "address"]) {
    assert.equal(checkoutSchema.safeParse({ ...validCheckout, [field]: "   " }).success, false);
  }
  assert.equal(checkoutSchema.safeParse({ ...validCheckout, receiverName: "a".repeat(101) }).success, false);
  assert.equal(checkoutSchema.safeParse({ ...validCheckout, address: "a".repeat(201) }).success, false);
});

test("checkout accepts zero and boundary coordinates but rejects invalid coordinate values", () => {
  for (const [latitude, longitude] of [[0, 0], [-90, -180], [90, 180]]) {
    assert.equal(checkoutSchema.safeParse({ ...validCheckout, latitude, longitude }).success, true);
  }
  for (const coords of [
    { latitude: -91 }, { latitude: 91 }, { longitude: -181 }, { longitude: 181 },
    { latitude: "10.762" }, { longitude: null }, { latitude: NaN }, { longitude: Infinity },
  ]) {
    assert.equal(checkoutSchema.safeParse({ ...validCheckout, ...coords }).success, false);
  }
});

test("checkout rejects client-controlled ownership, prices, and cart contents", () => {
  for (const field of ["userId", "price", "totalAmount", "shippingFee", "items"]) {
    assert.equal(checkoutSchema.safeParse({ ...validCheckout, [field]: "untrusted" }).success, false, field);
  }
});

test("checkout validates and trims optional idempotency keys", () => {
  assert.equal(idempotencyKeySchema.parse(" request-a "), "request-a");
  for (const key of ["", "   ", "a".repeat(201)]) {
    assert.equal(idempotencyKeySchema.safeParse(key).success, false);
  }
});
