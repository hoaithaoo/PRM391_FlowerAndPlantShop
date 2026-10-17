import { createHash } from "node:crypto";

import { EmbeddingProvider } from "../providers/embedding.provider";
import {
  buildContextualChunk,
  ChunkOptions,
  chunkProductDescription,
} from "./product-knowledge";

/**
 * Sản phẩm đọc từ DB để lập chỉ mục.
 */
export interface ProductKnowledgeSource {
  id: string;
  name: string;
  description: string | null;
  categoryName: string;
}

/**
 * Một dòng chunk + embedding sẽ ghi vào bảng product_knowledge_chunks.
 */
export interface ProductKnowledgeRow {
  productId: string;
  chunkIndex: number;
  content: string;
  sourceHash: string;
  embeddingModel: string;
  embedding: number[];
}

/**
 * Nơi đọc sản phẩm và ghi chỉ mục. replaceAll xóa chỉ mục cũ và ghi chỉ mục mới trong cùng một transaction.
 */
export interface ProductKnowledgeIndexStore {
  listProducts(): Promise<ProductKnowledgeSource[]>;
  replaceAll(rows: ProductKnowledgeRow[]): Promise<void>;
}

interface ReindexDependencies {
  store: ProductKnowledgeIndexStore;
  embeddingProvider: EmbeddingProvider;
  embeddingModel: string;
  chunkOptions?: ChunkOptions;
}

/**
 * Thống kê sau khi reindex: số sản phẩm đã đọc, đã lập chỉ mục và số chunk.
 */
export interface ReindexSummary {
  productsRead: number;
  productsIndexed: number;
  chunksIndexed: number;
}

/**
 * Lập lại chỉ mục RAG cho toàn bộ sản phẩm: cắt mô tả thành chunk → tạo embedding → ghi DB.
 * Tạo xong mọi embedding rồi mới ghi, nên nếu dịch vụ embedding lỗi giữa chừng thì chỉ mục cũ
 * vẫn được giữ nguyên. Chạy bằng lệnh pnpm rag:reindex.
 */
export async function reindexProductKnowledge(
  dependencies: ReindexDependencies
): Promise<ReindexSummary> {
  const products = await dependencies.store.listProducts();
  const rows: ProductKnowledgeRow[] = [];
  let productsIndexed = 0;

  for (const product of products) {
    const chunks = chunkProductDescription(product.description ?? "", dependencies.chunkOptions);
    if (chunks.length === 0) continue;
    productsIndexed += 1;

    for (const [chunkIndex, chunk] of chunks.entries()) {
      const content = buildContextualChunk(
        {
          productId: product.id,
          productName: product.name,
          categoryName: product.categoryName,
        },
        chunk
      );
      const embedding = await dependencies.embeddingProvider.embedDocument(content, product.name);
      rows.push({
        productId: product.id,
        chunkIndex,
        content,
        sourceHash: createHash("sha256").update(content).digest("hex"),
        embeddingModel: dependencies.embeddingModel,
        embedding,
      });
    }
  }

  // Chỉ thay index sau khi mọi embedding đã thành công; lỗi giữa chừng không xóa dữ liệu RAG cũ.
  await dependencies.store.replaceAll(rows);

  return {
    productsRead: products.length,
    productsIndexed,
    chunksIndexed: rows.length,
  };
}
