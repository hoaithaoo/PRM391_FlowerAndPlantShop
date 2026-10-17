import { AppError } from "../../../common/errors/app-error";
import { ErrorCodes } from "../../../common/errors/error-codes";
import { EmbeddingProvider } from "./embedding.provider";

interface GeminiEmbeddingProviderOptions {
  apiKey: string;
  model: string;
  baseUrl: string;
  dimensions: number;
  timeoutMs: number;
  fetchImpl?: typeof fetch;
}

/**
 * Cài đặt EmbeddingProvider bằng Gemini Embedding REST API.
 * - Thêm tiền tố định dạng khác nhau cho document và query.
 * - Có timeout và hỗ trợ hủy (AbortSignal).
 * - Kiểm tra vector trả về đúng 768 số hợp lệ; sai thì ném CHATBOT_PROVIDER_ERROR.
 * - Thông báo lỗi không nêu tên nhà cung cấp.
 */
export class GeminiEmbeddingProvider implements EmbeddingProvider {
  private readonly fetchImpl: typeof fetch;

  constructor(private readonly options: GeminiEmbeddingProviderOptions) {
    this.fetchImpl = options.fetchImpl ?? fetch;
  }

  embedDocument(text: string, title = "none", signal?: AbortSignal): Promise<number[]> {
    // Embedding tìm kiếm bất đối xứng cần định dạng document khác query để tăng độ chính xác truy hồi.
    return this.embed(`title: ${title.trim() || "none"} | text: ${text}`, signal);
  }

  embedQuery(text: string, signal?: AbortSignal): Promise<number[]> {
    return this.embed(`task: search result | query: ${text}`, signal);
  }

  private async embed(text: string, signal?: AbortSignal): Promise<number[]> {
    if (!this.options.apiKey) {
      throw this.providerError("Dịch vụ embedding chưa được cấu hình.");
    }

    const controller = new AbortController();
    const abortFromCaller = () => controller.abort();
    signal?.addEventListener("abort", abortFromCaller, { once: true });
    const timeout = setTimeout(() => controller.abort(), this.options.timeoutMs);

    try {
      const response = await this.fetchImpl(this.endpoint(), {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-goog-api-key": this.options.apiKey,
        },
        body: JSON.stringify({
          model: `models/${this.options.model}`,
          content: { parts: [{ text }] },
          output_dimensionality: this.options.dimensions,
        }),
        signal: controller.signal,
      });

      if (!response.ok) {
        throw this.providerError("Dịch vụ embedding trả về trạng thái không thành công.");
      }

      const body = (await response.json()) as { embedding?: { values?: unknown } };
      const values = body.embedding?.values;
      if (
        !Array.isArray(values) ||
        values.length !== this.options.dimensions ||
        !values.every((value) => typeof value === "number" && Number.isFinite(value))
      ) {
        throw this.providerError("Dịch vụ embedding trả về vector không hợp lệ.");
      }

      return values as number[];
    } catch (error) {
      if (controller.signal.aborted || (error instanceof DOMException && error.name === "AbortError")) {
        throw new AppError(
          504,
          ErrorCodes.CHATBOT_PROVIDER_TIMEOUT,
          "Dịch vụ tìm kiếm phản hồi quá thời gian cho phép."
        );
      }
      if (error instanceof AppError) throw error;
      throw this.providerError("Không thể tạo dữ liệu tìm kiếm ngữ nghĩa.");
    } finally {
      clearTimeout(timeout);
      signal?.removeEventListener("abort", abortFromCaller);
    }
  }

  private endpoint(): string {
    return `${this.options.baseUrl.replace(/\/$/u, "")}/models/${encodeURIComponent(this.options.model)}:embedContent`;
  }

  private providerError(message: string): AppError {
    return new AppError(502, ErrorCodes.CHATBOT_PROVIDER_ERROR, message);
  }
}
