/**
 * Số chiều vector; phải khớp cột vector(768) trong database.
 */
export const RAG_EMBEDDING_DIMENSIONS = 768;

/**
 * Interface biến text thành vector để tìm kiếm theo ngữ nghĩa.
 * - embedDocument: dùng khi reindex mô tả sản phẩm.
 * - embedQuery: dùng cho câu hỏi của người dùng lúc chat.
 * Hai loại tách riêng vì model embedding cho kết quả tốt hơn khi biết đâu là tài liệu, đâu là câu hỏi.
 */
export interface EmbeddingProvider {
  embedDocument(text: string, title?: string, signal?: AbortSignal): Promise<number[]>;
  embedQuery(text: string, signal?: AbortSignal): Promise<number[]>;
}
