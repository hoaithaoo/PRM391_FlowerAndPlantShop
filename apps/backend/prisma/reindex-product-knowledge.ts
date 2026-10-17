import { Prisma, PrismaClient } from "@prisma/client";

import { env } from "../src/config/env";
import { RAG_EMBEDDING_DIMENSIONS } from "../src/modules/chatbot/providers/embedding.provider";
import { GeminiEmbeddingProvider } from "../src/modules/chatbot/providers/gemini-embedding.provider";
import {
  ProductKnowledgeIndexStore,
  ProductKnowledgeRow,
  reindexProductKnowledge,
} from "../src/modules/chatbot/rag/product-knowledge-indexer";

const prisma = new PrismaClient();

const store: ProductKnowledgeIndexStore = {
  async listProducts() {
    const products = await prisma.product.findMany({
      select: {
        id: true,
        name: true,
        description: true,
        category: { select: { name: true } },
      },
      orderBy: { id: "asc" },
    });
    return products.map((product) => ({
      id: product.id,
      name: product.name,
      description: product.description,
      categoryName: product.category.name,
    }));
  },

  async replaceAll(rows: ProductKnowledgeRow[]) {
    await prisma.$transaction(async (transaction) => {
      await transaction.$executeRaw(Prisma.sql`DELETE FROM "product_knowledge_chunks"`);

      for (const row of rows) {
        const vector = JSON.stringify(row.embedding);
        await transaction.$executeRaw(Prisma.sql`
          INSERT INTO "product_knowledge_chunks" (
            "product_id",
            "chunk_index",
            "content",
            "source_hash",
            "embedding_model",
            "embedding"
          ) VALUES (
            ${row.productId}::uuid,
            ${row.chunkIndex},
            ${row.content},
            ${row.sourceHash},
            ${row.embeddingModel},
            ${vector}::extensions.vector(768)
          )
        `);
      }
    });
  },
};

async function main(): Promise<void> {
  const embeddingProvider = new GeminiEmbeddingProvider({
    apiKey: env.GEMINI_API_KEY ?? "",
    model: env.GEMINI_EMBEDDING_MODEL,
    baseUrl: env.GEMINI_API_BASE_URL,
    dimensions: RAG_EMBEDDING_DIMENSIONS,
    timeoutMs: env.GEMINI_TIMEOUT_MS,
  });
  const summary = await reindexProductKnowledge({
    store,
    embeddingProvider,
    embeddingModel: env.GEMINI_EMBEDDING_MODEL,
  });

  console.info(
    `RAG reindex completed: ${summary.productsIndexed}/${summary.productsRead} products, ${summary.chunksIndexed} chunks.`
  );
}

main()
  .catch((error: unknown) => {
    console.error("RAG reindex failed", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
