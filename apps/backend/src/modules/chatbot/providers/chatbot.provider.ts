/**
 * Sản phẩm được phép đưa cho AI; AI chỉ được gợi ý các id trong danh sách này.
 */
export interface ChatbotProviderProduct {
  id: string;
  name: string;
  description: string | null;
  price: string;
}

/**
 * Một lượt hội thoại trước đó gửi kèm cho AI làm ngữ cảnh.
 */
export interface ChatbotProviderMessage {
  role: "USER" | "ASSISTANT";
  content: string;
}

/**
 * Đoạn mô tả sản phẩm tìm được bằng RAG, kèm điểm xếp hạng.
 */
export interface ChatbotProviderKnowledgeChunk {
  productId: string;
  productName: string;
  content: string;
  score: number;
}

/**
 * AI phân loại câu trả lời để server áp quy tắc an toàn:
 * ANSWER tư vấn sản phẩm, INCIDENT hỗ trợ báo sự cố, IDENTITY hỏi bot là ai,
 * TRANSLATION dịch câu trước, OFF_TOPIC ngoài phạm vi, NO_KNOWLEDGE thiếu dữ liệu.
 */
export type ChatbotResponseType =
  | "ANSWER"
  | "INCIDENT"
  | "IDENTITY"
  | "TRANSLATION"
  | "OFF_TOPIC"
  | "NO_KNOWLEDGE";

/**
 * Đơn hàng/thanh toán đã kiểm tra thuộc về user, dùng làm ngữ cảnh báo sự cố.
 */
export interface VerifiedIncidentContext {
  orderId: string | null;
  orderNumber: string | null;
  orderStatus: string | null;
  paymentId: string | null;
  paymentStatus: string | null;
  source: string | null;
}

/**
 * Bản nháp báo sự cố do AI đề xuất (chưa gắn orderId/paymentId).
 */
export interface ProviderIncidentDraft {
  category: string;
  title: string;
  description: string;
}

/**
 * Toàn bộ dữ liệu gửi cho AI trong một lượt; chỉ gồm dữ liệu đã xác minh.
 */
export interface ChatbotProviderInput {
  message: string;
  history: ChatbotProviderMessage[];
  catalogProducts: ChatbotProviderProduct[];
  knowledgeChunks: ChatbotProviderKnowledgeChunk[];
  contextProduct: ChatbotProviderProduct | null;
  incidentContext: VerifiedIncidentContext | null;
}

/**
 * Kết quả có cấu trúc AI trả về (đã qua lọc an toàn của provider).
 */
export interface ChatbotProviderResult {
  responseType: ChatbotResponseType;
  reply: string;
  suggestedProductIds: string[];
  actionDraft: ProviderIncidentDraft | null;
}

/**
 * Interface cho dịch vụ AI sinh câu trả lời. Service chỉ biết interface này,
 * nên đổi nhà cung cấp AI chỉ cần viết class cài đặt mới.
 */
export interface ChatbotProvider {
  generate(input: ChatbotProviderInput, signal?: AbortSignal): Promise<ChatbotProviderResult>;
}
