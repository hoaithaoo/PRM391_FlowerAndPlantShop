export interface SuggestedProduct {
  id: string;
  name: string;
  price: string;
  imageUrl: string | null;
}

export interface IncidentDraft {
  category: string;
  title: string;
  description: string;
  orderId: string | null;
  paymentId: string | null;
}

export interface ChatbotAction {
  type: "OPEN_INCIDENT_REPORT";
  draft: IncidentDraft & { conversationId: string };
}

export interface ChatbotMessageMetadata {
  suggestedProducts: SuggestedProduct[];
  action: ChatbotAction | null;
}

export interface SendChatbotMessageResult {
  conversationId: string;
  messageId: string;
  reply: string;
  suggestedProducts: SuggestedProduct[];
  action: ChatbotAction | null;
  createdAt: string;
}

export interface HistoryMessage {
  id: string;
  role: "USER" | "ASSISTANT";
  content: string;
  suggestedProducts: SuggestedProduct[];
  action: ChatbotAction | null;
  createdAt: string;
}

export interface ChatbotHistoryResult {
  conversation: { id: string; title: string | null };
  items: HistoryMessage[];
  page: number;
  pageSize: number;
  total: number;
  totalPages: number;
}
