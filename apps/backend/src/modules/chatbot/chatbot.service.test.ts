import assert from "node:assert/strict";
import { describe, test } from "node:test";

import { AppError } from "../../common/errors/app-error";
import {
  ChatbotProvider,
  ChatbotProviderInput,
  ChatbotProviderResult,
} from "./providers/chatbot.provider";
import {
  ChatbotCatalogProduct,
  ChatbotConversationRecord,
  ChatbotExchangeInput,
  ChatbotExchangeResult,
  ChatbotIncidentSummary,
  ChatbotKnowledgeChunk,
  ChatbotOrderSummary,
  ChatbotRepository,
  ChatbotStoreInfo,
  OwnedOrderContext,
  OwnedPaymentContext,
  SearchKnowledgeInput,
  StoredChatbotMessage,
} from "./repository/chatbot.repository";
import { ChatbotService } from "./chatbot.service";
import { EmbeddingProvider } from "./providers/embedding.provider";

const USER_ID = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
const OTHER_USER_ID = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";
const CONVERSATION_ID = "cccccccc-cccc-4ccc-8ccc-cccccccccccc";
const PRODUCT_ID = "dddddddd-dddd-4ddd-8ddd-dddddddddddd";
const RETRIEVED_PRODUCT_ID = "13131313-1313-4131-8131-131313131313";
const ORDER_ID = "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee";
const PAYMENT_ID = "ffffffff-ffff-4fff-8fff-ffffffffffff";
const ASSISTANT_MESSAGE_ID = "12121212-1212-4121-8121-121212121212";
const NOW = new Date("2026-10-15T10:00:00.000Z");

class FakeProvider implements ChatbotProvider {
  calls: ChatbotProviderInput[] = [];

