import { Prisma, PrismaClient } from "@prisma/client";

import { prisma } from "../../lib/prisma";
import {
  ChatbotCatalogProduct,
  ChatbotConversationRecord,
  ChatbotExchangeInput,
  ChatbotExchangeResult,
  ChatbotHistoryPage,
  ChatbotKnowledgeChunk,
  ChatbotRepository,
  OwnedOrderContext,
  OwnedPaymentContext,
  StoredChatbotMessage,
  SearchKnowledgeInput,
} from "./chatbot.repository";
import { RAG_EMBEDDING_DIMENSIONS } from "./embedding.provider";

export class PrismaChatbotRepository implements ChatbotRepository {
  constructor(private readonly client: PrismaClient = prisma) {}

  async findOwnedConversation(id: string, userId: string): Promise<ChatbotConversationRecord | null> {
    return this.client.chatbotConversation.findFirst({
      where: { id, userId },
      select: { id: true, userId: true, title: true },
    });
  }

  async findRecentMessages(conversationId: string, limit: number): Promise<StoredChatbotMessage[]> {
    const rows = await this.client.chatbotMessage.findMany({
      where: { conversationId },
      orderBy: { sequence: "desc" },
      take: limit,
      select: { id: true, role: true, content: true, metadata: true, createdAt: true },
    });
    return rows.reverse();
  }

  async findProductById(id: string): Promise<ChatbotCatalogProduct | null> {
    const row = await this.client.product.findFirst({
      where: { id, isActive: true },
      select: {
        id: true,
        name: true,
        description: true,
        price: true,
        imageUrl: true,
        isActive: true,
        stock: true,
      },
    });
    return row ? { ...row, price: row.price.toFixed(0) } : null;
  }

  async listCatalogProducts(limit: number): Promise<ChatbotCatalogProduct[]> {
    const rows = await this.client.product.findMany({
      where: { isActive: true, stock: { gt: 0 } },
      orderBy: { createdAt: "desc" },
      take: limit,
      select: {
        id: true,
        name: true,
        description: true,
        price: true,
        imageUrl: true,
        isActive: true,
        stock: true,
      },
    });
    return rows.map((row) => ({ ...row, price: row.price.toFixed(0) }));
  }

  async searchKnowledge(input: SearchKnowledgeInput): Promise<ChatbotKnowledgeChunk[]> {
    if (
      input.embedding !== null &&
      (input.embedding.length !== RAG_EMBEDDING_DIMENSIONS ||
        !input.embedding.every((value) => Number.isFinite(value)))
    ) {
      throw new Error(`Query embedding must contain ${RAG_EMBEDDING_DIMENSIONS} finite numbers.`);
    }

    const limit = Math.max(1, Math.min(Math.trunc(input.limit), 30));
    const candidateLimit = Math.min(limit * 4, 120);
    const hasEmbedding = input.embedding !== null;
    const vector = input.embedding ? JSON.stringify(input.embedding) : null;
    const queryVector = Prisma.sql`${vector}::extensions.vector(768)`;
    const minPrice = input.filters.minPrice ?? null;
    const maxPrice = input.filters.maxPrice ?? null;

    type KnowledgeRow = Omit<ChatbotKnowledgeChunk, "score"> & { score: number | string };

    // Hai bảng xếp hạng chạy độc lập rồi hợp nhất bằng RRF để tên chính xác và ý nghĩa đều có trọng số.
    const rows = await this.client.$queryRaw<KnowledgeRow[]>(Prisma.sql`
      WITH filtered AS (
        SELECT
          chunk."id",
          chunk."product_id",
          chunk."chunk_index",
          chunk."content",
          chunk."search_vector",
          chunk."embedding_model",
          chunk."embedding",
          product."name" AS "product_name",
          product."price"::text AS "price",
          product."image_url",
          product."stock"
        FROM "product_knowledge_chunks" AS chunk
        INNER JOIN "products" AS product ON product."id" = chunk."product_id"
        WHERE product."is_active" = true
          AND product."stock" > 0
          AND (${minPrice}::numeric IS NULL OR product."price" >= ${minPrice}::numeric)
          AND (${maxPrice}::numeric IS NULL OR product."price" <= ${maxPrice}::numeric)
      ),
      full_text AS (
        SELECT
          "id",
          row_number() OVER (
            ORDER BY ts_rank_cd(
              "search_vector",
              websearch_to_tsquery('simple', ${input.query})
            ) DESC, "id"
          ) AS rank_ix
        FROM filtered
        WHERE "search_vector" @@ websearch_to_tsquery('simple', ${input.query})
        ORDER BY ts_rank_cd(
          "search_vector",
          websearch_to_tsquery('simple', ${input.query})
        ) DESC, "id"
        LIMIT ${candidateLimit}
      ),
      semantic AS (
        SELECT
          "id",
          row_number() OVER (ORDER BY "embedding" OPERATOR(extensions.<=>) ${queryVector}, "id") AS rank_ix
        FROM filtered
        WHERE ${hasEmbedding}
          AND "embedding_model" = ${input.embeddingModel}
          AND 1 - ("embedding" OPERATOR(extensions.<=>) ${queryVector}) >= ${input.minSemanticScore}
        ORDER BY "embedding" OPERATOR(extensions.<=>) ${queryVector}, "id"
        LIMIT ${candidateLimit}
      ),
      fused AS (
        SELECT
          COALESCE(full_text."id", semantic."id") AS "id",
          (
            COALESCE(1.0 / (50 + full_text.rank_ix), 0.0)
            + COALESCE(1.0 / (50 + semantic.rank_ix), 0.0)
          )::double precision AS "score"
        FROM full_text
        FULL OUTER JOIN semantic ON semantic."id" = full_text."id"
      ),
      product_ranked AS (
        SELECT
          filtered."product_id" AS "productId",
          filtered."product_name" AS "productName",
          filtered."content",
          filtered."price",
          filtered."image_url" AS "imageUrl",
          filtered."stock",
          fused."score",
          row_number() OVER (
            PARTITION BY filtered."product_id"
            ORDER BY fused."score" DESC, filtered."chunk_index", filtered."id"
          ) AS product_rank
        FROM fused
        INNER JOIN filtered ON filtered."id" = fused."id"
      )
      SELECT "productId", "productName", "content", "price", "imageUrl", "stock", "score"
      FROM product_ranked
      WHERE product_rank = 1
      ORDER BY "score" DESC, "productId"
      LIMIT ${limit}
    `);

    return rows.map((row) => ({ ...row, score: Number(row.score) }));
  }

