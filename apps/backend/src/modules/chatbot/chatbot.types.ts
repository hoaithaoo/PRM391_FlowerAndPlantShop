/**
 * Product card trả cho client; dữ liệu lấy từ DB, không lấy từ AI.
 */
export interface SuggestedProduct {
  id: string;
  name: string;
  price: string;
  imageUrl: string | null;
}

/**
 * Bản nháp báo sự cố để client điền sẵn vào form; người dùng vẫn phải xác nhận.
 */
export interface IncidentDraft {
  category: string;
  title: string;
  description: string;
  orderId: string | null;
  paymentId: string | null;
}

/**
 * Hành động client cần làm sau câu trả lời; hiện chỉ có mở form báo sự cố.
 */
export interface ChatbotAction {
  type: "OPEN_INCIDENT_REPORT";
  draft: IncidentDraft & { conversationId: string };
}

/**
 * Phần đi kèm câu trả lời (gợi ý sản phẩm, action), lưu vào cột metadata của tin nhắn.
 */
export interface ChatbotMessageMetadata {
  suggestedProducts: SuggestedProduct[];
  action: ChatbotAction | null;
}

/**
 * Response của POST /messages.
 */
export interface SendChatbotMessageResult {
  conversationId: string;
  messageId: string;
  reply: string;
  suggestedProducts: SuggestedProduct[];
  action: ChatbotAction | null;
  createdAt: string;
}

/**
 * Một tin nhắn trong lịch sử (của user hoặc assistant).
 */
export interface HistoryMessage {
  id: string;
  role: "USER" | "ASSISTANT";
  content: string;
  suggestedProducts: SuggestedProduct[];
  action: ChatbotAction | null;
  createdAt: string;
}

/**
 * Response của GET lịch sử: danh sách tin nhắn + thông tin phân trang.
 */
export interface ChatbotHistoryResult {
  conversation: { id: string; title: string | null };
  items: HistoryMessage[];
  page: number;
  pageSize: number;
  total: number;
  totalPages: number;
}
