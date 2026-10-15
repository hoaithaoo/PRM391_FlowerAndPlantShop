import { randomUUID } from "node:crypto";
import { z } from "zod";

import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { logger } from "../../lib/logger";
import { SendChatbotMessageInput } from "./chatbot.schema";
import { ChatbotProvider, VerifiedIncidentContext } from "./chatbot.provider";
import {
  ChatbotCatalogProduct,
  ChatbotRepository,
  OwnedOrderContext,
  OwnedPaymentContext,
} from "./chatbot.repository";
import {
  ChatbotAction,
  ChatbotHistoryResult,
  ChatbotMessageMetadata,
  SendChatbotMessageResult,
  SuggestedProduct,
} from "./chatbot.types";

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
    const catalogProducts = await repository.listCatalogProducts(50);
    const history = input.conversationId
      ? await repository.findRecentMessages(input.conversationId, 12)
      : [];

    // Giữ slot trước khi gọi Gemini để chặn gửi trùng giữa nhiều instance backend.
    const acquired = await repository.tryAcquireSendSlot(
      userId,
      this.options.rateLimitMs,
      this.options.sendLeaseMs
    );
    if (!acquired) {
      throw new AppError(429, ErrorCodes.CHATBOT_RATE_LIMITED, "Bạn đang gửi tin nhắn quá nhanh.");
    }

    try {
      const providerResult = await this.options.provider.generate({
        message: input.message,
        history: history.map(({ role, content }) => ({ role, content })),
        catalogProducts: catalogProducts.map(({ id, name, description, price }) => ({
          id,
          name,
          description,
          price,
        })),
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

      const suggestedProducts = this.resolveSuggestions(providerResult.suggestedProductIds, catalogProducts);
      const action = providerResult.actionDraft
        ? this.buildIncidentAction(conversationId, providerResult.actionDraft, incidentContext)
        : null;
      const assistantMetadata: ChatbotMessageMetadata = { suggestedProducts, action };
      const exchange = await repository.createExchange({
        conversationId,
        createConversation,
        userId,
        title: createConversation ? input.message.slice(0, 80) : null,
        userMessage: input.message,
        assistantReply: providerResult.reply,
        assistantMetadata,
      });

      return {
        conversationId: exchange.conversationId,
        messageId: exchange.assistantMessageId,
        reply: providerResult.reply,
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
