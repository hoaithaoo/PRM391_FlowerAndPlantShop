-- Store the normalized FTS document once so ranking and the GIN index use the same expression.
ALTER TABLE "product_knowledge_chunks"
ADD COLUMN "search_vector" tsvector
GENERATED ALWAYS AS (to_tsvector('simple'::regconfig, "content")) STORED;

DROP INDEX "product_knowledge_chunks_content_fts_idx";
CREATE INDEX "product_knowledge_chunks_search_vector_fts_idx"
  ON "product_knowledge_chunks" USING GIN ("search_vector");