  constructor(
    private readonly result: ChatbotProviderResult = {
      responseType: "ANSWER",
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
  knowledgeChunks: ChatbotKnowledgeChunk[] = [];
  searchRequests: SearchKnowledgeInput[] = [];
  orderSummaries: Array<ChatbotOrderSummary & { userId: string }> = [];
  incidentSummaries: Array<ChatbotIncidentSummary & { userId: string }> = [];
  incidentFailure: Error | null = null;
  stores: ChatbotStoreInfo[] = [];
  storeFailure: Error | null = null;

  async listActiveStores(): Promise<ChatbotStoreInfo[]> {
    if (this.storeFailure) throw this.storeFailure;
    return this.stores;
  }

  faqs: Array<{ topic: string; answer: string }> = [];
  faqFailure: Error | null = null;

  async listActiveFaqs() {
    if (this.faqFailure) throw this.faqFailure;
    return this.faqs;
  }

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

  async searchKnowledge(input: SearchKnowledgeInput) {
    this.searchRequests.push(input);
    return this.knowledgeChunks;
  }

  async findOwnedOrder(userId: string, id: string): Promise<OwnedOrderContext | null> {
    const order = this.orders.get(id);
    return order?.userId === userId ? order : null;
  }

  async findOwnedPayment(userId: string, id: string): Promise<OwnedPaymentContext | null> {
    const payment = this.payments.get(id);
    return payment?.userId === userId ? payment : null;
  }

  async listOwnedOrders(userId: string, orderNumbers: string[], limit: number): Promise<ChatbotOrderSummary[]> {
    const owned = this.orderSummaries.filter((order) => order.userId === userId);
    return owned.filter((order, index) => index < limit || orderNumbers.includes(order.orderNumber))
      .map(({ userId: _owner, ...order }) => order);
  }

  async listOwnedIncidents(userId: string, codes: string[], limit: number): Promise<ChatbotIncidentSummary[]> {
    if (this.incidentFailure) throw this.incidentFailure;
    const owned = this.incidentSummaries.filter((incident) => incident.userId === userId);
    return owned.filter((incident, index) => index < limit || codes.includes(incident.code))
      .map(({ userId: _owner, ...incident }) => incident);
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

  async listOwnedConversations(userId: string) {
    const items = [...this.conversations.values()]
      .filter((conversation) => conversation.userId === userId)
      .map(({ id, title }) => ({ id, title, updatedAt: NOW }));
    return { items, total: items.length };
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
    this.resolveResult({
      responseType: "ANSWER",
      reply: "Xong",
      suggestedProductIds: [],
      actionDraft: null,
    });
  }
}

class FakeEmbeddingProvider implements EmbeddingProvider {
  queries: string[] = [];
  failure: Error | null = null;

  async embedDocument(): Promise<number[]> {
    throw new Error("not used while sending a message");
  }

  async embedQuery(text: string): Promise<number[]> {
    this.queries.push(text);
    if (this.failure) throw this.failure;
    return Array.from({ length: 768 }, () => 0.01);
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

function service(
  repository: FakeRepository,
  provider: ChatbotProvider,
  embeddingProvider: EmbeddingProvider = new FakeEmbeddingProvider()
): ChatbotService {
  return new ChatbotService({
    repository,
    provider,
    embeddingProvider,
    embeddingModel: "embedding-test",
    minSemanticScore: 0.55,
    rateLimitMs: 1000,
    sendLeaseMs: 25_000,
    newId: () => CONVERSATION_ID,
  });
}

describe("ChatbotService.listConversations", () => {
  test("returns only the user's conversations", async () => {
    const repository = new FakeRepository();
    repository.conversations.set(CONVERSATION_ID, { id: CONVERSATION_ID, userId: USER_ID, title: "Hoa" });
    repository.conversations.set("other", { id: "other", userId: "other-user", title: "Khác" });

    const result = await service(repository, new FakeProvider()).listConversations(USER_ID, 1);

    assert.deepEqual(result.items, [
      { id: CONVERSATION_ID, title: "Hoa", updatedAt: NOW.toISOString() },
    ]);
    assert.equal(result.total, 1);
  });
});

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

  test("can answer from verified selected-product facts even when description is empty", async () => {
    const repository = new FakeRepository();
    repository.products = [product({ description: null })];
    const provider = new FakeProvider({
      responseType: "ANSWER",
      reply: "Sản phẩm này có giá 120.000 đồng.",
      suggestedProductIds: [PRODUCT_ID],
      actionDraft: null,
    });

    const result = await service(repository, provider).sendMessage(USER_ID, {
      message: "Sản phẩm này giá bao nhiêu?",
      productId: PRODUCT_ID,
    });

    assert.equal(result.reply, "Sản phẩm này có giá 120.000 đồng.");
    assert.deepEqual(result.suggestedProducts.map((item) => item.id), [PRODUCT_ID]);
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
      responseType: "INCIDENT",
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

  test("passes the user's own orders and incidents and links a typed order number to the incident draft", async () => {
    const repository = new FakeRepository();
    const order = {
      id: ORDER_ID,
      orderNumber: "ORD-20261111-ABCDEF123456",
      status: "SHIPPING",
      paymentMethod: "COD",
      invoiceStatus: "ISSUED",
      totalAmount: "250000",
      isPickup: false,
      items: [{ name: "Bó hồng", quantity: 1 }],
      createdAt: NOW,
      completedAt: null,
      cancelledAt: null,
    };
    repository.orderSummaries = [
      { ...order, userId: USER_ID },
      { ...order, id: PAYMENT_ID, orderNumber: "ORD-20261111-000000000000", userId: OTHER_USER_ID },
    ];
    repository.incidentSummaries = [
      {
        userId: USER_ID,
        code: "SC-20261111-A1B2C3",
        category: "DELIVERY",
        title: "Giao trễ",
        status: "IN_PROGRESS",
        adminNote: "Đang liên hệ shipper",
        orderNumber: order.orderNumber,
        createdAt: NOW,
        resolvedAt: null,
      },
    ];
    const provider = new FakeProvider({
      responseType: "INCIDENT",
      reply: "Mình đã soạn phiếu cho đơn này.",
      suggestedProductIds: [],
      actionDraft: { category: "DELIVERY", title: "Giao trễ", description: "Chưa nhận hàng." },
    });

    const result = await service(repository, provider).sendMessage(USER_ID, {
      message: "đơn ord-20261111-abcdef123456 giao trễ quá",
    });

    const input = provider.calls[0]!;
    assert.deepEqual(input.customerOrders?.map((o) => o.orderNumber), [order.orderNumber]);
    assert.equal(input.customerOrders?.[0]?.createdAt, NOW.toISOString());
    assert.equal(input.incidentReports?.[0]?.adminNote, "Đang liên hệ shipper");
    assert.equal(input.incidentContext?.orderId, ORDER_ID);
    assert.equal(input.incidentContext?.source, "CHAT_MESSAGE");
    assert.equal(result.action?.draft.orderId, ORDER_ID);
    assert.equal(result.reply, "Mình đã soạn phiếu cho đơn này.");
  });

  test("ACCOUNT reply without any order or incident data is replaced", async () => {
    const repository = new FakeRepository();
    repository.incidentFailure = new Error("relation incident_reports does not exist");
    const provider = new FakeProvider({
      responseType: "ACCOUNT",
      reply: "Đơn của bạn đang được giao.",
      suggestedProductIds: [],
      actionDraft: null,
    });

    const result = await service(repository, provider).sendMessage(USER_ID, { message: "đơn của tôi tới đâu rồi" });

    assert.match(result.reply, /chưa thấy đơn hàng/u);
    assert.equal(result.action, null);
  });

  test("drafts an incident without order context but replaces the unverified reply", async () => {
    const repository = new FakeRepository();
    const provider = new FakeProvider({
      responseType: "INCIDENT",
      reply: "Đơn của bạn đã được hoàn tiền.",
      suggestedProductIds: [],
      actionDraft: { category: "hoa-bi-heo", title: "Hoa bị héo", description: "Hoa nhận về đã héo." },
    });

    const result = await service(repository, provider).sendMessage(USER_ID, { message: "Hoa tôi nhận bị héo" });

    assert.doesNotMatch(result.reply, /hoàn tiền/u);
    assert.deepEqual(result.action?.draft, {
      category: "OTHER",
      title: "Hoa bị héo",
      description: "Hoa nhận về đã héo.",
      orderId: null,
      paymentId: null,
      conversationId: CONVERSATION_ID,
    });
  });

  test("retrieves knowledge before generation and exposes only retrieved products", async () => {
    const repository = new FakeRepository();
    repository.knowledgeChunks = [
      {
        productId: RETRIEVED_PRODUCT_ID,
        productName: "Cây Kim Tiền",
        content: "Cây Kim Tiền phù hợp ánh sáng gián tiếp.",
        price: "250000",
        imageUrl: null,
        stock: 4,
        score: 0.031,
      },
    ];
    const embeddingProvider = new FakeEmbeddingProvider();
    const provider = new FakeProvider({
      responseType: "ANSWER",
      reply: "Bạn có thể tham khảo Cây Kim Tiền.",
      suggestedProductIds: [RETRIEVED_PRODUCT_ID, PRODUCT_ID],
      actionDraft: null,
    });

    const result = await service(repository, provider, embeddingProvider).sendMessage(USER_ID, {
      message: "Tìm cây để bàn dưới 300k",
    });

    assert.deepEqual(embeddingProvider.queries, ["Tìm cây để bàn dưới 300k"]);
    assert.equal(repository.searchRequests[0]?.query, "Tìm cây để bàn");
    assert.equal(repository.searchRequests[0]?.embeddingModel, "embedding-test");
    assert.equal(repository.searchRequests[0]?.filters.maxPrice, 300_000);
    assert.deepEqual(provider.calls[0]?.knowledgeChunks, [
      {
        productId: RETRIEVED_PRODUCT_ID,
        productName: "Cây Kim Tiền",
        content: "Cây Kim Tiền phù hợp ánh sáng gián tiếp.",
        score: 0.031,
      },
    ]);
    assert.deepEqual(provider.calls[0]?.catalogProducts.map((item) => item.id), [RETRIEVED_PRODUCT_ID]);
    assert.deepEqual(result.suggestedProducts.map((item) => item.id), [RETRIEVED_PRODUCT_ID]);
  });

  test("falls back to keyword retrieval when query embedding fails", async () => {
    const repository = new FakeRepository();
    const embeddingProvider = new FakeEmbeddingProvider();
    embeddingProvider.failure = new Error("embedding unavailable");

    await service(repository, new FakeProvider(), embeddingProvider).sendMessage(USER_ID, {
      message: "Cây lưỡi hổ",
    });

    assert.equal(repository.searchRequests.length, 1);
    assert.equal(repository.searchRequests[0]?.embedding, null);
  });

  test("clears product cards and actions for a non-answer response", async () => {
    const repository = new FakeRepository();
    repository.knowledgeChunks = [
      {
        productId: RETRIEVED_PRODUCT_ID,
        productName: "Cây Kim Tiền",
        content: "Cây Kim Tiền phù hợp ánh sáng gián tiếp.",
        price: "250000",
        imageUrl: null,
        stock: 4,
        score: 0.031,
      },
    ];
    const provider = new FakeProvider({
      responseType: "OFF_TOPIC",
      reply: "Tôi chỉ hỗ trợ nội dung cửa hàng.",
      suggestedProductIds: [RETRIEVED_PRODUCT_ID],
      actionDraft: {
        category: "OTHER",
        title: "Không được giữ",
        description: "Không được giữ",
      },
    });

    const result = await service(repository, provider).sendMessage(USER_ID, {
      message: "Viết code sắp xếp",
    });

    assert.deepEqual(result.suggestedProducts, []);
    assert.equal(result.action, null);
  });

  test("replaces an ungrounded answer when retrieval found no verified knowledge", async () => {
    const repository = new FakeRepository();
    const provider = new FakeProvider({
      responseType: "ANSWER",
      reply: "Cây tưởng tượng này chắc chắn phù hợp.",
      suggestedProductIds: [],
      actionDraft: null,
    });

    const result = await service(repository, provider).sendMessage(USER_ID, {
      message: "Cây nào sống được trong phòng hoàn toàn tối?",
    });

    assert.equal(
      result.reply,
      "Hiện tại dữ liệu đã xác minh của cửa hàng chưa có đủ thông tin để trả lời câu hỏi này."
    );
    assert.equal(repository.exchanges[0]?.assistantReply, result.reply);
  });

  test("keeps the no-knowledge fallback in English for an English message containing 's'", async () => {
    const repository = new FakeRepository();
    const provider = new FakeProvider({
      responseType: "ANSWER",
      reply: "This imaginary plant suits you.",
      suggestedProductIds: [],
      actionDraft: null,
    });

    const result = await service(repository, provider).sendMessage(USER_ID, {
      message: "Which plants survive in a dark room?",
    });

    assert.equal(
      result.reply,
      "The store's verified data does not currently contain enough information to answer that question."
    );
  });

  test("does not let unrelated incident context bypass catalog grounding", async () => {
    const repository = new FakeRepository();
    repository.orders.set(ORDER_ID, {
      id: ORDER_ID,
      userId: USER_ID,
      orderNumber: "ORD-1001",
      status: "PENDING",
    });
    const provider = new FakeProvider({
      responseType: "ANSWER",
      reply: "Cây tưởng tượng này phù hợp.",
      suggestedProductIds: [],
      actionDraft: null,
    });

    const result = await service(repository, provider).sendMessage(USER_ID, {
      message: "Tư vấn cây cho phòng tối",
      context: { orderId: ORDER_ID },
    });

    assert.equal(
      result.reply,
      "Hiện tại dữ liệu đã xác minh của cửa hàng chưa có đủ thông tin để trả lời câu hỏi này."
    );
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

  test("answers store FAQ from store data even with an empty product catalog", async () => {
    const repository = new FakeRepository();
    repository.stores = [{ name: "Nhà Có Hoa Q1", address: "1 Lê Lợi", phone: "0900000000", openingHours: "8:00-21:00" }];
    const provider = new FakeProvider({
      responseType: "FAQ",
      reply: "Phí giao trong 2 km là 15.000đ.",
      suggestedProductIds: [PRODUCT_ID],
      actionDraft: null,
    });

    const result = await service(repository, provider).sendMessage(USER_ID, { message: "Phí ship bao nhiêu?" });

    assert.equal(result.reply, "Phí giao trong 2 km là 15.000đ.");
    assert.deepEqual(result.suggestedProducts, []);
    assert.deepEqual(provider.calls[0]?.stores, repository.stores);
  });

  test("still chats when stores cannot be loaded", async () => {
    const repository = new FakeRepository();
    repository.storeFailure = new Error("db down");
    const provider = new FakeProvider();

    await service(repository, provider).sendMessage(USER_ID, { message: "Cửa hàng ở đâu?" });

    assert.deepEqual(provider.calls[0]?.stores, []);
  });

  test("uses admin FAQ from the database when present", async () => {
    const repository = new FakeRepository();
    repository.faqs = [{ topic: "Đổi trả", answer: "Đổi trong 24 giờ nếu hoa héo." }];
    const provider = new FakeProvider();

    await service(repository, provider).sendMessage(USER_ID, { message: "Có đổi trả không?" });

    assert.deepEqual(provider.calls[0]?.storeFaq, repository.faqs);
  });

  test("still chats with no FAQ when the FAQ table cannot be read", async () => {
    const repository = new FakeRepository();
    repository.faqFailure = new Error('relation "store_faqs" does not exist');
    const provider = new FakeProvider();

    await service(repository, provider).sendMessage(USER_ID, { message: "Phí ship bao nhiêu?" });

    assert.deepEqual(provider.calls[0]?.storeFaq, []);
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
