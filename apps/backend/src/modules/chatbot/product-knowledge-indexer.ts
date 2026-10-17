import { createHash } from "node:crypto";

import { EmbeddingProvider } from "./embedding.provider";
import {
  buildContextualChunk,
  ChunkOptions,
  chunkProductDescription,
} from "./product-knowledge";

export interface ProductKnowledgeSource {
  id: string;
  name: string;
  description: string | null;
  categoryName: string;
}

export interface ProductKnowledgeRow {
  productId: string;
  chunkIndex: number;
  content: string;
  sourceHash: string;
  embeddingModel: string;
  embedding: number[];
}

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

export interface ReindexSummary {
  productsRead: number;
  productsIndexed: number;
  chunksIndexed: number;
}

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
