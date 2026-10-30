import { z } from "zod";

const optionalTextSchema = z.preprocess(
  (value) =>
    typeof value === "string" && value.trim().length === 0 ? null : value,
  z.string().trim().min(1).nullable().optional()
);

const transactionDateSchema = z
  .string()
  .trim()
  .min(1)
  .refine((value) => !Number.isNaN(Date.parse(value.replace(" ", "T"))), {
    message: "Thời gian giao dịch không hợp lệ.",
  })
  .optional();

export const sepayWebhookSchema = z
  .object({
    id: z
      .union([
        z.string().trim().min(1),
        z.number().int().safe().nonnegative(),
      ])
      .transform((value) => String(value)),
    gateway: optionalTextSchema,
    transactionDate: transactionDateSchema,
    accountNumber: optionalTextSchema,
    code: optionalTextSchema,
    content: optionalTextSchema,
    transferType: z
      .enum(["in", "out"])
      .transform((value) => (value === "in" ? "IN" : "OUT") as "IN" | "OUT"),
    transferAmount: z.number().int().safe().positive(),
    referenceCode: optionalTextSchema,
  })
  .passthrough();

export type SepayWebhookInput = z.infer<typeof sepayWebhookSchema>;
