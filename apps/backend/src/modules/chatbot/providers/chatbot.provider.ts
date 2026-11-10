import type { ChatbotCartAction, ChatbotFavoriteAction } from "../chatbot.types";
import type { ChatbotStoreInfo, StoreFaqEntry } from "../repository/chatbot.repository";

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
 * TRANSLATION dịch câu trước, OFF_TOPIC ngoài phạm vi, NO_KNOWLEDGE thiếu dữ liệu,
 * CART xem hoặc thay đổi giỏ hàng của người dùng, ACCOUNT trả lời trạng thái đơn hàng/phiếu sự cố
 * của chính người dùng, FAQ trả lời chính sách/thông tin cửa hàng từ storeFaq và stores,
 * FAVORITE xem hoặc thay đổi danh sách sản phẩm yêu thích (nút trái tim) của người dùng.
 */
export type ChatbotResponseType =
  | "ANSWER"
  | "FAQ"
  | "CART"
  | "FAVORITE"
  | "ACCOUNT"
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
 * Một dòng trong giỏ hàng hiện tại của user.
 */
export interface ChatbotCartItem {
  productId: string;
  name: string;
  price: string;
  quantity: number;
}

/**
 * Một sản phẩm trong danh sách yêu thích client gửi lên (đã kiểm tra còn bán trong DB).
 */
export interface ChatbotFavoriteItem {
  productId: string;
  name: string;
  price: string;
}

/**
 * Đơn hàng của chính user (đơn gần đây + đơn user nhắc mã trong tin nhắn).
 */
export interface ChatbotProviderOrder {
  orderNumber: string;
  status: string;
  paymentMethod: string;
  invoiceStatus: string | null;
  totalAmount: string;
  isPickup: boolean;
  items: Array<{ name: string; quantity: number }>;
  createdAt: string;
  completedAt: string | null;
  cancelledAt: string | null;
}

/**
 * Phiếu báo sự cố của chính user, kèm ghi chú xử lý của admin.
 */
export interface ChatbotProviderIncident {
  code: string;
  category: string;
  title: string;
  status: string;
  adminNote: string | null;
  orderNumber: string | null;
  createdAt: string;
  resolvedAt: string | null;
}

/**
 * Toàn bộ dữ liệu gửi cho AI trong một lượt; chỉ gồm dữ liệu đã xác minh.
 */
export interface ChatbotProviderInput {
  cartItems?: ChatbotCartItem[];
  /** Sản phẩm yêu thích hiện tại của user. */
  favoriteItems?: ChatbotFavoriteItem[];
  customerOrders?: ChatbotProviderOrder[];
  incidentReports?: ChatbotProviderIncident[];
  /** Chính sách cửa hàng (phí giao, thanh toán, hủy đơn...) admin nhập trong bảng store_faqs. */
  storeFaq?: StoreFaqEntry[];
  /** Cửa hàng đang hoạt động: tên, địa chỉ, điện thoại, giờ mở cửa. */
  stores?: ChatbotStoreInfo[];
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
  cartActions?: ChatbotCartAction[];
  favoriteActions?: ChatbotFavoriteAction[];
}

/**
 * Interface cho dịch vụ AI sinh câu trả lời. Service chỉ biết interface này,
 * nên đổi nhà cung cấp AI chỉ cần viết class cài đặt mới.
 */
export interface ChatbotProvider {
  generate(input: ChatbotProviderInput, signal?: AbortSignal): Promise<ChatbotProviderResult>;
}
