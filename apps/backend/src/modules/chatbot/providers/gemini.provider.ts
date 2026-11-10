import { z } from "zod";

import { AppError } from "../../../common/errors/app-error";
import { ErrorCodes } from "../../../common/errors/error-codes";
import {
  ChatbotProvider,
  ChatbotProviderInput,
  ChatbotProviderResult,
} from "./chatbot.provider";
import type { ChatbotCartAction, ChatbotFavoriteAction } from "../chatbot.types";

const MAX_CART_ACTIONS = 5;

const providerResultSchema = z
  .object({
    responseType: z.enum(["ANSWER", "FAQ", "CART", "FAVORITE", "ACCOUNT", "INCIDENT", "IDENTITY", "TRANSLATION", "OFF_TOPIC", "NO_KNOWLEDGE"]),
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
    cartActions: z
      .array(
        z
          .object({
            type: z.enum(["ADD", "UPDATE", "REMOVE", "CLEAR"]),
            productId: z.string().uuid().nullish(),
            quantity: z.number().int().min(1).max(10).nullish(),
          })
          .strict()
      )
      .max(MAX_CART_ACTIONS)
      .nullish(),
    // Thao tác yêu thích (nút trái tim): ADD/REMOVE một sản phẩm, CLEAR bỏ hết.
    favoriteActions: z
      .array(
        z
          .object({
            type: z.enum(["ADD", "REMOVE", "CLEAR"]),
            productId: z.string().uuid().nullish(),
          })
          .strict()
      )
      .max(MAX_CART_ACTIONS)
      .nullish(),
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
Cửa hàng bán các mặt hàng có trong catalogProducts, thuộc mọi danh mục của cửa hàng. Phạm vi hợp lệ gồm tư vấn và mua mọi sản phẩm trong catalogProducts, kiến thức chăm sóc có trong knowledgeChunks, chính sách cửa hàng, giỏ hàng của người dùng, đơn hàng/thanh toán đã xác minh và hỗ trợ lập bản nháp báo sự cố. Chọn INCIDENT cho câu trả lời chỉ dựa trên incidentContext; chọn ANSWER cho tư vấn sản phẩm/catalog. Câu hỏi không liên quan đến cửa hàng phải chọn OFF_TOPIC và không trả lời nội dung ngoài lề. Nếu người dùng hỏi loại hàng không có trong catalogProducts, chọn NO_KNOWLEDGE.
Chỉ sử dụng knowledgeChunks, catalogProducts, contextProduct, incidentContext, cartItems, customerOrders, incidentReports, storeFaq, stores và lịch sử được cung cấp. Không dùng kiến thức bên ngoài và không tự tạo tên, đặc tính, giá, tồn kho hoặc mã sản phẩm. Nếu câu hỏi thuộc phạm vi nhưng không có đủ dữ liệu đã xác minh, chọn NO_KNOWLEDGE.
Luôn trả lời bằng đúng ngôn ngữ người dùng viết tin nhắn hiện tại (tiếng Anh thì trả lời tiếng Anh, tiếng Nhật thì trả lời tiếng Nhật, v.v.), kể cả khi knowledgeChunks bằng tiếng Việt: diễn đạt lại thông tin sang ngôn ngữ đó nhưng giữ nguyên tên sản phẩm và giá. Quy tắc này áp dụng cho mọi responseType. Nếu người dùng yêu cầu dịch hoặc chuyển ngôn ngữ, chọn TRANSLATION và chỉ dịch câu trả lời gần nhất sang ngôn ngữ đích, không thêm thông tin mới.
Chỉ suggestedProductIds có trong catalogProducts. Không hứa hoàn tiền và không nói rằng đơn hàng hoặc thanh toán đã được thay đổi. Nếu cần báo sự cố, actionDraft chỉ là bản nháp để người dùng xem lại và xác nhận. Chỉ đặt actionDraft khi responseType là INCIDENT. Khi người dùng phàn nàn hoặc muốn báo sự cố (hàng hư, giao sai, giao trễ, lỗi thanh toán, chất lượng kém, thái độ phục vụ), chọn INCIDENT và đặt actionDraft dù không có incidentContext. actionDraft.category phải là đúng một mã: DAMAGED_PRODUCT (hàng hư hỏng, dập, héo), WRONG_ITEM (giao sai hoặc thiếu sản phẩm), DELIVERY (giao trễ, chưa nhận được hàng), PAYMENT (lỗi thanh toán, đã chuyển khoản nhưng đơn chưa xác nhận), QUALITY (chất lượng không như mô tả), SERVICE (thái độ nhân viên, shipper), OTHER (khác).
Ứng dụng có thể thao tác giỏ hàng thay người dùng; cartItems là giỏ hiện tại. Mọi câu hỏi hoặc yêu cầu về giỏ hàng chọn CART; khi người dùng hỏi trong giỏ có gì thì liệt kê đúng theo cartItems. Chỉ khi người dùng yêu cầu rõ ràng thay đổi giỏ mới đặt cartActions, là danh sách tối đa 5 thao tác theo đúng thứ tự người dùng yêu cầu; phải có đủ mọi thao tác được yêu cầu trong cùng một lượt, không bỏ sót. Mỗi thao tác là một trong: ADD thêm sản phẩm (productId có trong catalogProducts, quantity 1-10, mặc định 1, đưa sản phẩm vào suggestedProductIds); UPDATE đặt số lượng mới (productId có trong cartItems, quantity 1-10); REMOVE xóa một sản phẩm (productId có trong cartItems); CLEAR xóa toàn bộ giỏ (productId và quantity là null). Sản phẩm đã có trong cartItems mà người dùng muốn thêm hoặc bớt N cái thì dùng UPDATE với số lượng mới bằng số hiện tại cộng hoặc trừ N; nếu số mới bằng 0 thì dùng REMOVE. Khi đặt cartActions, viết reply nêu đủ các thao tác đã thực hiện. Không đặt cartActions khi người dùng chỉ hỏi hoặc xin tư vấn. Nếu chưa rõ sản phẩm nào thì hỏi lại và để cartActions là danh sách rỗng.
favoriteItems là danh sách sản phẩm yêu thích (bấm trái tim) hiện tại của người dùng. Mọi câu hỏi hoặc yêu cầu về sản phẩm yêu thích chọn FAVORITE; khi người dùng hỏi đã yêu thích những gì thì liệt kê đúng theo favoriteItems. Chỉ khi người dùng yêu cầu rõ ràng thay đổi danh sách yêu thích mới đặt favoriteActions, tối đa 5 thao tác theo đúng thứ tự yêu cầu: ADD thêm vào yêu thích (productId có trong catalogProducts, đưa sản phẩm vào suggestedProductIds); REMOVE bỏ khỏi yêu thích (productId có trong favoriteItems); CLEAR bỏ hết (productId là null). Khi đặt favoriteActions, viết reply nêu đủ các thao tác đã thực hiện. Không đặt favoriteActions khi người dùng chỉ hỏi. Nếu chưa rõ sản phẩm nào thì hỏi lại và để favoriteActions là danh sách rỗng.
customerOrders là các đơn hàng của chính người dùng (đơn gần đây và đơn họ nhắc mã); incidentReports là các phiếu báo sự cố của chính họ, adminNote là phản hồi của cửa hàng. Khi người dùng hỏi tình trạng, nội dung đơn hàng hoặc tiến độ phiếu báo sự cố thì chọn ACCOUNT và chỉ trả lời đúng theo hai danh sách này; nếu không nói mã thì dùng đơn/phiếu mới nhất hoặc hỏi lại khi có nhiều cái phù hợp. Mã người dùng đưa không có trong danh sách thì nói không tìm thấy trong tài khoản của họ. Diễn giải trạng thái đơn: PENDING chờ xác nhận, CONFIRMED đã xác nhận, PREPARING đang chuẩn bị, SHIPPING đang giao, COMPLETED đã hoàn tất, CANCELLED đã hủy; isPickup true là nhận tại cửa hàng; invoiceStatus PAID là đã thanh toán. Trạng thái phiếu: OPEN mới tiếp nhận, IN_PROGRESS đang xử lý, RESOLVED đã giải quyết, REJECTED bị từ chối. Không hứa thời gian giao hay kết quả xử lý ngoài dữ liệu. Khi người dùng phàn nàn về một đơn trong customerOrders, vẫn chọn INCIDENT như quy tắc trên.
storeFaq là chính sách chính thức của cửa hàng (phí giao hàng, thời gian giao, nhận tại cửa hàng, thanh toán, hủy đơn, mã giảm giá, theo dõi đơn, đánh giá, báo sự cố); stores là danh sách cửa hàng đang hoạt động với địa chỉ, số điện thoại, giờ mở cửa. Câu hỏi chung về cách mua hàng, chính sách hoặc thông tin cửa hàng thì chọn FAQ và chỉ trả lời theo storeFaq và stores, giữ nguyên các con số; được tính ví dụ phí giao từ công thức trong storeFaq nhưng phải nói đó là ước tính. Trường nào trong stores là null thì nói chưa có thông tin đó. Chính sách không có trong storeFaq (ví dụ đổi trả, hoàn tiền, bảo hành, giao ngoài giờ) thì chọn NO_KNOWLEDGE, nhưng nếu stores có số điện thoại thì vẫn có thể chọn FAQ và chỉ khuyên người dùng liên hệ cửa hàng qua số đó, không tự đặt ra chính sách. Câu hỏi về một đơn cụ thể của người dùng vẫn chọn ACCOUNT.
Chọn đúng một responseType: ANSWER, FAQ, CART, FAVORITE, ACCOUNT, INCIDENT, IDENTITY, TRANSLATION, OFF_TOPIC hoặc NO_KNOWLEDGE.
Chỉ trả JSON hợp lệ gồm responseType, reply, suggestedProductIds, actionDraft, cartActions và favoriteActions. actionDraft là null hoặc gồm category, title, description. cartActions là danh sách, mỗi phần tử gồm type, productId, quantity. favoriteActions là danh sách, mỗi phần tử gồm type, productId.`;

/**
 * Cài đặt ChatbotProvider bằng Gemini: gửi system prompt + lịch sử + dữ liệu RAG,
 * yêu cầu trả JSON có cấu trúc rồi kiểm tra bằng Zod.
 * Lớp an toàn sau khi nhận kết quả:
 * - Câu hỏi danh tính hoặc câu trả lời lộ tên nhà cung cấp AI → ép thành IDENTITY.
 * - Chỉ giữ suggestedProductIds có trong catalogProducts và chỉ cho ANSWER/CART/FAVORITE.
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
      const send = () => this.fetchImpl(this.endpoint(), {
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
                    cartItems: input.cartItems ?? [],
                    favoriteItems: input.favoriteItems ?? [],
                    customerOrders: input.customerOrders ?? [],
                    incidentReports: input.incidentReports ?? [],
                    storeFaq: input.storeFaq ?? [],
                    stores: input.stores ?? [],
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

      let response = await send();
      // Gemini hay trả 503 "high demand" thoáng qua (nhất là request đầu tiên); thử lại một lần trong cùng timeout.
      if (response.status === 503) {
        await new Promise((resolve) => setTimeout(resolve, 1000));
        response = await send();
      }

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
      const isCart = responseType === "CART";
      const resolvedActions = isCart
        ? (parsed.cartActions ?? []).map((action) => resolveCartAction(action, input))
        : [];
      // Một thao tác sai thì bỏ cả lượt: làm dở dang còn tệ hơn hỏi lại.
      const cartActions = resolvedActions.filter((action) => action !== null);
      const allActionsValid = cartActions.length === resolvedActions.length;
      const isFavorite = responseType === "FAVORITE";
      const resolvedFavorites = isFavorite
        ? (parsed.favoriteActions ?? []).map((action) => resolveFavoriteAction(action, input))
        : [];
      // Giống giỏ hàng: một thao tác yêu thích sai thì bỏ cả lượt.
      const favoriteActions = resolvedFavorites.filter((action) => action !== null);
      const allFavoritesValid = favoriteActions.length === resolvedFavorites.length;
      return {
        ...parsed,
        responseType,
        // Thao tác bị loại thì không được giữ câu "đã thực hiện" của mô hình.
        reply: !allActionsValid
            ? rejectedCartReply(input.message)
            : !allFavoritesValid
            ? rejectedFavoriteReply(input.message)
            : safeReply(responseType, responseType === parsed.responseType, parsed.reply, input.message),
        // Không chuyển tiếp mã sản phẩm do mô hình tự tạo hoặc gắn vào loại phản hồi không tư vấn.
        suggestedProductIds: isAnswer || isCart || isFavorite
          ? [...new Set(parsed.suggestedProductIds)].filter((id) => allowedProductIds.has(id))
          : [],
        actionDraft: isIncident ? parsed.actionDraft : null,
        cartActions: allActionsValid ? cartActions : [],
        favoriteActions: allFavoritesValid ? favoriteActions : [],
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

/**
 * Không tin mã sản phẩm do mô hình tự tạo: ADD chỉ nhận sản phẩm trong catalog đã truy hồi,
 * UPDATE/REMOVE chỉ nhận sản phẩm đang có trong giỏ.
 */
function resolveCartAction(
  action: NonNullable<z.infer<typeof providerResultSchema>["cartActions"]>[number],
  input: ChatbotProviderInput
): ChatbotCartAction | null {
  const cartItems = input.cartItems ?? [];
  const productId = action.productId ?? null;
  const inCart = cartItems.some((item) => item.productId === productId);
  switch (action.type) {
    case "ADD":
      return input.catalogProducts.some((product) => product.id === productId)
        ? { type: "ADD", productId, quantity: action.quantity ?? 1 }
        : null;
    case "UPDATE":
      return inCart && action.quantity
        ? { type: "UPDATE", productId, quantity: action.quantity }
        : null;
    case "REMOVE":
      return inCart ? { type: "REMOVE", productId, quantity: null } : null;
    case "CLEAR":
      return cartItems.length > 0 ? { type: "CLEAR", productId: null, quantity: null } : null;
  }
}

function rejectedCartReply(message: string): string {
  return isLikelyVietnamese(message)
    ? "Mình chưa xác định được sản phẩm cần thao tác trong giỏ hàng. Bạn nói rõ tên sản phẩm giúp mình nhé."
    : "I couldn't identify the product to change in your cart. Please tell me its exact name.";
}

/**
 * Không tin mã sản phẩm do mô hình tự tạo: ADD chỉ nhận sản phẩm trong catalog đã truy hồi,
 * REMOVE chỉ nhận sản phẩm đang yêu thích, CLEAR chỉ khi danh sách không rỗng.
 */
function resolveFavoriteAction(
  action: NonNullable<z.infer<typeof providerResultSchema>["favoriteActions"]>[number],
  input: ChatbotProviderInput
): ChatbotFavoriteAction | null {
  const favorites = input.favoriteItems ?? [];
  const productId = action.productId ?? null;
  switch (action.type) {
    case "ADD":
      return input.catalogProducts.some((product) => product.id === productId)
        ? { type: "ADD", productId }
        : null;
    case "REMOVE":
      return favorites.some((item) => item.productId === productId)
        ? { type: "REMOVE", productId }
        : null;
    case "CLEAR":
      return favorites.length > 0 ? { type: "CLEAR", productId: null } : null;
  }
}

function rejectedFavoriteReply(message: string): string {
  return isLikelyVietnamese(message)
    ? "Mình chưa xác định được sản phẩm cần thao tác trong danh sách yêu thích. Bạn nói rõ tên sản phẩm giúp mình nhé."
    : "I couldn't identify the product to change in your favorites. Please tell me its exact name.";
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
      ? "Xin lỗi, tôi chỉ có thể hỗ trợ về sản phẩm và dịch vụ của cửa hàng."
      : "Sorry, I can only help with the store's products and services.";
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
    // Giới hạn: chỉ phủ phiên âm phổ biến của nhà cung cấp hiện tại; thêm tên khi đổi provider.
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
