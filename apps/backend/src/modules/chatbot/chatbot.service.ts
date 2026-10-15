import { randomUUID } from "node:crypto";

import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { SendChatbotMessageInput } from "./chatbot.schema";
import { ChatbotProvider, VerifiedIncidentContext } from "./chatbot.provider";
import {
  ChatbotCatalogProduct,
  ChatbotRepository,
  ChatbotRepositorySession,
  OwnedOrderContext,
  OwnedPaymentContext,
} from "./chatbot.repository";
import {
  ChatbotAction,
  ChatbotMessageMetadata,
  SendChatbotMessageResult,
  SuggestedProduct,
} from "./chatbot.types";

interface ChatbotServiceOptions {
  repository: ChatbotRepository;
  provider: ChatbotProvider;
  rateLimitMs: number;
  now?: () => Date;
  newId?: () => string;
}

export class ChatbotService {
  private readonly now: () => Date;
  private readonly newId: () => string;

  constructor(private readonly options: ChatbotServiceOptions) {
    this.now = options.now ?? (() => new Date());
    this.newId = options.newId ?? randomUUID;
  }

  async sendMessage(userId: string, input: SendChatbotMessageInput): Promise<SendChatbotMessageResult> {
    return this.options.repository.withUserSendLock(userId, async (session) => {
      const conversationId = input.conversationId ?? this.newId();
      const createConversation = !input.conversationId;

      if (input.conversationId) {
        const conversation = await session.findOwnedConversation(input.conversationId, userId);
        if (!conversation) {
          throw new AppError(
            404,
            ErrorCodes.CHATBOT_CONVERSATION_NOT_FOUND,
            "Không tìm thấy phiên chatbot."
          );
        }
      }

      await this.enforceRateLimit(session, userId);
      const contextProduct = await this.verifyProductContext(session, input.productId);
      const incidentContext = await this.verifyIncidentContext(session, userId, input.context);
      const catalogProducts = await session.listCatalogProducts(50);
      const history = input.conversationId
        ? await session.findRecentMessages(input.conversationId, 12)
        : [];

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
      const exchange = await session.createExchange({
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
    });
  }

  private async enforceRateLimit(session: ChatbotRepositorySession, userId: string): Promise<void> {
    const lastMessageAt = await session.findLastUserMessageAt(userId);
    if (lastMessageAt && this.now().getTime() - lastMessageAt.getTime() < this.options.rateLimitMs) {
      throw new AppError(429, ErrorCodes.CHATBOT_RATE_LIMITED, "Bạn đang gửi tin nhắn quá nhanh.");
    }
  }

  private async verifyProductContext(
    session: ChatbotRepositorySession,
    productId: string | null | undefined
  ): Promise<ChatbotCatalogProduct | null> {
    if (!productId) return null;
    const product = await session.findProductById(productId);
    if (!product) {
      throw new AppError(404, ErrorCodes.PRODUCT_NOT_FOUND, "Không tìm thấy sản phẩm.");
    }
    return product;
  }

  private async verifyIncidentContext(
    session: ChatbotRepositorySession,
    userId: string,
    context: SendChatbotMessageInput["context"]
  ): Promise<VerifiedIncidentContext | null> {
    if (!context) return null;

    let order: OwnedOrderContext | null = null;
    let payment: OwnedPaymentContext | null = null;
    if (context.orderId) {
      order = await session.findOwnedOrder(userId, context.orderId);
      if (!order) {
        throw new AppError(404, ErrorCodes.ORDER_NOT_FOUND, "Không tìm thấy đơn hàng.");
      }
    }
    if (context.paymentId) {
      payment = await session.findOwnedPayment(userId, context.paymentId);
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
}
