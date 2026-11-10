import { ChatbotMessageMetadata } from "../chatbot.types";
import { ProductSearchFilters } from "../rag/product-search-query";

/**
 * Conversation đã kiểm tra thuộc về user.
 */
export interface ChatbotConversationRecord {
  id: string;
  userId: string;
  title: string | null;
}

/**
 * Sản phẩm kèm giá, tồn kho, ảnh; nguồn dữ liệu thật cho product card.
 */
export interface ChatbotCatalogProduct {
  id: string;
  name: string;
  description: string | null;
  price: string;
  imageUrl: string | null;
  isActive: boolean;
  stock: number;
}

/**
 * Đơn hàng đã kiểm tra thuộc về user.
 */
export interface OwnedOrderContext {
  id: string;
  userId: string;
  orderNumber: string;
  status: string;
}

/**
 * Thanh toán đã kiểm tra thuộc về user, kèm trạng thái đơn hàng.
 */
export interface OwnedPaymentContext {
  id: string;
  userId: string;
  status: string;
  orderId: string;
  orderNumber: string;
  orderStatus: string;
}

/**
 * Tóm tắt đơn hàng của user để chatbot trả lời trạng thái đơn.
 */
export interface ChatbotOrderSummary {
  id: string;
  orderNumber: string;
  status: string;
  paymentMethod: string;
  invoiceStatus: string | null;
  totalAmount: string;
  isPickup: boolean;
  items: Array<{ name: string; quantity: number }>;
  createdAt: Date;
  completedAt: Date | null;
  cancelledAt: Date | null;
}

/**
 * Tóm tắt phiếu báo sự cố của user để chatbot trả lời tiến độ xử lý.
 */
export interface ChatbotIncidentSummary {
  code: string;
  category: string;
  title: string;
  status: string;
  adminNote: string | null;
  orderNumber: string | null;
  createdAt: Date;
  resolvedAt: Date | null;
}

/**
 * Tin nhắn đã lưu trong DB.
 */
export interface StoredChatbotMessage {
  id: string;
  role: "USER" | "ASSISTANT";
  content: string;
  metadata: unknown;
  createdAt: Date;
}

/**
 * Một lượt hỏi–đáp cần lưu (tin nhắn user + câu trả lời + metadata).
 */
export interface ChatbotExchangeInput {
  conversationId: string;
  createConversation: boolean;
  userId: string;
  title: string | null;
  userMessage: string;
  assistantReply: string;
  assistantMetadata: ChatbotMessageMetadata;
}

/**
 * Kết quả sau khi lưu lượt hỏi–đáp.
 */
export interface ChatbotExchangeResult {
  conversationId: string;
  assistantMessageId: string;
  createdAt: Date;
}

/**
 * Một trang lịch sử tin nhắn và tổng số tin nhắn.
 */
export interface ChatbotHistoryPage {
  items: StoredChatbotMessage[];
  total: number;
}

/**
 * Một trang danh sách phiên chat của user, mới cập nhật nhất trước.
 */
export interface ChatbotConversationPage {
  items: Array<{ id: string; title: string | null; updatedAt: Date }>;
  total: number;
}

/**
 * Kết quả tìm kiếm RAG: chunk mô tả kèm dữ liệu sản phẩm và điểm xếp hạng.
 */
export interface ChatbotKnowledgeChunk {
  productId: string;
  productName: string;
  content: string;
  price: string;
  imageUrl: string | null;
  stock: number;
  score: number;
}

/** Một câu FAQ admin nhập trong bảng store_faqs. */
export interface StoreFaqEntry {
  topic: string;
  answer: string;
}

export interface ChatbotStoreInfo {
  name: string;
  address: string;
  phone: string | null;
  openingHours: string | null;
}

/**
 * Tham số hybrid search: câu tìm kiếm, vector câu hỏi (null nếu embedding lỗi), bộ lọc giá,
 * số kết quả và ngưỡng điểm ngữ nghĩa tối thiểu.
 */
export interface SearchKnowledgeInput {
  query: string;
  embedding: number[] | null;
  embeddingModel: string;
  filters: ProductSearchFilters;
  limit: number;
  minSemanticScore: number;
}

/**
 * Interface truy cập dữ liệu mà ChatbotService cần: conversation, tin nhắn, sản phẩm,
 * đơn hàng/thanh toán, tìm kiếm RAG và slot chống spam. Các hàm findOwned* lọc theo userId.
 */
export interface ChatbotRepository {
  findOwnedConversation(id: string, userId: string): Promise<ChatbotConversationRecord | null>;
  findRecentMessages(conversationId: string, limit: number): Promise<StoredChatbotMessage[]>;
  findProductById(id: string): Promise<ChatbotCatalogProduct | null>;
  /** Lấy nhiều sản phẩm còn bán theo id (dùng cho danh sách yêu thích client gửi lên). */
  findProductsByIds(ids: string[]): Promise<ChatbotCatalogProduct[]>;
  listCatalogProducts(limit: number): Promise<ChatbotCatalogProduct[]>;
  searchKnowledge(input: SearchKnowledgeInput): Promise<ChatbotKnowledgeChunk[]>;
  findOwnedOrder(userId: string, id: string): Promise<OwnedOrderContext | null>;
  findOwnedPayment(userId: string, id: string): Promise<OwnedPaymentContext | null>;
  /** `limit` đơn mới nhất của user, cộng thêm các đơn của user có mã trong `orderNumbers`. */
  listOwnedOrders(userId: string, orderNumbers: string[], limit: number): Promise<ChatbotOrderSummary[]>;
  /** `limit` phiếu sự cố mới nhất của user, cộng thêm các phiếu của user có mã trong `codes`. */
  listOwnedIncidents(userId: string, codes: string[], limit: number): Promise<ChatbotIncidentSummary[]>;
  /** Cửa hàng đang hoạt động, cho câu hỏi địa chỉ/giờ mở cửa/số điện thoại. */
  listActiveStores(): Promise<ChatbotStoreInfo[]>;
  /** FAQ admin đang bật, theo sortOrder. */
  listActiveFaqs(): Promise<StoreFaqEntry[]>;
  createExchange(input: ChatbotExchangeInput): Promise<ChatbotExchangeResult>;
  tryAcquireSendSlot(userId: string, cooldownMs: number, leaseMs: number): Promise<boolean>;
  releaseSendSlot(userId: string): Promise<void>;
  getMessages(conversationId: string, page: number, pageSize: number): Promise<ChatbotHistoryPage>;
  listOwnedConversations(userId: string, page: number, pageSize: number): Promise<ChatbotConversationPage>;
  deleteOwnedConversation(conversationId: string, userId: string): Promise<boolean>;
}
