import { ChatbotMessageMetadata } from "../chatbot.types";
import { ProductSearchFilters } from "../rag/product-search-query";

export interface ChatbotConversationRecord {
  id: string;
  userId: string;
  title: string | null;
}

export interface ChatbotCatalogProduct {
  id: string;
  name: string;
  description: string | null;
  price: string;
  imageUrl: string | null;
  isActive: boolean;
  stock: number;
}

export interface OwnedOrderContext {
  id: string;
  userId: string;
  orderNumber: string;
  status: string;
}

export interface OwnedPaymentContext {
  id: string;
  userId: string;
  status: string;
  orderId: string;
  orderNumber: string;
  orderStatus: string;
}

export interface StoredChatbotMessage {
  id: string;
  role: "USER" | "ASSISTANT";
  content: string;
  metadata: unknown;
  createdAt: Date;
}

export interface ChatbotExchangeInput {
  conversationId: string;
  createConversation: boolean;
  userId: string;
  title: string | null;
  userMessage: string;
  assistantReply: string;
  assistantMetadata: ChatbotMessageMetadata;
}

export interface ChatbotExchangeResult {
  conversationId: string;
  assistantMessageId: string;
  createdAt: Date;
}

export interface ChatbotHistoryPage {
  items: StoredChatbotMessage[];
  total: number;
}

export interface ChatbotKnowledgeChunk {
  productId: string;
  productName: string;
  content: string;
  price: string;
  imageUrl: string | null;
  stock: number;
  score: number;
}

export interface SearchKnowledgeInput {
  query: string;
  embedding: number[] | null;
  embeddingModel: string;
  filters: ProductSearchFilters;
  limit: number;
  minSemanticScore: number;
}

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
