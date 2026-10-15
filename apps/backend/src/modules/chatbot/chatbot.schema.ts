import { z } from "zod";

const optionalNullableUuid = z.string().uuid().nullable().optional();

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

export const conversationParamsSchema = z.object({ id: z.string().uuid() }).strict();

export const historyQuerySchema = z
  .object({
    page: z.coerce.number().int().min(1).default(1),
  })
  .strict();

export type SendChatbotMessageInput = z.infer<typeof sendChatbotMessageSchema>;
export type ConversationParams = z.infer<typeof conversationParamsSchema>;
export type HistoryQuery = z.infer<typeof historyQuerySchema>;
