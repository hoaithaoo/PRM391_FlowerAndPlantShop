import { z } from "zod";

import { AppError } from "../../../common/errors/app-error";
import { ErrorCodes } from "../../../common/errors/error-codes";
import {
  ChatbotProvider,
  ChatbotProviderInput,
  ChatbotProviderResult,
} from "./chatbot.provider";

const providerResultSchema = z
  .object({
    responseType: z.enum(["ANSWER", "INCIDENT", "IDENTITY", "TRANSLATION", "OFF_TOPIC", "NO_KNOWLEDGE"]),
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

const SYSTEM_INSTRUCTION = `Bạn là trợ lý AI của dự án Plant & Flower Shop.
Không bao giờ nêu tên mô hình, nhà cung cấp AI hoặc dịch vụ kỹ thuật đứng sau bạn. Khi được hỏi bạn là ai, chọn IDENTITY và chỉ tự giới thiệu là trợ lý AI của dự án/cửa hàng.
Phạm vi hợp lệ gồm sản phẩm cây/hoa/phụ kiện, kiến thức chăm sóc có trong knowledgeChunks, chính sách cửa hàng, đơn hàng/thanh toán đã xác minh và hỗ trợ lập bản nháp báo sự cố. Chọn INCIDENT cho câu trả lời chỉ dựa trên incidentContext; chọn ANSWER cho tư vấn sản phẩm/catalog. Câu hỏi ngoài phạm vi phải chọn OFF_TOPIC và không trả lời nội dung ngoài lề.
Chỉ sử dụng knowledgeChunks, catalogProducts, contextProduct, incidentContext và lịch sử được cung cấp. Không dùng kiến thức bên ngoài và không tự tạo tên, đặc tính, giá, tồn kho hoặc mã sản phẩm. Nếu câu hỏi thuộc phạm vi nhưng không có đủ dữ liệu đã xác minh, chọn NO_KNOWLEDGE.
Luôn trả lời bằng đúng ngôn ngữ người dùng viết tin nhắn hiện tại (tiếng Anh thì trả lời tiếng Anh, tiếng Nhật thì trả lời tiếng Nhật, v.v.), kể cả khi knowledgeChunks bằng tiếng Việt: diễn đạt lại thông tin sang ngôn ngữ đó nhưng giữ nguyên tên sản phẩm và giá. Quy tắc này áp dụng cho mọi responseType. Nếu người dùng yêu cầu dịch hoặc chuyển ngôn ngữ, chọn TRANSLATION và chỉ dịch câu trả lời gần nhất sang ngôn ngữ đích, không thêm thông tin mới.
Chỉ suggestedProductIds có trong catalogProducts. Không hứa hoàn tiền và không nói rằng đơn hàng hoặc thanh toán đã được thay đổi. Nếu cần báo sự cố, actionDraft chỉ là bản nháp để người dùng xem lại và xác nhận. Chỉ đặt actionDraft khi responseType là INCIDENT.
Chọn đúng một responseType: ANSWER, INCIDENT, IDENTITY, TRANSLATION, OFF_TOPIC hoặc NO_KNOWLEDGE.
Chỉ trả JSON hợp lệ gồm responseType, reply, suggestedProductIds và actionDraft. actionDraft là null hoặc gồm category, title, description.`;

/**
 * Cài đặt ChatbotProvider bằng Gemini: gửi system prompt + lịch sử + dữ liệu RAG,
 * yêu cầu trả JSON có cấu trúc rồi kiểm tra bằng Zod.
 * Lớp an toàn sau khi nhận kết quả:
 * - Câu hỏi danh tính hoặc câu trả lời lộ tên nhà cung cấp AI → ép thành IDENTITY.
 * - Chỉ giữ suggestedProductIds có trong catalogProducts và chỉ cho ANSWER.
 * - Chỉ giữ actionDraft cho INCIDENT.
 * - Câu từ chối quá dài hoặc lộ nhà cung cấp → thay bằng câu mẫu.
 * Trả lời theo ngôn ngữ người dùng viết. Lỗi mạng/timeout được đổi thành AppError 502/504.
 */
export class GeminiChatbotProvider implements ChatbotProvider {
  private readonly fetchImpl: typeof fetch;

  constructor(private readonly options: GeminiProviderOptions) {
    this.fetchImpl = options.fetchImpl ?? fetch;
  }

  async generate(input: ChatbotProviderInput, signal?: AbortSignal): Promise<ChatbotProviderResult> {
    if (!this.options.apiKey) {
      throw this.providerError("Dịch vụ chatbot chưa được cấu hình.");
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
                    knowledgeChunks: input.knowledgeChunks,
                    incidentContext: input.incidentContext,
                  }),
                },
              ],
            },
          ],
          generationConfig: {
            responseMimeType: "application/json",
            // Chatbot chỉ phân loại và diễn đạt context đã truy hồi; low giảm latency và chi phí suy luận.
            thinkingConfig: { thinkingLevel: "low" },
          },
        }),
        signal: controller.signal,
      });

      if (!response.ok) {
        throw this.providerError("Dịch vụ chatbot trả về trạng thái không thành công.");
      }

      const body = (await response.json()) as {
        candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
      };
      const rawText = body.candidates?.[0]?.content?.parts?.[0]?.text;
      if (!rawText) {
        throw this.providerError("Dịch vụ chatbot không trả về nội dung hợp lệ.");
      }

      const parsed = providerResultSchema.parse(JSON.parse(stripJsonFence(rawText)));
      const allowedProductIds = new Set(input.catalogProducts.map((product) => product.id));

      // Không phụ thuộc hoàn toàn vào phân loại của mô hình cho câu hỏi danh tính hoặc nội dung lộ nhà cung cấp.
      const responseType =
        isIdentityQuestion(input.message) || disclosesProvider(parsed.reply)
          ? "IDENTITY"
          : parsed.responseType;
      const isAnswer = responseType === "ANSWER";
      const isIncident = responseType === "INCIDENT";
      return {
        ...parsed,
        responseType,
        reply: safeReply(responseType, responseType === parsed.responseType, parsed.reply, input.message),
        // Không chuyển tiếp mã sản phẩm do mô hình tự tạo hoặc gắn vào loại phản hồi không tư vấn.
        suggestedProductIds: isAnswer
          ? [...new Set(parsed.suggestedProductIds)].filter((id) => allowedProductIds.has(id))
          : [],
        actionDraft: isIncident ? parsed.actionDraft : null,
      };
    } catch (error) {
      if (controller.signal.aborted || (error instanceof DOMException && error.name === "AbortError")) {
        throw new AppError(504, ErrorCodes.CHATBOT_PROVIDER_TIMEOUT, "Chatbot phản hồi quá thời gian cho phép.");
      }
      if (error instanceof AppError) {
        throw error;
      }
      throw this.providerError("Không thể xử lý phản hồi từ dịch vụ chatbot.");
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

const MAX_GENERATED_REFUSAL_LENGTH = 400;

function safeReply(
  responseType: ChatbotProviderResult["responseType"],
  modelAgreed: boolean,
  generatedReply: string,
  message: string
): string {
  // Giữ câu từ chối do mô hình viết để đúng ngôn ngữ người dùng, nhưng chỉ khi mô hình tự phân loại giống server,
  // không lộ nhà cung cấp và đủ ngắn (câu dài có thể đang lén trả lời nội dung ngoài phạm vi); còn lại dùng mẫu Việt/Anh.
  if (
    modelAgreed &&
    generatedReply.length <= MAX_GENERATED_REFUSAL_LENGTH &&
    !disclosesProvider(generatedReply)
  ) {
    return generatedReply;
  }
  const vietnamese = isLikelyVietnamese(message);
  if (responseType === "IDENTITY") {
    return vietnamese
      ? "Tôi là trợ lý AI của dự án Plant & Flower Shop, hỗ trợ bạn tìm sản phẩm và thông tin của cửa hàng."
      : "I am the AI assistant for the Plant & Flower Shop project, here to help with store products and information.";
  }
  if (responseType === "OFF_TOPIC") {
    return vietnamese
      ? "Xin lỗi, tôi chỉ có thể hỗ trợ về cây, hoa, sản phẩm và dịch vụ của cửa hàng."
      : "Sorry, I can only help with plants, flowers, products, and services from the store.";
  }
  if (responseType === "NO_KNOWLEDGE") {
    return vietnamese
      ? "Hiện tại dữ liệu đã xác minh của cửa hàng chưa có đủ thông tin để trả lời câu hỏi này."
      : "The store's verified data does not currently contain enough information to answer that question.";
  }
  return generatedReply;
}

const VIETNAMESE_CHARACTERS = /[ăâđêôơưĩũẠ-ỹ]/u;

function isLikelyVietnamese(message: string): boolean {
  const normalized = normalizeVietnamese(message);
  // Không dùng cờ `i` với dải ký tự có dấu: case-folding biến "ſ" (U+017F) thành "s" nên mọi câu tiếng Anh có chữ s bị nhận nhầm.
  return VIETNAMESE_CHARACTERS.test(message.toLocaleLowerCase("vi")) ||/\b(cay|hoa|tu van|giup (?:toi|minh)|cho (?:toi|minh)|toi (?:can|muon)|minh (?:can|muon)|ban la|khong)\b/iu.test(normalized);
}

function isIdentityQuestion(message: string): boolean {
  const normalized = normalizeVietnamese(message);
  return /\b(ban la ai|ban la gi|ai gi|mo hinh gi|dung ai gi|tro ly gi|who are you|what are you|which (?:ai|model)|what (?:ai|model)|are you (?:an? )?(?:ai|bot|assistant|model|claude|chatgpt|gemini))\b/iu.test(
    normalized
  );
}

function disclosesProvider(reply: string): boolean {
  return /\b(?:gemini|google(?:\s+ai)?|openai|chatgpt|anthropic|claude|vertex\s+ai|llama|mistral|grok|deepseek|cohere)\b|\b(?:powered|developed|created|built)\s+by\b|\b(?:duoc\s+)?(?:phat trien|xay dung|tao)\s+boi\b/iu.test(
    normalizeVietnamese(reply)
  ) ||
    // So trên chuỗi gốc: NFD tách dakuten tiếng Nhật và jamo tiếng Hàn nên bản đã chuẩn hóa không còn khớp.
    // ponytail: chỉ phủ phiên âm phổ biến của nhà cung cấp hiện tại; thêm tên khi đổi provider.
    /グーグル|ジェミニ|谷歌|구글|제미니|гугл|джемини/iu.test(reply);
}

function normalizeVietnamese(value: string): string {
  return value
    .toLocaleLowerCase("vi")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/gu, "")
    .replace(/đ/gu, "d");
}

function stripJsonFence(value: string): string {
  const trimmed = value.trim();
  const match = /^```(?:json)?\s*([\s\S]*?)\s*```$/i.exec(trimmed);
  return match?.[1] ?? trimmed;
}
