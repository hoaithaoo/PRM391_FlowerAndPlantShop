import assert from "node:assert/strict";
import { describe, test } from "node:test";

import { AppError } from "../../common/errors/app-error";
import { GeminiChatbotProvider } from "./gemini.provider";

const PRODUCT_ID = "11111111-1111-4111-8111-111111111111";
const UNKNOWN_PRODUCT_ID = "22222222-2222-4222-8222-222222222222";

const input = {
  message: "Tư vấn cây để bàn",
  history: [],
  catalogProducts: [
    {
      id: PRODUCT_ID,
      name: "Cây Lưỡi Hổ Mini",
      description: "Cây chịu bóng",
      price: "120000",
    },
  ],
  incidentContext: null,
};

function providerWith(fetchImpl: typeof fetch, timeoutMs = 100): GeminiChatbotProvider {
  return new GeminiChatbotProvider({
    apiKey: "test-key",
    model: "gemini-test",
    baseUrl: "https://gemini.example/v1beta",
    timeoutMs,
    fetchImpl,
  });
}

function geminiResponse(payload: unknown): Response {
  return new Response(
    JSON.stringify({
      candidates: [{ content: { parts: [{ text: JSON.stringify(payload) }] } }],
    }),
    { status: 200, headers: { "content-type": "application/json" } }
  );
}

describe("GeminiChatbotProvider", () => {
  test("parses structured output and keeps only catalog product identifiers", async () => {
    const provider = providerWith(async () =>
      geminiResponse({
        reply: "Bạn có thể tham khảo cây Lưỡi Hổ Mini.",
        suggestedProductIds: [PRODUCT_ID, UNKNOWN_PRODUCT_ID, PRODUCT_ID],
        actionDraft: null,
      })
    );

    const result = await provider.generate(input);

    assert.equal(result.reply, "Bạn có thể tham khảo cây Lưỡi Hổ Mini.");
    assert.deepEqual(result.suggestedProductIds, [PRODUCT_ID]);
    assert.equal(result.actionDraft, null);
  });

  test("returns an editable incident draft from valid structured output", async () => {
    const provider = providerWith(async () =>
      geminiResponse({
        reply: "Mình đã chuẩn bị thông tin báo lỗi thanh toán.",
        suggestedProductIds: [],
        actionDraft: {
          category: "PAYMENT",
          title: "Thanh toán chưa được ghi nhận",
          description: "Tôi đã thanh toán nhưng trạng thái chưa cập nhật.",
        },
      })
    );

    const result = await provider.generate(input);

    assert.equal(result.actionDraft?.category, "PAYMENT");
  });

  test("maps an aborted request to CHATBOT_PROVIDER_TIMEOUT", async () => {
    const fetchImpl = ((_url: string | URL | Request, init?: RequestInit) =>
      new Promise<Response>((_resolve, reject) => {
        init?.signal?.addEventListener("abort", () => reject(new DOMException("Aborted", "AbortError")));
      })) as typeof fetch;
    const provider = providerWith(fetchImpl, 5);

    await assert.rejects(provider.generate(input), (error: unknown) => {
      return error instanceof AppError && error.statusCode === 504 && error.code === "CHATBOT_PROVIDER_TIMEOUT";
    });
  });

  test("maps non-success and malformed responses to CHATBOT_PROVIDER_ERROR", async () => {
    const unavailable = providerWith(async () => new Response("unavailable", { status: 503 }));
    const malformed = providerWith(async () => geminiResponse({ reply: "missing fields" }));

    for (const provider of [unavailable, malformed]) {
      await assert.rejects(provider.generate(input), (error: unknown) => {
        return error instanceof AppError && error.statusCode === 502 && error.code === "CHATBOT_PROVIDER_ERROR";
      });
    }
  });
});
