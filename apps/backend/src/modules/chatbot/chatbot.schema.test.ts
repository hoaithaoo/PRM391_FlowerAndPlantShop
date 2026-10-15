import assert from "node:assert/strict";
import { describe, test } from "node:test";

import {
  conversationParamsSchema,
  historyQuerySchema,
  sendChatbotMessageSchema,
} from "./chatbot.schema";

const UUID = "11111111-1111-4111-8111-111111111111";

describe("sendChatbotMessageSchema", () => {
  test("accepts the shortest message and optional verified context identifiers", () => {
    const parsed = sendChatbotMessageSchema.parse({
      conversationId: UUID,
      message: "a",
      productId: UUID,
      context: { orderId: UUID, paymentId: UUID, source: "payment-screen" },
    });

    assert.equal(parsed.message, "a");
    assert.equal(parsed.context?.paymentId, UUID);
  });

  test("rejects blank and over-2000-character messages", () => {
    assert.equal(sendChatbotMessageSchema.safeParse({ message: "   " }).success, false);
    assert.equal(sendChatbotMessageSchema.safeParse({ message: "a".repeat(2001) }).success, false);
  });

  test("rejects malformed identifiers and unknown fields", () => {
    assert.equal(sendChatbotMessageSchema.safeParse({ message: "help", productId: "bad" }).success, false);
    assert.equal(sendChatbotMessageSchema.safeParse({ message: "help", userId: UUID }).success, false);
    assert.equal(conversationParamsSchema.safeParse({ id: "bad" }).success, false);
  });
});

describe("historyQuerySchema", () => {
  test("defaults to page one and coerces a positive integer query value", () => {
    assert.deepEqual(historyQuerySchema.parse({}), { page: 1 });
    assert.deepEqual(historyQuerySchema.parse({ page: "2" }), { page: 2 });
  });

  test("rejects pages below one", () => {
    assert.equal(historyQuerySchema.safeParse({ page: "0" }).success, false);
  });
});
