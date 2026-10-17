import assert from "node:assert/strict";
import { describe, test } from "node:test";
import { PrismaClient } from "@prisma/client";

import { PrismaChatbotRepository } from "./prisma-chatbot.repository";

describe("PrismaChatbotRepository.searchKnowledge", () => {
  test("maps a ranked hybrid-search row to verified product knowledge", async () => {
    const queries: unknown[] = [];
    const client = {
      $queryRaw: async (query: unknown) => {
        queries.push(query);
        return [
          {
            productId: "11111111-1111-4111-8111-111111111111",
            productName: "Cây Lưỡi Hổ",
            content: "Cây chịu được ánh sáng yếu.",
            price: "180000",
            imageUrl: null,
            stock: 5,
            score: 0.032,
          },
        ];
      },
    } as unknown as PrismaClient;
    const repository = new PrismaChatbotRepository(client);

    const result = await repository.searchKnowledge({
      query: "cây dưới 300k",
      embedding: Array.from({ length: 768 }, () => 0.01),
      embeddingModel: "embedding-test",
      filters: { maxPrice: 300_000 },
      limit: 6,
      minSemanticScore: 0.55,
    });

    assert.equal(queries.length, 1);
    assert.deepEqual(result, [
      {
        productId: "11111111-1111-4111-8111-111111111111",
        productName: "Cây Lưỡi Hổ",
        content: "Cây chịu được ánh sáng yếu.",
        price: "180000",
        imageUrl: null,
        stock: 5,
        score: 0.032,
      },
    ]);
  });

  test("rejects a malformed query vector before contacting PostgreSQL", async () => {
    let queryCalls = 0;
    const client = {
      $queryRaw: async () => {
        queryCalls += 1;
        return [];
      },
    } as unknown as PrismaClient;
    const repository = new PrismaChatbotRepository(client);

    await assert.rejects(
      repository.searchKnowledge({
        query: "cây",
        embedding: [0.1, 0.2],
        embeddingModel: "embedding-test",
        filters: {},
        limit: 6,
        minSemanticScore: 0.55,
      }),
      /768/u
    );
    assert.equal(queryCalls, 0);
  });
});
