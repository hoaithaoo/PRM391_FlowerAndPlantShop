import assert from "node:assert/strict";
import { describe, test } from "node:test";

import { AppError } from "../../common/errors/app-error";
import {
  ChatbotProvider,
  ChatbotProviderInput,
  ChatbotProviderResult,
} from "./chatbot.provider";
import {
  ChatbotCatalogProduct,
  ChatbotConversationRecord,
  ChatbotExchangeInput,
  ChatbotExchangeResult,
  ChatbotRepository,
  OwnedOrderContext,
  OwnedPaymentContext,
  StoredChatbotMessage,
} from "./chatbot.repository";
import { ChatbotService } from "./chatbot.service";

const USER_ID = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
const OTHER_USER_ID = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";
const CONVERSATION_ID = "cccccccc-cccc-4ccc-8ccc-cccccccccccc";
const PRODUCT_ID = "dddddddd-dddd-4ddd-8ddd-dddddddddddd";
const ORDER_ID = "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee";
const PAYMENT_ID = "ffffffff-ffff-4fff-8fff-ffffffffffff";
const ASSISTANT_MESSAGE_ID = "12121212-1212-4121-8121-121212121212";
const NOW = new Date("2026-10-15T10:00:00.000Z");

class FakeProvider implements ChatbotProvider {
  calls: ChatbotProviderInput[] = [];

  constructor(
    private readonly result: ChatbotProviderResult = {
      reply: "Bạn có thể tham khảo sản phẩm này.",
      suggestedProductIds: [PRODUCT_ID],
      actionDraft: null,
    }
  ) {}

  async generate(input: ChatbotProviderInput): Promise<ChatbotProviderResult> {
    this.calls.push(input);
    return this.result;
  }
}

class FakeRepository implements ChatbotRepository {
  conversations = new Map<string, ChatbotConversationRecord>();
  products: ChatbotCatalogProduct[] = [];
  orders = new Map<string, OwnedOrderContext>();
  payments = new Map<string, OwnedPaymentContext>();
  recentMessages: StoredChatbotMessage[] = [];
  exchanges: ChatbotExchangeInput[] = [];
  historyPage: { items: StoredChatbotMessage[]; total: number } = { items: [], total: 0 };
  historyRequests: Array<{ conversationId: string; page: number; pageSize: number }> = [];
  deleteCalls: Array<{ conversationId: string; userId: string }> = [];
  sendInFlight = false;
  lastFinishedAt: Date | null = null;
  databaseNow = NOW;

  async findOwnedConversation(id: string, userId: string): Promise<ChatbotConversationRecord | null> {
    const conversation = this.conversations.get(id);
    return conversation?.userId === userId ? conversation : null;
  }

  async findRecentMessages(): Promise<StoredChatbotMessage[]> {
    return this.recentMessages;
  }

  async findProductById(id: string): Promise<ChatbotCatalogProduct | null> {
    return this.products.find((product) => product.id === id) ?? null;
  }

  async listCatalogProducts(): Promise<ChatbotCatalogProduct[]> {
    return this.products.filter((product) => product.isActive && product.stock > 0);
  }

  async findOwnedOrder(userId: string, id: string): Promise<OwnedOrderContext | null> {
    const order = this.orders.get(id);
    return order?.userId === userId ? order : null;
  }

  async findOwnedPayment(userId: string, id: string): Promise<OwnedPaymentContext | null> {
    const payment = this.payments.get(id);
    return payment?.userId === userId ? payment : null;
  }

  async createExchange(input: ChatbotExchangeInput): Promise<ChatbotExchangeResult> {
    this.exchanges.push(input);
    if (input.createConversation) {
      this.conversations.set(input.conversationId, {
        id: input.conversationId,
        userId: input.userId,
        title: input.title,
      });
    }
    return {
      conversationId: input.conversationId,
      assistantMessageId: ASSISTANT_MESSAGE_ID,
      createdAt: NOW,
    };
  }

  async getMessages(conversationId: string, page: number, pageSize: number) {
    this.historyRequests.push({ conversationId, page, pageSize });
    return this.historyPage;
  }

  async deleteOwnedConversation(conversationId: string, userId: string): Promise<boolean> {
    this.deleteCalls.push({ conversationId, userId });
    const conversation = await this.findOwnedConversation(conversationId, userId);
    if (!conversation) return false;
    this.conversations.delete(conversationId);
    return true;
  }

  async tryAcquireSendSlot(_userId: string, rateLimitMs: number): Promise<boolean> {
    if (this.sendInFlight) return false;
    if (this.lastFinishedAt && this.databaseNow.getTime() - this.lastFinishedAt.getTime() < rateLimitMs) {
      return false;
    }
    this.sendInFlight = true;
    return true;
  }

  async releaseSendSlot(): Promise<void> {
    this.sendInFlight = false;
    this.lastFinishedAt = this.databaseNow;
  }
}

class BlockingProvider implements ChatbotProvider {
  calls: ChatbotProviderInput[] = [];
  private resolveResult!: (value: ChatbotProviderResult) => void;
  private readonly pending = new Promise<ChatbotProviderResult>((resolve) => {
    this.resolveResult = resolve;
  });

