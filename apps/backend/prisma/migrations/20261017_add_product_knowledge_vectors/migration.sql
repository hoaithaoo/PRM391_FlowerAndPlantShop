-- Supabase installs extensions outside public; using the same schema locally keeps SQL portable.
CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA extensions;

CREATE TABLE "product_knowledge_chunks" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "product_id" UUID NOT NULL,
  "chunk_index" INTEGER NOT NULL,
  "content" TEXT NOT NULL,
  "source_hash" VARCHAR(64) NOT NULL,
  "embedding_model" TEXT NOT NULL,
  "embedding" extensions.vector(768) NOT NULL,
  "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "product_knowledge_chunks_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "product_knowledge_chunks_chunk_index_non_negative" CHECK ("chunk_index" >= 0),
  CONSTRAINT "product_knowledge_chunks_source_hash_length" CHECK (length("source_hash") = 64),
  CONSTRAINT "product_knowledge_chunks_embedding_model_non_empty" CHECK (length(trim("embedding_model")) > 0),
  CONSTRAINT "product_knowledge_chunks_product_id_fkey"
    FOREIGN KEY ("product_id") REFERENCES "products"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX "product_knowledge_chunks_product_id_chunk_index_key"
  ON "product_knowledge_chunks"("product_id", "chunk_index");
CREATE INDEX "product_knowledge_chunks_product_id_idx"
  ON "product_knowledge_chunks"("product_id");

-- FTS giữ lợi thế cho tên/mã chính xác; vector xử lý câu hỏi cùng nghĩa hoặc khác ngôn ngữ.
CREATE INDEX "product_knowledge_chunks_content_fts_idx"
  ON "product_knowledge_chunks" USING GIN (to_tsvector('simple', "content"));
CREATE INDEX "product_knowledge_chunks_embedding_hnsw_idx"
  ON "product_knowledge_chunks" USING hnsw ("embedding" extensions.vector_cosine_ops);

CREATE TRIGGER product_knowledge_chunks_set_updated_at
BEFORE UPDATE ON "product_knowledge_chunks"
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Mobile/web chỉ dùng Supabase Auth; bảng RAG cũng phải đi qua backend như các bảng ứng dụng khác.
ALTER TABLE "product_knowledge_chunks" ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    REVOKE ALL ON TABLE "product_knowledge_chunks" FROM anon;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    REVOKE ALL ON TABLE "product_knowledge_chunks" FROM authenticated;
  END IF;
END;
$$;
