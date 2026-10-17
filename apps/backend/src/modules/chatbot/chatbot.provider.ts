export interface ChatbotProviderProduct {
  id: string;
  name: string;
  description: string | null;
  price: string;
}

export interface ChatbotProviderMessage {
  role: "USER" | "ASSISTANT";
  content: string;
}

export interface ChatbotProviderKnowledgeChunk {
  productId: string;
  productName: string;
  content: string;
  score: number;
}

export type ChatbotResponseType =
  | "ANSWER"
  | "INCIDENT"
  | "IDENTITY"
  | "TRANSLATION"
  | "OFF_TOPIC"
  | "NO_KNOWLEDGE";

export interface VerifiedIncidentContext {
  orderId: string | null;
  orderNumber: string | null;
  orderStatus: string | null;
  paymentId: string | null;
  paymentStatus: string | null;
  source: string | null;
}

export interface ProviderIncidentDraft {
  category: string;
  title: string;
  description: string;
}

export interface ChatbotProviderInput {
  message: string;
  history: ChatbotProviderMessage[];
  catalogProducts: ChatbotProviderProduct[];
  knowledgeChunks: ChatbotProviderKnowledgeChunk[];
  contextProduct: ChatbotProviderProduct | null;
  incidentContext: VerifiedIncidentContext | null;
}

export interface ChatbotProviderResult {
  responseType: ChatbotResponseType;
  reply: string;
  suggestedProductIds: string[];
  actionDraft: ProviderIncidentDraft | null;
}

export interface ChatbotProvider {
  generate(input: ChatbotProviderInput, signal?: AbortSignal): Promise<ChatbotProviderResult>;
}