  async generate(input: ChatbotProviderInput): Promise<ChatbotProviderResult> {
    this.calls.push(input);
    return this.pending;
  }

  finish(): void {
    this.resolveResult({ reply: "Xong", suggestedProductIds: [], actionDraft: null });
  }
}

function product(overrides: Partial<ChatbotCatalogProduct> = {}): ChatbotCatalogProduct {
  return {
    id: PRODUCT_ID,
    name: "Cây Lưỡi Hổ Mini",
    description: "Cây chịu bóng",
    price: "120000",
    imageUrl: "https://example.com/plant.jpg",
    isActive: true,
    stock: 5,
    ...overrides,
  };
}

function service(repository: FakeRepository, provider: ChatbotProvider): ChatbotService {
  return new ChatbotService({
    repository,
    provider,
    rateLimitMs: 1000,
    sendLeaseMs: 25_000,
    newId: () => CONVERSATION_ID,
  });
}

describe("ChatbotService.sendMessage", () => {
  test("creates a conversation and persists DB-backed product cards in assistant metadata", async () => {
    const repository = new FakeRepository();
    repository.products = [product()];
    const provider = new FakeProvider();

    const result = await service(repository, provider).sendMessage(USER_ID, {
      message: "Tư vấn cây để bàn",
      productId: PRODUCT_ID,
    });

    assert.equal(result.conversationId, CONVERSATION_ID);
    assert.equal(result.messageId, ASSISTANT_MESSAGE_ID);
    assert.deepEqual(result.suggestedProducts, [
      {
        id: PRODUCT_ID,
        name: "Cây Lưỡi Hổ Mini",
        price: "120000",
        imageUrl: "https://example.com/plant.jpg",
      },
    ]);
    assert.equal(repository.exchanges[0]?.title, "Tư vấn cây để bàn");
    assert.deepEqual(repository.exchanges[0]?.assistantMetadata.suggestedProducts, result.suggestedProducts);
    assert.deepEqual(provider.calls[0]?.contextProduct, {
      id: PRODUCT_ID,
      name: "Cây Lưỡi Hổ Mini",
      description: "Cây chịu bóng",
      price: "120000",
    });
  });

  test("rejects a missing or foreign conversation before calling the provider", async () => {
    const repository = new FakeRepository();
    repository.conversations.set(CONVERSATION_ID, {
      id: CONVERSATION_ID,
      userId: OTHER_USER_ID,
      title: "Foreign",
    });
    const provider = new FakeProvider();

    await assert.rejects(
      service(repository, provider).sendMessage(USER_ID, {
        conversationId: CONVERSATION_ID,
        message: "Xin chào",
      }),
      (error: unknown) => error instanceof AppError && error.code === "CHATBOT_CONVERSATION_NOT_FOUND"
    );
    assert.equal(provider.calls.length, 0);
  });

  test("rejects unverified product, order, and payment context before calling the provider", async () => {
    const cases = [
      { message: "product", productId: PRODUCT_ID },
      { message: "order", context: { orderId: ORDER_ID } },
      { message: "payment", context: { paymentId: PAYMENT_ID } },
    ];

    for (const input of cases) {
      const repository = new FakeRepository();
      const provider = new FakeProvider();
      await assert.rejects(service(repository, provider).sendMessage(USER_ID, input));
      assert.equal(provider.calls.length, 0);
      assert.equal(repository.exchanges.length, 0);
    }
  });

  test("uses only owned order/payment context in an editable incident action", async () => {
    const repository = new FakeRepository();
    repository.orders.set(ORDER_ID, {
      id: ORDER_ID,
      userId: USER_ID,
      orderNumber: "ORD-1001",
      status: "PENDING",
    });
    repository.payments.set(PAYMENT_ID, {
      id: PAYMENT_ID,
      userId: USER_ID,
      status: "FAILED",
      orderId: ORDER_ID,
      orderNumber: "ORD-1001",
      orderStatus: "PENDING",
    });
    const provider = new FakeProvider({
      reply: "Mình đã chuẩn bị form báo lỗi.",
      suggestedProductIds: [],
      actionDraft: {
        category: "PAYMENT",
        title: "Thanh toán thất bại",
        description: "Giao dịch chưa hoàn tất.",
      },
    });

    const result = await service(repository, provider).sendMessage(USER_ID, {
      message: "Thanh toán của tôi bị lỗi",
      context: { orderId: ORDER_ID, paymentId: PAYMENT_ID, source: "checkout" },
    });

    assert.deepEqual(provider.calls[0]?.incidentContext, {
      orderId: ORDER_ID,
      orderNumber: "ORD-1001",
      orderStatus: "PENDING",
      paymentId: PAYMENT_ID,
      paymentStatus: "FAILED",
      source: "checkout",
    });
    assert.deepEqual(result.action, {
      type: "OPEN_INCIDENT_REPORT",
      draft: {
        category: "PAYMENT",
        title: "Thanh toán thất bại",
        description: "Giao dịch chưa hoàn tất.",
        orderId: ORDER_ID,
        paymentId: PAYMENT_ID,
        conversationId: CONVERSATION_ID,
      },
    });
    assert.deepEqual(repository.exchanges[0]?.assistantMetadata.action, result.action);
  });

  test("rejects rapid messages while holding the per-user send lock", async () => {
    const repository = new FakeRepository();
    repository.lastFinishedAt = new Date(NOW.getTime() - 500);
    const provider = new FakeProvider();

    await assert.rejects(service(repository, provider).sendMessage(USER_ID, { message: "Lần hai" }), (error: unknown) => {
      return error instanceof AppError && error.statusCode === 429 && error.code === "CHATBOT_RATE_LIMITED";
    });
    assert.equal(provider.calls.length, 0);
  });

  test("rejects an overlapping send while the first provider call is still running", async () => {
    const repository = new FakeRepository();
    const provider = new BlockingProvider();
    const chatbot = service(repository, provider);

    const first = chatbot.sendMessage(USER_ID, { message: "Tin đầu" });
    while (provider.calls.length === 0) await new Promise((resolve) => setImmediate(resolve));

    const second = chatbot.sendMessage(USER_ID, { message: "Tin đồng thời" });
    const secondOutcome = await Promise.race([
      second.then(
        () => "resolved" as const,
        (error: unknown) => error
      ),
      new Promise<"pending">((resolve) => setTimeout(() => resolve("pending"), 20)),
    ]);
    provider.finish();
    await Promise.allSettled([first, second]);

    assert.equal(secondOutcome instanceof AppError && secondOutcome.code === "CHATBOT_RATE_LIMITED", true);
    assert.equal(provider.calls.length, 1);
  });

  test("keeps per-user cooldown state after deleting conversation history", async () => {
    const repository = new FakeRepository();
    const chatbot = service(repository, new FakeProvider());

    const first = await chatbot.sendMessage(USER_ID, { message: "Tin đầu" });
    await chatbot.deleteConversation(USER_ID, first.conversationId);

    await assert.rejects(chatbot.sendMessage(USER_ID, { message: "Tin ngay sau khi xóa" }), (error: unknown) => {
      return error instanceof AppError && error.code === "CHATBOT_RATE_LIMITED";
    });
  });
});

