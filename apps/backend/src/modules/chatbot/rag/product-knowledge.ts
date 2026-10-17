export interface ChunkOptions {
  maxWords?: number;
  overlapWords?: number;
}

export interface ProductChunkContext {
  productId: string;
  productName: string;
  categoryName: string;
}

interface SentenceUnit {
  text: string;
  paragraphIndex: number;
  words: number;
}

const DEFAULT_MAX_WORDS = 320;
const DEFAULT_OVERLAP_WORDS = 50;

export function chunkProductDescription(
  description: string,
  options: ChunkOptions = {}
): string[] {
  const maxWords = positiveInteger(options.maxWords, DEFAULT_MAX_WORDS);
  const overlapWords = Math.min(
    nonNegativeInteger(options.overlapWords, DEFAULT_OVERLAP_WORDS),
    Math.max(0, maxWords - 1)
  );
  const paragraphs = normalizeParagraphs(description);

  if (paragraphs.length === 0) return [];

  const normalized = paragraphs.join("\n\n");
  if (countWords(normalized) <= maxWords) return [normalized];

  const units = paragraphs.flatMap((paragraph, paragraphIndex) =>
    splitSentences(paragraph).map((text) => ({
      text,
      paragraphIndex,
      words: countWords(text),
    }))
  );

  const chunks: string[] = [];
  let current: SentenceUnit[] = [];

  for (const unit of units) {
    const candidateWords = totalWords(current) + unit.words;
    if (current.length === 0 || candidateWords <= maxWords) {
      current.push(unit);
      continue;
    }

    chunks.push(joinUnits(current));

    // Chỉ lặp lại câu hoàn chỉnh để phần giao nhau không làm mất hoặc cắt đôi ý chăm sóc cây.
    current = trailingOverlap(current, overlapWords);
    // maxWords là soft limit: ưu tiên giữ overlap nguyên câu hơn là cắt mất ngữ cảnh.
    current.push(unit);
  }

  if (current.length > 0) chunks.push(joinUnits(current));
  return chunks;
}

export function buildContextualChunk(context: ProductChunkContext, chunk: string): string {
  return [
    `Mã sản phẩm: ${context.productId}`,
    `Tên sản phẩm: ${context.productName}`,
    `Danh mục: ${context.categoryName}`,
    "",
    chunk.trim(),
  ].join("\n");
}

function normalizeParagraphs(value: string): string[] {
  return value
    .replace(/\r\n?/g, "\n")
    .split(/\n\s*\n/u)
    .map((paragraph) => paragraph.replace(/\s+/gu, " ").trim())
    .filter(Boolean);
}

function splitSentences(paragraph: string): string[] {
  return (paragraph.match(/[^.!?…]+(?:[.!?…]+|$)/gu) ?? [paragraph])
    .map((sentence) => sentence.trim())
    .filter(Boolean);
}

function trailingOverlap(units: SentenceUnit[], overlapWords: number): SentenceUnit[] {
  if (overlapWords === 0) return [];

  const overlap: SentenceUnit[] = [];
  let words = 0;
  for (let index = units.length - 1; index >= 0; index -= 1) {
    const unit = units[index];
    if (!unit || words + unit.words > overlapWords) break;
    overlap.unshift(unit);
    words += unit.words;
  }
  return overlap;
}

function joinUnits(units: SentenceUnit[]): string {
  return units.reduce((result, unit, index) => {
    if (index === 0) return unit.text;
    const previous = units[index - 1];
    return `${result}${previous?.paragraphIndex === unit.paragraphIndex ? " " : "\n\n"}${unit.text}`;
  }, "");
}

function totalWords(units: SentenceUnit[]): number {
  return units.reduce((total, unit) => total + unit.words, 0);
}

function countWords(value: string): number {
  return value.trim() ? value.trim().split(/\s+/u).length : 0;
}

function positiveInteger(value: number | undefined, fallback: number): number {
  return Number.isInteger(value) && (value ?? 0) > 0 ? value! : fallback;
}

function nonNegativeInteger(value: number | undefined, fallback: number): number {
  return Number.isInteger(value) && (value ?? -1) >= 0 ? value! : fallback;
}
