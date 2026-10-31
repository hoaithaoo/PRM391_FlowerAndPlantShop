import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { AppError } from "../../common/errors/app-error";
import { SepaySignatureVerifier } from "./sepay-signature";

const SECRET = "c0ffee".repeat(10);

const assertStatus = (fn: () => void, status: number) => {
  assert.throws(fn, (error: unknown) => {
    assert.ok(error instanceof AppError);
    assert.equal(error.statusCode, status);
    return true;
  });
};

describe("SepaySignatureVerifier.verifyApiKey", () => {
  const verifier = new SepaySignatureVerifier(SECRET);

  it("nhận header Authorization: Apikey <key> đúng (không phân biệt hoa thường scheme)", () => {
    assert.doesNotThrow(() => verifier.verifyApiKey(`Apikey ${SECRET}`));
    assert.doesNotThrow(() => verifier.verifyApiKey(`APIKEY  ${SECRET} `));
  });

  it("từ chối key sai hoặc scheme khác", () => {
    assertStatus(() => verifier.verifyApiKey("Apikey wrong-key"), 401);
    assertStatus(() => verifier.verifyApiKey(`Bearer ${SECRET}`), 401);
    assertStatus(() => verifier.verifyApiKey("Apikey"), 401);
  });

  it("trả 503 khi chưa cấu hình secret", () => {
    assertStatus(() => new SepaySignatureVerifier(undefined).verifyApiKey(`Apikey ${SECRET}`), 503);
  });
});
