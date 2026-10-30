import { z } from "zod";

export const paymentIdParamsSchema = z
  .object({
    id: z.string().uuid("ID thanh toán phải là UUID hợp lệ."),
  })
  .strict();

export type PaymentIdParams = z.infer<typeof paymentIdParamsSchema>;