  async findOwnedOrder(userId: string, id: string): Promise<OwnedOrderContext | null> {
    return this.client.order.findFirst({
      where: { id, userId },
      select: { id: true, userId: true, orderNumber: true, status: true },
    });
  }

  async findOwnedPayment(userId: string, id: string): Promise<OwnedPaymentContext | null> {
    const row = await this.client.payment.findFirst({
      where: { id, invoice: { userId } },
      select: {
        id: true,
        status: true,
        invoice: {
          select: {
            userId: true,
            order: { select: { id: true, orderNumber: true, status: true } },
          },
        },
      },
    });
    if (!row) return null;
    return {
      id: row.id,
      userId: row.invoice.userId,
      status: row.status,
      orderId: row.invoice.order.id,
      orderNumber: row.invoice.order.orderNumber,
      orderStatus: row.invoice.order.status,
    };
  }

  async tryAcquireSendSlot(userId: string, cooldownMs: number, leaseMs: number): Promise<boolean> {
    // Một UPSERT có điều kiện giúp việc cấp slot là atomic giữa các process backend.
    const rows = await this.client.$queryRaw<Array<{ user_id: string }>>(Prisma.sql`
      INSERT INTO "chatbot_rate_limits" ("user_id", "last_finished_at", "in_flight_until")
      VALUES (
        ${userId}::uuid,
        NULL,
        clock_timestamp() + (${leaseMs} * interval '1 millisecond')
      )
      ON CONFLICT ("user_id") DO UPDATE
      SET "in_flight_until" = EXCLUDED."in_flight_until"
      WHERE "chatbot_rate_limits"."in_flight_until" <= clock_timestamp()
        AND (
          "chatbot_rate_limits"."last_finished_at" IS NULL
          OR "chatbot_rate_limits"."last_finished_at"
            <= clock_timestamp() - (${cooldownMs} * interval '1 millisecond')
        )
      RETURNING "user_id"
    `);
    return rows.length === 1;
  }

  async releaseSendSlot(userId: string): Promise<void> {
    await this.client.$executeRaw(Prisma.sql`
      UPDATE "chatbot_rate_limits"
      SET
        "last_finished_at" = clock_timestamp(),
        "in_flight_until" = clock_timestamp()
      WHERE "user_id" = ${userId}::uuid
    `);
  }

  async createExchange(input: ChatbotExchangeInput): Promise<ChatbotExchangeResult> {
    // Lưu cả câu hỏi và câu trả lời trong cùng transaction để lịch sử không bị lệch nửa lượt chat.
    return this.client.$transaction(async (transaction) => {
      if (input.createConversation) {
        await transaction.chatbotConversation.create({
          data: {
            id: input.conversationId,
            userId: input.userId,
            title: input.title,
          },
        });
      }

      await transaction.chatbotMessage.create({
        data: {
          conversationId: input.conversationId,
          role: "USER",
          content: input.userMessage,
        },
      });
      const assistant = await transaction.chatbotMessage.create({
        data: {
          conversationId: input.conversationId,
          role: "ASSISTANT",
          content: input.assistantReply,
          metadata: input.assistantMetadata as unknown as Prisma.InputJsonValue,
        },
        select: { id: true, createdAt: true },
      });
      await transaction.chatbotConversation.update({
        where: { id: input.conversationId },
        data: { updatedAt: assistant.createdAt },
      });

      return {
        conversationId: input.conversationId,
        assistantMessageId: assistant.id,
        createdAt: assistant.createdAt,
      };
    });
  }

  async getMessages(conversationId: string, page: number, pageSize: number): Promise<ChatbotHistoryPage> {
    const [rows, total] = await this.client.$transaction([
      this.client.chatbotMessage.findMany({
        where: { conversationId },
        orderBy: { sequence: "desc" },
        skip: (page - 1) * pageSize,
        take: pageSize,
        select: { id: true, role: true, content: true, metadata: true, createdAt: true },
      }),
      this.client.chatbotMessage.count({ where: { conversationId } }),
    ]);
    // Phân trang từ tin mới nhất nhưng trả từng trang theo thứ tự đọc từ cũ đến mới.
    return { items: rows.reverse(), total };
  }

  async deleteOwnedConversation(conversationId: string, userId: string): Promise<boolean> {
    const result = await this.client.chatbotConversation.deleteMany({
      where: { id: conversationId, userId },
    });
    return result.count === 1;
  }
}
