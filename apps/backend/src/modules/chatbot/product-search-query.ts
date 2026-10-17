export interface ProductSearchFilters {
  minPrice?: number;
  maxPrice?: number;
}

const AMOUNT = String.raw`(\d+(?:[.,]\d{1,3})?(?:[.,]\d{3})*)\s*(trieu|million|nghin|ngan|thousand|k|dong|vnd|d)?`;
const PRICE_AMOUNT = String.raw`\d+(?:[.,]\d{1,3})?(?:[.,]\d{3})*\s*(?:triệu|trieu|million|nghìn|nghin|ngàn|ngan|thousand|k|đồng|dong|vnd|đ|d)?`;

export function parseProductSearchFilters(query: string): ProductSearchFilters {
  const normalized = normalizeForMatching(query);
  const range = new RegExp(
    String.raw`(?:tu|between)\s+${AMOUNT}\s+(?:den|toi|and|-)\s+${AMOUNT}`,
    "iu"
  ).exec(normalized);

  if (range) {
    const first = parseAmount(range[1], range[2]);
    const second = parseAmount(range[3], range[4]);
    if (first !== null && second !== null) {
      return { minPrice: Math.min(first, second), maxPrice: Math.max(first, second) };
    }
  }

  const filters: ProductSearchFilters = {};
  const maximum = new RegExp(
    String.raw`(?:duoi|khong qua|toi da|under|below|up to|maximum|max)\s+${AMOUNT}`,
    "iu"
  ).exec(normalized);
  const minimum = new RegExp(
    String.raw`(?:tren|it nhat|toi thieu|over|above|at least|minimum|min)\s+${AMOUNT}`,
    "iu"
  ).exec(normalized);

  const maxPrice = maximum ? parseAmount(maximum[1], maximum[2]) : null;
  const minPrice = minimum ? parseAmount(minimum[1], minimum[2]) : null;
  if (minPrice !== null) filters.minPrice = minPrice;
  if (maxPrice !== null) filters.maxPrice = maxPrice;
  return filters;
}

/**
 * Bỏ phần giá khỏi câu FTS để PostgreSQL chỉ xếp hạng theo nhu cầu/sản phẩm.
 * Khoảng giá vẫn được giữ riêng trong ProductSearchFilters và lọc bằng cột price.
 */
export function stripProductSearchFilters(query: string): string {
  const pricePatterns = [
    new RegExp(
      String.raw`(?:từ|tu|between)\s+${PRICE_AMOUNT}\s+(?:đến|den|tới|toi|and|-)\s+${PRICE_AMOUNT}`,
      "giu"
    ),
    new RegExp(
      String.raw`(?:dưới|duoi|không quá|khong qua|tối đa|toi da|under|below|up to|maximum|max)\s+${PRICE_AMOUNT}`,
      "giu"
    ),
    new RegExp(
      String.raw`(?:trên|tren|ít nhất|it nhat|tối thiểu|toi thieu|over|above|at least|minimum|min)\s+${PRICE_AMOUNT}`,
      "giu"
    ),
  ];

  const stripped = pricePatterns.reduce((value, pattern) => value.replace(pattern, " "), query);
  return stripped.replace(/\s+([,.;!?])/gu, "$1").replace(/\s+/gu, " ").trim();
}

function normalizeForMatching(value: string): string {
  return value
    .toLocaleLowerCase("vi")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/gu, "")
    .replace(/đ/gu, "d")
    .replace(/\s+/gu, " ")
    .trim();
}

function parseAmount(rawValue: string | undefined, rawUnit: string | undefined): number | null {
  if (!rawValue) return null;

  const unit = rawUnit?.toLowerCase();
  const groupedNumber = /^\d{1,3}(?:[.,]\d{3})+$/u.test(rawValue);
  let numericValue: number;

  if (unit === "trieu" || unit === "million") {
    numericValue = Number(rawValue.replace(",", ".")) * 1_000_000;
  } else if (["nghin", "ngan", "thousand", "k"].includes(unit ?? "")) {
    numericValue = Number(rawValue.replace(",", ".")) * 1_000;
  } else {
    numericValue = Number(groupedNumber ? rawValue.replace(/[.,]/gu, "") : rawValue);
  }

  if (!Number.isFinite(numericValue) || numericValue < 0) return null;
  return Math.round(numericValue);
}
