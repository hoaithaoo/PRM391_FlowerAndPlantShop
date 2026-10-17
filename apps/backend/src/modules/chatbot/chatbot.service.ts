import { randomUUID } from "node:crypto";
import { z } from "zod";

import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { logger } from "../../lib/logger";
import { SendChatbotMessageInput } from "./chatbot.schema";
import { ChatbotProvider, VerifiedIncidentContext } from "./providers/chatbot.provider";
import { EmbeddingProvider } from "./providers/embedding.provider";
import {
  ChatbotCatalogProduct,
  ChatbotRepository,
  OwnedOrderContext,
  OwnedPaymentContext,
} from "./repository/chatbot.repository";
import {
  ChatbotAction,
  ChatbotHistoryResult,
  ChatbotMessageMetadata,
  SendChatbotMessageResult,
  SuggestedProduct,
} from "./chatbot.types";
import {
  parseProductSearchFilters,
  stripProductSearchFilters,
} from "./rag/product-search-query";

const HISTORY_PAGE_SIZE = 20;
const messageMetadataSchema = z.object({
  suggestedProducts: z.array(
    z.object({
      id: z.string().uuid(),
      name: z.string(),
      price: z.string(),
      imageUrl: z.string().nullable(),
    })
  ),
  action: z
    .object({
      type: z.literal("OPEN_INCIDENT_REPORT"),
      draft: z.object({
        category: z.string(),
        title: z.string(),
        description: z.string(),
        orderId: z.string().uuid().nullable(),
        paymentId: z.string().uuid().nullable(),
        conversationId: z.string().uuid(),
      }),
    })
    .nullable(),
});

interface ChatbotServiceOptions {
  repository: ChatbotRepository;
  provider: ChatbotProvider;
  embeddingProvider: EmbeddingProvider;
  embeddingModel: string;
  minSemanticScore: number;
  rateLimitMs: number;
  sendLeaseMs: number;
  newId?: () => string;
}

export class ChatbotService {
  private readonly newId: () => string;

  constructor(private readonly options: ChatbotServiceOptions) {
    this.newId = options.newId ?? randomUUID;
  }

