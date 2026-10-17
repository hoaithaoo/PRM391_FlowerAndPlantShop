import assert from "node:assert/strict";
import { describe, test } from "node:test";

import { AppError } from "../../common/errors/app-error";
import { GeminiEmbeddingProvider } from "./gemini-embedding.provider";

const DIMENSIONS = 768;
const VECTOR = Array.from({ length: DIMENSIONS }, (_, index) => index / DIMENSIONS);

function providerWith(fetchImpl: typeof fetch, timeoutMs = 100): GeminiEmbeddingProvider {
  return new GeminiEmbeddingProvider({
    apiKey: "test-key",
    model: "embedding-test",
    baseUrl: "https://embedding.example/v1beta",
    dimensions: DIMENSIONS,
    timeoutMs,
    fetchImpl,
  });
}

function embeddingResponse(values: unknown = VECTOR): Response {
  return new Response(JSON.stringify({ embedding: { values } }), {
    status: 200,
    headers: { "content-type": "application/json" },
  });
}

describe("GeminiEmbeddingProvider", () => {
  test("formats document and query inputs for asymmetric retrieval", async () => {
    const requestBodies: unknown[] = [];
    const provider = providerWith(async (_url, init) => {
      requestBodies.push(JSON.parse(String(init?.body)));
      return embeddingResponse();
    });

    await provider.embedDocument("Cây chịu bóng.", "Cây Lưỡi Hổ");
    await provider.embedQuery("cây cho phòng ít nắng");

    assert.deepEqual(requestBodies, [
      {
        model: "models/embedding-test",
        content: { parts: [{ text: "title: Cây Lưỡi Hổ | text: Cây chịu bóng." }] },
        output_dimensionality: DIMENSIONS,
      },
      {
        model: "models/embedding-test",
        content: { parts: [{ text: "task: search result | query: cây cho phòng ít nắng" }] },
        output_dimensionality: DIMENSIONS,
      },
    ]);
  });

  test("returns a finite vector with the configured dimensions", async () => {
    const result = await providerWith(async () => embeddingResponse()).embedQuery("cây để bàn");

    assert.equal(result.length, DIMENSIONS);
    assert.equal(result.every(Number.isFinite), true);
  });

  test("rejects malformed and wrong-sized vectors at the provider boundary", async () => {
    const providers = [
      providerWith(async () => embeddingResponse([0.1, 0.2])),
      providerWith(async () => embeddingResponse([...VECTOR.slice(0, -1), Number.NaN])),
    ];

    for (const provider of providers) {
      await assert.rejects(provider.embedQuery("cây"), (error: unknown) => {
        return error instanceof AppError && error.code === "CHATBOT_PROVIDER_ERROR";
      });
    }
  });

  test("maps an aborted request to the chatbot provider timeout", async () => {
    const fetchImpl = ((_url: string | URL | Request, init?: RequestInit) =>
      new Promise<Response>((_resolve, reject) => {
        init?.signal?.addEventListener("abort", () => reject(new DOMException("Aborted", "AbortError")));
      })) as typeof fetch;

    await assert.rejects(providerWith(fetchImpl, 5).embedQuery("cây"), (error: unknown) => {
      return error instanceof AppError && error.code === "CHATBOT_PROVIDER_TIMEOUT";
    });
  });

  test("maps non-success responses without exposing the provider name", async () => {
    const provider = providerWith(async () => new Response("unavailable", { status: 503 }));

    await assert.rejects(provider.embedQuery("cây"), (error: unknown) => {
      return (
        error instanceof AppError &&
        error.code === "CHATBOT_PROVIDER_ERROR" &&
        !error.message.toLocaleLowerCase("vi").includes("gemini")
      );
    });
  });
});
