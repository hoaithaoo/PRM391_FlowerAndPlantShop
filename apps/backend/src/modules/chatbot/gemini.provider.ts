import { z } from "zod";

import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import {
  ChatbotProvider,
  ChatbotProviderInput,
  ChatbotProviderResult,
} from "./chatbot.provider";

const providerResultSchema = z
  .object({
    reply: z.string().trim().min(1).max(4000),
    suggestedProductIds: z.array(z.string().uuid()).max(8),
    actionDraft: z
      .object({
        category: z.string().trim().min(1).max(50),
        title: z.string().trim().min(1).max(200),
        description: z.string().trim().min(1).max(2000),
      })
      .strict()
      .nullable(),
  })
  .strict();

interface GeminiProviderOptions {
  apiKey: string;
  model: string;
  baseUrl: string;
  timeoutMs: number;
  fetchImpl?: typeof fetch;
}

const SYSTEM_INSTRUCTION = `Bạn là trợ lý chăm sóc khách hàng cho cửa hàng cây và hoa.
Luôn trả lời bằng tiếng Việt. Chỉ tư vấn bằng dữ liệu sản phẩm được cung cấp; không tự tạo tên, giá, tồn kho hoặc mã sản phẩm.
Không hứa hoàn tiền và không nói rằng đơn hàng hoặc thanh toán đã được thay đổi.
Nếu người dùng cần báo sự cố, trả actionDraft để client mở form cho người dùng xem lại và xác nhận.
Chỉ trả JSON hợp lệ gồm reply, suggestedProductIds và actionDraft. actionDraft là null hoặc gồm category, title, description.`;

export class GeminiChatbotProvider implements ChatbotProvider {
  private readonly fetchImpl: typeof fetch;

  constructor(private readonly options: GeminiProviderOptions) {
    this.fetchImpl = options.fetchImpl ?? fetch;
  }

  async generate(input: ChatbotProviderInput, signal?: AbortSignal): Promise<ChatbotProviderResult> {
    if (!this.options.apiKey) {
      throw this.providerError("Gemini chưa được cấu hình.");
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
          system_instruction: { parts: [{ text: SYSTEM_INSTRUCTION }] },
          contents: [
            ...input.history.map((message) => ({
              role: message.role === "ASSISTANT" ? "model" : "user",
              parts: [{ text: message.content }],
            })),
            {
              role: "user",
              parts: [
                {
                  text: JSON.stringify({
                    message: input.message,
                    contextProduct: input.contextProduct,
                    catalogProducts: input.catalogProducts,
                    incidentContext: input.incidentContext,
                  }),
                },
              ],
            },
          ],
          generationConfig: { responseMimeType: "application/json" },
        }),
        signal: controller.signal,
      });

      if (!response.ok) {
        throw this.providerError("Gemini trả về trạng thái không thành công.");
      }

      const body = (await response.json()) as {
        candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
      };
      const rawText = body.candidates?.[0]?.content?.parts?.[0]?.text;
      if (!rawText) {
        throw this.providerError("Gemini không trả về nội dung hợp lệ.");
      }

      const parsed = providerResultSchema.parse(JSON.parse(stripJsonFence(rawText)));
      const allowedProductIds = new Set(input.catalogProducts.map((product) => product.id));

      return {
        ...parsed,
        // Không chuyển tiếp mã sản phẩm do mô hình tự tạo sang mobile.
        suggestedProductIds: [...new Set(parsed.suggestedProductIds)].filter((id) => allowedProductIds.has(id)),
      };
    } catch (error) {
      if (controller.signal.aborted || (error instanceof DOMException && error.name === "AbortError")) {
        throw new AppError(504, ErrorCodes.CHATBOT_PROVIDER_TIMEOUT, "Chatbot phản hồi quá thời gian cho phép.");
      }
      if (error instanceof AppError) {
        throw error;
      }
      throw this.providerError("Không thể xử lý phản hồi từ Gemini.");
    } finally {
      clearTimeout(timeout);
      signal?.removeEventListener("abort", abortFromCaller);
    }
  }

  private endpoint(): string {
    return `${this.options.baseUrl.replace(/\/$/, "")}/models/${encodeURIComponent(this.options.model)}:generateContent`;
  }

  private providerError(message: string): AppError {
    return new AppError(502, ErrorCodes.CHATBOT_PROVIDER_ERROR, message);
  }
}

function stripJsonFence(value: string): string {
  const trimmed = value.trim();
  const match = /^```(?:json)?\s*([\s\S]*?)\s*```$/i.exec(trimmed);
  return match?.[1] ?? trimmed;
}