  async sendMessage(userId: string, input: SendChatbotMessageInput): Promise<SendChatbotMessageResult> {
    const repository = this.options.repository;
    const conversationId = input.conversationId ?? this.newId();
    const createConversation = !input.conversationId;

    if (input.conversationId) {
      const conversation = await repository.findOwnedConversation(input.conversationId, userId);
      if (!conversation) {
        throw new AppError(
          404,
          ErrorCodes.CHATBOT_CONVERSATION_NOT_FOUND,
          "Không tìm thấy phiên chatbot."
        );
      }
    }

    // Chỉ đưa dữ liệu đã kiểm tra tồn tại và quyền sở hữu vào prompt của AI.
    const contextProduct = await this.verifyProductContext(repository, input.productId);
    const incidentContext = await this.verifyIncidentContext(repository, userId, input.context);
    const history = input.conversationId
      ? await repository.findRecentMessages(input.conversationId, 12)
      : [];

    // Giữ slot trước các network call để chặn gửi trùng giữa nhiều instance backend.
    const acquired = await repository.tryAcquireSendSlot(
      userId,
      this.options.rateLimitMs,
      this.options.sendLeaseMs
    );
    if (!acquired) {
      throw new AppError(429, ErrorCodes.CHATBOT_RATE_LIMITED, "Bạn đang gửi tin nhắn quá nhanh.");
    }

    try {
      let queryEmbedding: number[] | null = null;
      try {
        queryEmbedding = await this.options.embeddingProvider.embedQuery(input.message);
      } catch (error) {
        // Keyword search vẫn phục vụ được tên/mã chính xác khi dịch vụ embedding tạm thời lỗi.
        logger.warn("Chatbot semantic retrieval unavailable; using keyword fallback", {
          reason: error instanceof Error ? error.message : "unknown",
        });
      }

      const knowledge = await repository.searchKnowledge({
        query: stripProductSearchFilters(input.message) || input.message,
        embedding: queryEmbedding,
        embeddingModel: this.options.embeddingModel,
        filters: parseProductSearchFilters(input.message),
        limit: 6,
        minSemanticScore: this.options.minSemanticScore,
      });
      const catalogProducts = this.buildGroundedCatalog(knowledge, contextProduct);
      const knowledgeChunks = knowledge.map(({ productId, productName, content, score }) => ({
        productId,
        productName,
        content,
        score,
      }));

      if (
        contextProduct?.description &&
        !knowledgeChunks.some((chunk) => chunk.productId === contextProduct.id)
      ) {
        knowledgeChunks.unshift({
          productId: contextProduct.id,
          productName: contextProduct.name,
          content: contextProduct.description,
          score: 1,
        });
      }

      const providerResult = await this.options.provider.generate({
        message: input.message,
        history: history.map(({ role, content }) => ({ role, content })),
        catalogProducts: catalogProducts.map(({ id, name, description, price }) => ({
          id,
          name,
          description,
          price,
        })),
        knowledgeChunks,
        contextProduct: contextProduct
          ? {
              id: contextProduct.id,
              name: contextProduct.name,
              description: contextProduct.description,
              price: contextProduct.price,
            }
          : null,
        incidentContext,
      });

      const allowAnswerArtifacts = providerResult.responseType === "ANSWER";
      const allowIncidentArtifacts =
        providerResult.responseType === "INCIDENT" && incidentContext !== null;
      const reply =
        (allowAnswerArtifacts && catalogProducts.length === 0) ||
        (providerResult.responseType === "INCIDENT" && !allowIncidentArtifacts)
          ? noKnowledgeReply(input.message)
          : providerResult.reply;
      const suggestedProducts = allowAnswerArtifacts
        ? this.resolveSuggestions(providerResult.suggestedProductIds, catalogProducts)
        : [];
      const action = allowIncidentArtifacts && providerResult.actionDraft
        ? this.buildIncidentAction(conversationId, providerResult.actionDraft, incidentContext)
        : null;
      const assistantMetadata: ChatbotMessageMetadata = { suggestedProducts, action };
      const exchange = await repository.createExchange({
        conversationId,
        createConversation,
        userId,
        title: createConversation ? input.message.slice(0, 80) : null,
        userMessage: input.message,
        assistantReply: reply,
        assistantMetadata,
      });

      return {
        conversationId: exchange.conversationId,
        messageId: exchange.assistantMessageId,
        reply,
        suggestedProducts,
        action,
        createdAt: exchange.createdAt.toISOString(),
      };
    } finally {
      try {
        await repository.releaseSendSlot(userId);
      } catch (error) {
        logger.error("Failed to release chatbot send slot", { userId, error });
      }
    }
  }

  async getHistory(userId: string, conversationId: string, page: number): Promise<ChatbotHistoryResult> {
    const conversation = await this.requireOwnedConversation(userId, conversationId);
    const history = await this.options.repository.getMessages(conversationId, page, HISTORY_PAGE_SIZE);

    return {
      conversation: { id: conversation.id, title: conversation.title },
      items: history.items.map((message) => {
        const metadata = message.role === "ASSISTANT" ? messageMetadataSchema.safeParse(message.metadata) : null;
        return {
          id: message.id,
          role: message.role,
          content: message.content,
          suggestedProducts: metadata?.success ? metadata.data.suggestedProducts : [],
          action: metadata?.success ? metadata.data.action : null,
          createdAt: message.createdAt.toISOString(),
        };
      }),
      page,
      pageSize: HISTORY_PAGE_SIZE,
      total: history.total,
      totalPages: Math.ceil(history.total / HISTORY_PAGE_SIZE),
    };
  }

  async deleteConversation(userId: string, conversationId: string): Promise<void> {
    await this.requireOwnedConversation(userId, conversationId);
    const deleted = await this.options.repository.deleteOwnedConversation(conversationId, userId);
    if (!deleted) {
      throw this.conversationNotFound();
    }
  }

  private async verifyProductContext(
    repository: ChatbotRepository,
    productId: string | null | undefined
  ): Promise<ChatbotCatalogProduct | null> {
    if (!productId) return null;
    const product = await repository.findProductById(productId);
    if (!product) {
      throw new AppError(404, ErrorCodes.PRODUCT_NOT_FOUND, "Không tìm thấy sản phẩm.");
    }
    return product;
  }

