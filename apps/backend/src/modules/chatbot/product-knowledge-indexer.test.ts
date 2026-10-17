import assert from "node:assert/strict";
import { describe, test } from "node:test";

import { EmbeddingProvider } from "./embedding.provider";
import {
  ProductKnowledgeIndexStore,
  ProductKnowledgeRow,
  reindexProductKnowledge,
} from "./product-knowledge-indexer";

class FakeEmbeddingProvider implements EmbeddingProvider {
  calls: Array<{ text: string; title?: string }> = [];
  failAtCall: number | null = null;

  async embedDocument(text: string, title?: string): Promise<number[]> {
    this.calls.push({ text, title });
    if (this.failAtCall === this.calls.length) throw new Error("embedding failed");
    return [this.calls.length, 0.5];
  }

  async embedQuery(): Promise<number[]> {
    throw new Error("not used by reindex");
  }
}

class FakeStore implements ProductKnowledgeIndexStore {
  rows: ProductKnowledgeRow[] = [];
  replaceCalls = 0;

  constructor(
    private readonly products = [
      {
        id: "11111111-1111-4111-8111-111111111111",
        name: "Cây Lưỡi Hổ",
        description: "Cây chịu được ánh sáng yếu. Chỉ tưới khi đất đã khô.",
        categoryName: "Cây cảnh",
      },
      {
        id: "22222222-2222-4222-8222-222222222222",
        name: "Sản phẩm thiếu mô tả",
        description: null,
        categoryName: "Cây cảnh",
      },
    ]
  ) {}

  async listProducts() {
    return this.products;
  }

  async replaceAll(rows: ProductKnowledgeRow[]): Promise<void> {
    this.replaceCalls += 1;
    this.rows = rows;
  }
}

describe("reindexProductKnowledge", () => {
  test("creates contextual, hashed chunks and skips products without descriptions", async () => {
    const store = new FakeStore();
    const embeddingProvider = new FakeEmbeddingProvider();

    const summary = await reindexProductKnowledge({
      store,
      embeddingProvider,
      embeddingModel: "embedding-test",
      chunkOptions: { maxWords: 7, overlapWords: 3 },
    });

    assert.deepEqual(summary, { productsRead: 2, productsIndexed: 1, chunksIndexed: 2 });
    assert.equal(store.replaceCalls, 1);
    assert.equal(store.rows.length, 2);
    assert.equal(store.rows[0]?.chunkIndex, 0);
    assert.match(store.rows[0]?.content ?? "", /Tên sản phẩm: Cây Lưỡi Hổ/u);
    assert.match(store.rows[0]?.content ?? "", /Danh mục: Cây cảnh/u);
    assert.match(store.rows[0]?.sourceHash ?? "", /^[a-f0-9]{64}$/u);
    assert.equal(store.rows[0]?.embeddingModel, "embedding-test");
    assert.deepEqual(store.rows[0]?.embedding, [1, 0.5]);
    assert.equal(embeddingProvider.calls[0]?.title, "Cây Lưỡi Hổ");
  });

  test("does not replace the current index when any embedding fails", async () => {
    const store = new FakeStore([
      {
        id: "11111111-1111-4111-8111-111111111111",
        name: "Cây thứ nhất",
        description: "Mô tả thứ nhất.",
        categoryName: "Cây cảnh",
      },
      {
        id: "22222222-2222-4222-8222-222222222222",
        name: "Cây thứ hai",
        description: "Mô tả thứ hai.",
        categoryName: "Cây cảnh",
      },
    ]);
    const embeddingProvider = new FakeEmbeddingProvider();
    embeddingProvider.failAtCall = 2;

    await assert.rejects(
      reindexProductKnowledge({ store, embeddingProvider, embeddingModel: "embedding-test" }),
      /embedding failed/u
    );
    assert.equal(store.replaceCalls, 0);
    assert.deepEqual(store.rows, []);
  });
});
