import { ChatbotMessageMetadata } from "./chatbot.types";

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

export interface ChatbotRepositorySession {
  findOwnedConversation(id: string, userId: string): Promise<ChatbotConversationRecord | null>;
  findRecentMessages(conversationId: string, limit: number): Promise<StoredChatbotMessage[]>;
  findProductById(id: string): Promise<ChatbotCatalogProduct | null>;
  listCatalogProducts(limit: number): Promise<ChatbotCatalogProduct[]>;
  findOwnedOrder(userId: string, id: string): Promise<OwnedOrderContext | null>;
  findOwnedPayment(userId: string, id: string): Promise<OwnedPaymentContext | null>;
  findLastUserMessageAt(userId: string): Promise<Date | null>;
  createExchange(input: ChatbotExchangeInput): Promise<ChatbotExchangeResult>;
}

export interface ChatbotRepository {
  withUserSendLock<T>(userId: string, work: (session: ChatbotRepositorySession) => Promise<T>): Promise<T>;
  findOwnedConversation(id: string, userId: string): Promise<ChatbotConversationRecord | null>;
  getMessages(conversationId: string, page: number, pageSize: number): Promise<ChatbotHistoryPage>;
  deleteOwnedConversation(conversationId: string, userId: string): Promise<boolean>;
}
