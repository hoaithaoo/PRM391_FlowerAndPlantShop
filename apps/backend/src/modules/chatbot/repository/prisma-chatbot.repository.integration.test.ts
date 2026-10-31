import assert from "node:assert/strict";
import { after, describe, test } from "node:test";
import { Prisma, PrismaClient } from "@prisma/client";

import { PrismaChatbotRepository } from "./prisma-chatbot.repository";

const databaseUrl = process.env.CHATBOT_INTEGRATION_DATABASE_URL;
const client = databaseUrl ? new PrismaClient({ datasourceUrl: databaseUrl }) : null;
const repository = client ? new PrismaChatbotRepository(client) : null;

const metadata = { suggestedProducts: [], action: null };

describe("PrismaChatbotRepository with PostgreSQL", { skip: !databaseUrl }, () => {
  after(async () => {
    await client?.$disconnect();
  });

  test("atomically rejects an overlapping slot and preserves cooldown outside conversation history", async () => {
    const userId = "41414141-4141-4414-8414-414141414141";
    const conversationId = "42424242-4242-4424-8424-424242424242";
    await client!.profile.create({ data: { id: userId, email: "rate-limit@example.com" } });

    try {
      assert.equal(await repository!.tryAcquireSendSlot(userId, 10_000, 30_000), true);
      assert.equal(await repository!.tryAcquireSendSlot(userId, 10_000, 30_000), false);

      await repository!.createExchange({
        conversationId,
        createConversation: true,
        userId,
        title: "Rate limit",
        userMessage: "Tin đầu",
        assistantReply: "Phản hồi đầu",
        assistantMetadata: metadata,
      });
      await repository!.releaseSendSlot(userId);
      await repository!.deleteOwnedConversation(conversationId, userId);

      assert.equal(await repository!.tryAcquireSendSlot(userId, 10_000, 30_000), false);
    } finally {
      await client!.profile.deleteMany({ where: { id: userId } });
    }
  });

  test("returns persisted turns in deterministic user-assistant order", async () => {
    const userId = "51515151-5151-4515-8515-515151515151";
    const conversationId = "52525252-5252-4525-8525-525252525252";
    await client!.profile.create({ data: { id: userId, email: "ordering@example.com" } });

    try {
      await repository!.createExchange({
        conversationId,
        createConversation: true,
        userId,
        title: "Ordering",
        userMessage: "user-1",
        assistantReply: "assistant-1",
        assistantMetadata: metadata,
      });
      await repository!.createExchange({
        conversationId,
        createConversation: false,
        userId,
        title: null,
        userMessage: "user-2",
        assistantReply: "assistant-2",
        assistantMetadata: metadata,
      });

      const recent = await repository!.findRecentMessages(conversationId, 10);
      const history = await repository!.getMessages(conversationId, 1, 20);
      const expected = ["user-1", "assistant-1", "user-2", "assistant-2"];

      assert.deepEqual(recent.map((message) => message.content), expected);
      assert.deepEqual(history.items.map((message) => message.content), expected);
    } finally {
      await client!.profile.deleteMany({ where: { id: userId } });
    }
  });

  test("hybrid retrieval applies active, stock, and price filters before ranking", async () => {
    const categoryId = "61616161-6161-4616-8616-616161616161";
    const matchingProductId = "62626262-6262-4626-8626-626262626262";
    const expensiveProductId = "63636363-6363-4636-8636-636363636363";
    const unavailableProductId = "64646464-6464-4646-8646-646464646464";
    const inactiveProductId = "65656565-6565-4656-8656-656565656565";
    const vector = Array.from({ length: 768 }, (_, index) => (index === 0 ? 1 : 0));
    const vectorLiteral = JSON.stringify(vector);

    await client!.category.create({
      data: { id: categoryId, name: "RAG integration", slug: "rag-integration" },
    });
    await client!.product.createMany({
      data: [
        {
          id: matchingProductId,
          categoryId,
          name: "Cây để bàn hợp lệ",
          slug: "rag-matching-product",
          sku: "RAG-MATCH",
          description: "ragintegrationunique Cây để bàn chịu ánh sáng yếu.",
          price: new Prisma.Decimal(180_000),
          stock: 5,
          isActive: true,
        },
        {
          id: expensiveProductId,
          categoryId,
          name: "Cây quá giá",
          slug: "rag-expensive-product",
          sku: "RAG-EXPENSIVE",
          description: "ragintegrationunique Cây để bàn chịu ánh sáng yếu.",
          price: new Prisma.Decimal(450_000),
          stock: 5,
          isActive: true,
        },
        {
          id: unavailableProductId,
          categoryId,
          name: "Cây hết hàng",
          slug: "rag-unavailable-product",
          sku: "RAG-UNAVAILABLE",
          description: "ragintegrationunique Cây để bàn chịu ánh sáng yếu.",
          price: new Prisma.Decimal(150_000),
          stock: 0,
          isActive: true,
        },
        {
          id: inactiveProductId,
          categoryId,
          name: "Cây ngừng bán",
          slug: "rag-inactive-product",
          sku: "RAG-INACTIVE",
          description: "ragintegrationunique Cây để bàn chịu ánh sáng yếu.",
          price: new Prisma.Decimal(150_000),
          stock: 5,
          isActive: false,
        },
      ],
    });

    try {
      for (const productId of [matchingProductId, expensiveProductId, unavailableProductId, inactiveProductId]) {
        await client!.$executeRaw(Prisma.sql`
          INSERT INTO "product_knowledge_chunks" (
            "product_id", "chunk_index", "content", "source_hash", "embedding_model", "embedding"
          ) VALUES (
            ${productId}::uuid,
            0,
            'ragintegrationunique Cây để bàn chịu ánh sáng yếu.',
            ${"a".repeat(64)},
            'integration-test',
            ${vectorLiteral}::extensions.vector(768)
          )
        `);
      }
      await client!.$executeRaw(Prisma.sql`
        INSERT INTO "product_knowledge_chunks" (
          "product_id", "chunk_index", "content", "source_hash", "embedding_model", "embedding"
        ) VALUES (
          ${matchingProductId}::uuid,
          1,
          'Đoạn thứ hai của cùng sản phẩm.',
          ${"b".repeat(64)},
          'integration-test',
          ${vectorLiteral}::extensions.vector(768)
        )
      `);

      const results = await repository!.searchKnowledge({
        query: "ragintegrationunique",
        embedding: vector,
        embeddingModel: "integration-test",
        filters: { maxPrice: 300_000 },
        limit: 6,
        minSemanticScore: 0.55,
      });

      const productIds = results.map((result) => result.productId);
      assert.equal(productIds.includes(matchingProductId), true);
      assert.equal(productIds.includes(expensiveProductId), false);
      assert.equal(productIds.includes(unavailableProductId), false);
      assert.equal(productIds.includes(inactiveProductId), false);
      assert.equal(productIds.filter((id) => id === matchingProductId).length, 1);

      const semanticOnly = await repository!.searchKnowledge({
        query: "english semantic query without lexical overlap",
        embedding: vector,
        embeddingModel: "integration-test",
        filters: { maxPrice: 300_000 },
        limit: 6,
        minSemanticScore: 0.99,
      });
      assert.equal(semanticOnly.filter((result) => result.productId === matchingProductId).length, 1);

      const wrongEmbeddingSpace = await repository!.searchKnowledge({
        query: "english semantic query without lexical overlap",
        embedding: vector,
        embeddingModel: "another-model",
        filters: { maxPrice: 300_000 },
        limit: 6,
        minSemanticScore: 0.99,
      });
      assert.equal(wrongEmbeddingSpace.some((result) => result.productId === matchingProductId), false);
    } finally {
      await client!.product.deleteMany({ where: { categoryId } });
      await client!.category.deleteMany({ where: { id: categoryId } });
    }
  });
});
