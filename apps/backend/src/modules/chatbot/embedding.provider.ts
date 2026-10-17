export const RAG_EMBEDDING_DIMENSIONS = 768;

export interface EmbeddingProvider {
  embedDocument(text: string, title?: string, signal?: AbortSignal): Promise<number[]>;
  embedQuery(text: string, signal?: AbortSignal): Promise<number[]>;
}
