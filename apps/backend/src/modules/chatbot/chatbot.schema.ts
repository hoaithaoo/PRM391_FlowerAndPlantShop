import { z } from "zod";

const optionalNullableUuid = z.string().uuid().nullable().optional();

/**
 * Body của POST /messages: message (1–2000 ký tự), conversationId để nối tiếp cuộc trò chuyện,
 * productId khi hỏi về một sản phẩm cụ thể, và context (orderId/paymentId) khi báo sự cố.
 * Dùng .strict() để từ chối trường lạ.
 */
export const sendChatbotMessageSchema = z
  .object({
    conversationId: optionalNullableUuid,
    message: z.string().trim().min(1).max(2000),
    productId: optionalNullableUuid,
    context: z
      .object({
        orderId: optionalNullableUuid,
        paymentId: optionalNullableUuid,
        source: z.string().trim().min(1).max(100).nullable().optional(),
      })
      .strict()
      .optional(),
  })
  .strict();

/**
 * Params :id của conversation, bắt buộc là UUID.
 */
export const conversationParamsSchema = z.object({ id: z.string().uuid() }).strict();

/**
 * Query ?page= của lịch sử tin nhắn, số nguyên ≥ 1, mặc định 1.
 */
export const historyQuerySchema = z
  .object({
    page: z.coerce.number().int().min(1).default(1),
  })
  .strict();

export type SendChatbotMessageInput = z.infer<typeof sendChatbotMessageSchema>;
export type ConversationParams = z.infer<typeof conversationParamsSchema>;
export type HistoryQuery = z.infer<typeof historyQuerySchema>;