  private async verifyIncidentContext(
    repository: ChatbotRepository,
    userId: string,
    context: SendChatbotMessageInput["context"]
  ): Promise<VerifiedIncidentContext | null> {
    if (!context) return null;

    let order: OwnedOrderContext | null = null;
    let payment: OwnedPaymentContext | null = null;
    if (context.orderId) {
      order = await repository.findOwnedOrder(userId, context.orderId);
      if (!order) {
        throw new AppError(404, ErrorCodes.ORDER_NOT_FOUND, "Không tìm thấy đơn hàng.");
      }
    }
    if (context.paymentId) {
      payment = await repository.findOwnedPayment(userId, context.paymentId);
      if (!payment || (order && payment.orderId !== order.id)) {
        throw new AppError(404, ErrorCodes.PAYMENT_NOT_FOUND, "Không tìm thấy thanh toán.");
      }
    }

    return {
      orderId: order?.id ?? payment?.orderId ?? null,
      orderNumber: order?.orderNumber ?? payment?.orderNumber ?? null,
      orderStatus: order?.status ?? payment?.orderStatus ?? null,
      paymentId: payment?.id ?? null,
      paymentStatus: payment?.status ?? null,
      source: context.source ?? null,
    };
  }

  private resolveSuggestions(ids: string[], catalog: ChatbotCatalogProduct[]): SuggestedProduct[] {
    const products = new Map(catalog.map((product) => [product.id, product]));
    // ID do AI trả về là dữ liệu không tin cậy; chỉ giữ sản phẩm còn bán trong catalog hiện tại.
    return [...new Set(ids)].flatMap((id) => {
      const product = products.get(id);
      if (!product || !product.isActive || product.stock <= 0) return [];
      return [{ id: product.id, name: product.name, price: product.price, imageUrl: product.imageUrl }];
    });
  }

  private buildGroundedCatalog(
    knowledge: Awaited<ReturnType<ChatbotRepository["searchKnowledge"]>>,
    contextProduct: ChatbotCatalogProduct | null
  ): ChatbotCatalogProduct[] {
    const products = new Map<string, ChatbotCatalogProduct>();
    for (const chunk of knowledge) {
      products.set(chunk.productId, {
        id: chunk.productId,
        name: chunk.productName,
        description: chunk.content,
        price: chunk.price,
        imageUrl: chunk.imageUrl,
        isActive: true,
        stock: chunk.stock,
      });
    }

    // Sản phẩm người dùng đang xem đã được verify riêng nên cũng là context đáng tin cậy.
    if (contextProduct?.isActive && contextProduct.stock > 0) {
      products.set(contextProduct.id, contextProduct);
    }
    return [...products.values()];
  }

  private buildIncidentAction(
    conversationId: string,
    draft: { category: string; title: string; description: string },
    context: VerifiedIncidentContext | null
  ): ChatbotAction {
    return {
      type: "OPEN_INCIDENT_REPORT",
      draft: {
        ...draft,
        orderId: context?.orderId ?? null,
        paymentId: context?.paymentId ?? null,
        conversationId,
      },
    };
  }

  private async requireOwnedConversation(userId: string, conversationId: string) {
    const conversation = await this.options.repository.findOwnedConversation(conversationId, userId);
    if (!conversation) throw this.conversationNotFound();
    return conversation;
  }

  private conversationNotFound(): AppError {
    return new AppError(404, ErrorCodes.CHATBOT_CONVERSATION_NOT_FOUND, "Không tìm thấy phiên chatbot.");
  }
}

function noKnowledgeReply(message: string): string {
  const normalized = message
    .toLocaleLowerCase("vi")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/gu, "")
    .replace(/đ/gu, "d");
  // Không dùng cờ `i` với dải ký tự có dấu: case-folding biến "ſ" (U+017F) thành "s" nên mọi câu tiếng Anh có chữ s bị nhận nhầm.
  const vietnamese = /[ăâđêôơưĩũẠ-ỹ]/u.test(message.toLocaleLowerCase("vi")) ||/\b(cay|hoa|cho (?:toi|minh)|toi (?:can|muon)|minh (?:can|muon)|ban la|khong|nao)\b/iu.test(normalized);
  return vietnamese
    ? "Hiện tại dữ liệu đã xác minh của cửa hàng chưa có đủ thông tin để trả lời câu hỏi này."
    : "The store's verified data does not currently contain enough information to answer that question.";
}
