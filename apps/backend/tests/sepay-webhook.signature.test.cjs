const assert = require("node:assert/strict");
const { createHmac } = require("node:crypto");
const { test } = require("node:test");

let SepaySignatureVerifier;
let loadError;
try {
  ({ SepaySignatureVerifier } = require("../dist/modules/webhooks/sepay-signature"));
} catch (error) {
  loadError = error;
}

const secret = "test-sepay-secret";
const nowMs = 1792915200000;
const timestamp = String(Math.floor(nowMs / 1000));
const rawBody = Buffer.from('{"id":92704,"transferType":"in","transferAmount":285000}');

const sign = (body, signedAt = timestamp) => {
  const hmac = createHmac("sha256", secret);
  hmac.update(`${signedAt}.`, "utf8");
  hmac.update(body);
  return `sha256=${hmac.digest("hex")}`;
};

const hasError = (statusCode, code) => (error) => {
  assert.equal(error.statusCode, statusCode);
  assert.equal(error.code, code);
  return true;
};

test("signature verification accepts an exact fresh raw request body", () => {
  assert.ifError(loadError);
  const verifier = new SepaySignatureVerifier(secret, () => nowMs);
  assert.doesNotThrow(() => verifier.verify(rawBody, sign(rawBody), timestamp));
});

test("signature verification rejects tampering and timestamps outside five minutes", () => {
  assert.ifError(loadError);
  const verifier = new SepaySignatureVerifier(secret, () => nowMs);
  assert.throws(
    () => verifier.verify(Buffer.from('{"id":92705}'), sign(rawBody), timestamp),
    hasError(401, "SEPAY_SIGNATURE_INVALID")
  );
  const staleTimestamp = String(Number(timestamp) - 301);
  assert.throws(
    () => verifier.verify(rawBody, sign(rawBody, staleTimestamp), staleTimestamp),
    hasError(401, "SEPAY_SIGNATURE_INVALID")
  );
});

test("signature verification hashes the exact raw bytes without UTF-8 rewriting", () => {
  assert.ifError(loadError);
  const verifier = new SepaySignatureVerifier(secret, () => nowMs);
  const binaryBody = Buffer.from([0xff, 0xfe, 0x7b, 0x7d]);
  assert.doesNotThrow(() =>
    verifier.verify(binaryBody, sign(binaryBody), timestamp)
  );
});

test("signature verification reports missing server configuration", () => {
  assert.ifError(loadError);
  const verifier = new SepaySignatureVerifier(undefined, () => nowMs);
  assert.throws(
    () => verifier.verify(rawBody, sign(rawBody), timestamp),
    hasError(503, "SERVICE_UNAVAILABLE")
  );
});

test("API Key auth accepts the configured key and rejects others", () => {
  assert.ifError(loadError);
  const verifier = new SepaySignatureVerifier(undefined, () => nowMs, "sepay-api-key");
  assert.doesNotThrow(() =>
    verifier.verify(rawBody, undefined, undefined, "Apikey sepay-api-key")
  );
  assert.throws(
    () => verifier.verify(rawBody, undefined, undefined, "Apikey wrong-key"),
    (error) => hasError(401, "SEPAY_SIGNATURE_INVALID")(error) && error.reason === "apikey_mismatch"
  );
  assert.throws(
    () => verifier.verify(rawBody, undefined, undefined, undefined),
    hasError(401, "SEPAY_SIGNATURE_INVALID")
  );
});

test("signed requests always use HMAC even when an API key is configured", () => {
  assert.ifError(loadError);
  const verifier = new SepaySignatureVerifier(secret, () => nowMs, "sepay-api-key");
  assert.doesNotThrow(() => verifier.verify(rawBody, sign(rawBody), timestamp));
  assert.throws(
    () => verifier.verify(rawBody, "sha256=" + "0".repeat(64), timestamp, "Apikey sepay-api-key"),
    (error) => error.reason === "hmac_mismatch"
  );
});

test("rejections carry a diagnostic reason", () => {
  assert.ifError(loadError);
  const verifier = new SepaySignatureVerifier(secret, () => nowMs);
  assert.throws(() => verifier.verify(rawBody, undefined, undefined), (e) => e.reason === "missing_signature_headers");
  const stale = String(Number(timestamp) - 301);
  assert.throws(() => verifier.verify(rawBody, sign(rawBody, stale), stale), (e) => e.reason === "stale_timestamp");
});
