import assert from "node:assert/strict";
import { describe, test } from "node:test";

import { AppError } from "../../../common/errors/app-error";
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
  knowledgeChunks: [
    {
      productId: PRODUCT_ID,
      productName: "Cây Lưỡi Hổ Mini",
      content: "Cây chịu được ánh sáng yếu.",
      score: 0.032,
    },
  ],
  contextProduct: null,
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
        responseType: "ANSWER",
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
        responseType: "INCIDENT",
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

  test("sends only retrieved knowledge with scope, identity, and language rules", async () => {
    let requestBody: any;
    const provider = providerWith(async (_url, init) => {
      requestBody = JSON.parse(String(init?.body));
      return geminiResponse({
        responseType: "ANSWER",
        reply: "Cây phù hợp.",
        suggestedProductIds: [PRODUCT_ID],
        actionDraft: null,
      });
    });

    await provider.generate(input);

    const payload = JSON.parse(requestBody.contents.at(-1).parts[0].text);
    assert.deepEqual(payload.knowledgeChunks, input.knowledgeChunks);
    assert.deepEqual(requestBody.generationConfig.thinkingConfig, { thinkingLevel: "low" });
    assert.match(requestBody.system_instruction.parts[0].text, /trợ lý AI của dự án/u);
    assert.match(requestBody.system_instruction.parts[0].text, /ngôn ngữ/u);
    assert.match(requestBody.system_instruction.parts[0].text, /OFF_TOPIC/u);
    assert.match(requestBody.system_instruction.parts[0].text, /NO_KNOWLEDGE/u);
  });

  test("removes suggestions and actions from every non-answer response", async () => {
    for (const responseType of ["IDENTITY", "TRANSLATION", "OFF_TOPIC", "NO_KNOWLEDGE"] as const) {
      const provider = providerWith(async () =>
        geminiResponse({
          responseType,
          reply: responseType === "IDENTITY" ? "Tôi là Gemini của Google." : "Không áp dụng.",
          suggestedProductIds: [PRODUCT_ID],
          actionDraft: {
            category: "PAYMENT",
            title: "Không được giữ",
            description: "Không được giữ",
          },
        })
      );

      const result = await provider.generate(input);

      assert.deepEqual(result.suggestedProductIds, []);
      assert.equal(result.actionDraft, null);
      if (responseType === "IDENTITY") {
        assert.equal(result.reply.includes("Gemini"), false);
        assert.equal(result.reply.includes("Google"), false);
      }
    }
  });

  test("forces project identity even when generated output tries to disclose its provider", async () => {
    const provider = providerWith(async () =>
      geminiResponse({
        responseType: "ANSWER",
        reply: "Tôi là Gemini của Google.",
        suggestedProductIds: [PRODUCT_ID],
        actionDraft: null,
      })
    );

    const result = await provider.generate({ ...input, message: "Bạn là AI gì?" });

    assert.equal(result.responseType, "IDENTITY");
    assert.equal(result.reply, "Tôi là trợ lý AI của dự án Plant & Flower Shop, hỗ trợ bạn tìm sản phẩm và thông tin của cửa hàng.");
    assert.deepEqual(result.suggestedProductIds, []);
  });

  test("uses Vietnamese for an unaccented identity question and blocks other provider names", async () => {
    const provider = providerWith(async () =>
      geminiResponse({
        responseType: "ANSWER",
        reply: "I am Claude from Anthropic.",
        suggestedProductIds: [PRODUCT_ID],
        actionDraft: null,
      })
    );

    const result = await provider.generate({ ...input, message: "cho minh biet ban la ai" });

    assert.equal(result.responseType, "IDENTITY");
    assert.match(result.reply, /^Tôi là trợ lý AI của dự án/u);
    assert.equal(/claude|anthropic/iu.test(result.reply), false);
    assert.deepEqual(result.suggestedProductIds, []);
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

  test("instructs the model to mirror the user's language even for Vietnamese knowledge", async () => {
    let requestBody: any;
    const provider = providerWith(async (_url, init) => {
      requestBody = JSON.parse(String(init?.body));
      return geminiResponse({ responseType: "ANSWER", reply: "OK", suggestedProductIds: [], actionDraft: null });
    });

    await provider.generate(input);

    assert.match(requestBody.system_instruction.parts[0].text, /kể cả khi knowledgeChunks bằng tiếng Việt/u);
  });

  test("keeps a safe generated refusal in the user's language instead of the Vietnamese/English template", async () => {
    const cases = [
      { responseType: "IDENTITY", message: "Who are you?", reply: "I'm the AI assistant of the Plant & Flower Shop project." },
      { responseType: "OFF_TOPIC", message: "Python で配列をソートして", reply: "申し訳ありませんが、植物・花・ショップの商品についてのみお手伝いできます。" },
      { responseType: "NO_KNOWLEDGE", message: "Quelle est la garantie ?", reply: "Les données vérifiées de la boutique ne contiennent pas encore cette information." },
    ] as const;

    for (const { responseType, message, reply } of cases) {
      const provider = providerWith(async () =>
        geminiResponse({ responseType, reply, suggestedProductIds: [], actionDraft: null })
      );

      const result = await provider.generate({ ...input, message });

      assert.equal(result.responseType, responseType);
      assert.equal(result.reply, reply);
    }
  });

  test("falls back to the template when a refusal is long enough to smuggle off-topic content", async () => {
    const provider = providerWith(async () =>
      geminiResponse({
        responseType: "OFF_TOPIC",
        reply: `Sorry, but here is the code anyway: ${"def sort(a): return sorted(a)\n".repeat(30)}`,
        suggestedProductIds: [],
        actionDraft: null,
      })
    );

    const result = await provider.generate({ ...input, message: "Write a Python sort function" });

    assert.equal(result.reply, "Sorry, I can only help with plants, flowers, products, and services from the store.");
  });

  test("blocks transliterated provider names in non-Latin identity replies", async () => {
    const provider = providerWith(async () =>
      geminiResponse({ responseType: "IDENTITY", reply: "私はグーグルのジェミニです。", suggestedProductIds: [], actionDraft: null })
    );

    const result = await provider.generate({ ...input, message: "あなたは誰ですか？" });

    assert.equal(/グーグル|ジェミニ/u.test(result.reply), false);
  });

  test("does not expose the provider name when configuration is missing", async () => {
    const provider = new GeminiChatbotProvider({
      apiKey: "",
      model: "gemini-test",
      baseUrl: "https://gemini.example/v1beta",
      timeoutMs: 100,
      fetchImpl: async () => geminiResponse({}),
    });

    await assert.rejects(provider.generate(input), (error: unknown) => {
      return (
        error instanceof AppError &&
        error.code === "CHATBOT_PROVIDER_ERROR" &&
        !error.message.toLocaleLowerCase("vi").includes("gemini")
      );
    });
  });
});
