import { Prisma, PrismaClient } from "@prisma/client";

import { prisma } from "../../lib/prisma";
import {
  ChatbotCatalogProduct,
  ChatbotConversationRecord,
  ChatbotExchangeInput,
  ChatbotExchangeResult,
  ChatbotHistoryPage,
  ChatbotRepository,
  ChatbotRepositorySession,
  OwnedOrderContext,
  OwnedPaymentContext,
  StoredChatbotMessage,
} from "./chatbot.repository";

type DatabaseClient = Prisma.TransactionClient;

export class PrismaChatbotRepository implements ChatbotRepository {
  constructor(
    private readonly client: PrismaClient = prisma,
    private readonly transactionTimeoutMs = 25_000
  ) {}

  async withUserSendLock<T>(
    userId: string,
    work: (session: ChatbotRepositorySession) => Promise<T>
  ): Promise<T> {
    return this.client.$transaction(
      async (transaction) => {
        await transaction.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${userId}, 0))`;
        return work(new PrismaChatbotRepositorySession(transaction));
      },
      { timeout: this.transactionTimeoutMs }
    );
  }

  async findOwnedConversation(id: string, userId: string): Promise<ChatbotConversationRecord | null> {
    return this.client.chatbotConversation.findFirst({
      where: { id, userId },
      select: { id: true, userId: true, title: true },
    });
  }

  async getMessages(conversationId: string, page: number, pageSize: number): Promise<ChatbotHistoryPage> {
    const [rows, total] = await this.client.$transaction([
      this.client.chatbotMessage.findMany({
        where: { conversationId },
        orderBy: [{ createdAt: "desc" }, { id: "desc" }],
        skip: (page - 1) * pageSize,
        take: pageSize,
        select: { id: true, role: true, content: true, metadata: true, createdAt: true },
      }),
      this.client.chatbotMessage.count({ where: { conversationId } }),
    ]);
    return { items: rows.reverse(), total };
  }

  async deleteOwnedConversation(conversationId: string, userId: string): Promise<boolean> {
    const result = await this.client.chatbotConversation.deleteMany({
      where: { id: conversationId, userId },
    });
    return result.count === 1;
  }
}

class PrismaChatbotRepositorySession implements ChatbotRepositorySession {
  constructor(private readonly db: DatabaseClient) {}

  async findOwnedConversation(id: string, userId: string): Promise<ChatbotConversationRecord | null> {
    return this.db.chatbotConversation.findFirst({
      where: { id, userId },
      select: { id: true, userId: true, title: true },
    });
  }

  async findRecentMessages(conversationId: string, limit: number): Promise<StoredChatbotMessage[]> {
    const rows = await this.db.chatbotMessage.findMany({
      where: { conversationId },
      orderBy: [{ createdAt: "desc" }, { id: "desc" }],
      take: limit,
      select: { id: true, role: true, content: true, metadata: true, createdAt: true },
    });
    return rows.reverse();
  }

  async findProductById(id: string): Promise<ChatbotCatalogProduct | null> {
    const row = await this.db.product.findFirst({
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
    const rows = await this.db.product.findMany({
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

  async findOwnedOrder(userId: string, id: string): Promise<OwnedOrderContext | null> {
    return this.db.order.findFirst({
      where: { id, userId },
      select: { id: true, userId: true, orderNumber: true, status: true },
    });
  }

  async findOwnedPayment(userId: string, id: string): Promise<OwnedPaymentContext | null> {
    const row = await this.db.payment.findFirst({
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

  async findLastUserMessageAt(userId: string): Promise<Date | null> {
    const row = await this.db.chatbotMessage.findFirst({
      where: { role: "USER", conversation: { userId } },
      orderBy: { createdAt: "desc" },
      select: { createdAt: true },
    });
    return row?.createdAt ?? null;
  }

  async createExchange(input: ChatbotExchangeInput): Promise<ChatbotExchangeResult> {
    if (input.createConversation) {
      await this.db.chatbotConversation.create({
        data: {
          id: input.conversationId,
          userId: input.userId,
          title: input.title,
        },
      });
    }

    await this.db.chatbotMessage.create({
      data: {
        conversationId: input.conversationId,
        role: "USER",
        content: input.userMessage,
      },
    });
    const assistant = await this.db.chatbotMessage.create({
      data: {
        conversationId: input.conversationId,
        role: "ASSISTANT",
        content: input.assistantReply,
        metadata: input.assistantMetadata as unknown as Prisma.InputJsonValue,
      },
      select: { id: true, createdAt: true },
    });
    await this.db.chatbotConversation.update({
      where: { id: input.conversationId },
      data: { updatedAt: assistant.createdAt },
    });

    return {
      conversationId: input.conversationId,
      assistantMessageId: assistant.id,
      createdAt: assistant.createdAt,
    };
  }
}