describe("ChatbotService history and deletion", () => {
  test("returns chronological messages and restores assistant metadata", async () => {
    const repository = new FakeRepository();
    repository.conversations.set(CONVERSATION_ID, {
      id: CONVERSATION_ID,
      userId: USER_ID,
      title: "Tư vấn cây",
    });
    repository.historyPage = {
      total: 22,
      items: [
        {
          id: "23232323-2323-4232-8232-232323232323",
          role: "USER",
          content: "Cho tôi xem cây này",
          metadata: null,
          createdAt: new Date("2026-10-15T09:00:00.000Z"),
        },
        {
          id: ASSISTANT_MESSAGE_ID,
          role: "ASSISTANT",
          content: "Đây là sản phẩm phù hợp.",
          metadata: {
            suggestedProducts: [
              {
                id: PRODUCT_ID,
                name: "Cây Lưỡi Hổ Mini",
                price: "120000",
                imageUrl: "https://example.com/plant.jpg",
              },
            ],
            action: null,
          },
          createdAt: NOW,
        },
      ],
    };

    const result = await service(repository, new FakeProvider()).getHistory(USER_ID, CONVERSATION_ID, 2);

    assert.deepEqual(repository.historyRequests, [{ conversationId: CONVERSATION_ID, page: 2, pageSize: 20 }]);
    assert.equal(result.conversation.title, "Tư vấn cây");
    assert.equal(result.items[0]?.role, "USER");
    assert.deepEqual(result.items[0]?.suggestedProducts, []);
    assert.deepEqual(result.items[1]?.suggestedProducts[0]?.id, PRODUCT_ID);
    assert.equal(result.page, 2);
    assert.equal(result.totalPages, 2);
  });

  test("returns the same not-found error for missing and foreign conversations", async () => {
    const repository = new FakeRepository();
    repository.conversations.set(CONVERSATION_ID, {
      id: CONVERSATION_ID,
      userId: OTHER_USER_ID,
      title: null,
    });
    const chatbot = service(repository, new FakeProvider());

    await assert.rejects(chatbot.getHistory(USER_ID, CONVERSATION_ID, 1), (error: unknown) => {
      return error instanceof AppError && error.code === "CHATBOT_CONVERSATION_NOT_FOUND";
    });
    await assert.rejects(chatbot.deleteConversation(USER_ID, CONVERSATION_ID), (error: unknown) => {
      return error instanceof AppError && error.code === "CHATBOT_CONVERSATION_NOT_FOUND";
    });
    assert.equal(repository.deleteCalls.length, 0);
  });

  test("deletes an owned conversation", async () => {
    const repository = new FakeRepository();
    repository.conversations.set(CONVERSATION_ID, {
      id: CONVERSATION_ID,
      userId: USER_ID,
      title: null,
    });

    await service(repository, new FakeProvider()).deleteConversation(USER_ID, CONVERSATION_ID);

    assert.deepEqual(repository.deleteCalls, [{ conversationId: CONVERSATION_ID, userId: USER_ID }]);
  });
});
