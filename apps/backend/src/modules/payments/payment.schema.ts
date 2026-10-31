import { PaymentMethod, PaymentStatus } from "@prisma/client";
import { z } from "zod";
import { limitSchema, pageSchema } from "../../common/utils/pagination";

export const paymentIdParamsSchema = z
  .object({
    id: z.string().uuid("ID thanh toán phải là UUID hợp lệ."),
  })
  .strict();

export type PaymentIdParams = z.infer<typeof paymentIdParamsSchema>;

const booleanQuerySchema = z
  .enum(["true", "false"])
  .transform((value) => value === "true");

export const adminListPaymentsQuerySchema = z
  .object({
    page: pageSchema,
    limit: limitSchema,
    status: z.nativeEnum(PaymentStatus).optional(),
    provider: z.nativeEnum(PaymentMethod).optional(),
    search: z.string().trim().min(1).max(100).optional(),
  })
  .strict();

export const adminListSepayTransactionsQuerySchema = z
  .object({
    page: pageSchema,
    limit: limitSchema,
    matched: booleanQuerySchema.optional(),
    search: z.string().trim().min(1).max(100).optional(),
  })
  .strict();

export const sepayTransactionIdParamsSchema = paymentIdParamsSchema;

export const adminMatchSepayTransactionSchema = z
  .object({
    orderCode: z.string().trim().min(1).max(100),
  })
  .strict();

export type AdminListPaymentsQuery = z.infer<typeof adminListPaymentsQuerySchema>;
export type AdminListSepayTransactionsQuery = z.infer<
  typeof adminListSepayTransactionsQuerySchema
>;
export type AdminMatchSepayTransactionInput = z.infer<
  typeof adminMatchSepayTransactionSchema
>;
