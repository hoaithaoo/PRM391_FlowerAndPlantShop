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
  listCatalogProducts(limit: number): Promise<ChatbotCatalogProduct[]>;
  searchKnowledge(input: SearchKnowledgeInput): Promise<ChatbotKnowledgeChunk[]>;
  findOwnedOrder(userId: string, id: string): Promise<OwnedOrderContext | null>;
  findOwnedPayment(userId: string, id: string): Promise<OwnedPaymentContext | null>;
  createExchange(input: ChatbotExchangeInput): Promise<ChatbotExchangeResult>;
  tryAcquireSendSlot(userId: string, cooldownMs: number, leaseMs: number): Promise<boolean>;
  releaseSendSlot(userId: string): Promise<void>;
  getMessages(conversationId: string, page: number, pageSize: number): Promise<ChatbotHistoryPage>;
  deleteOwnedConversation(conversationId: string, userId: string): Promise<boolean>;
}
