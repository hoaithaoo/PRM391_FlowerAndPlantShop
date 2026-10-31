import { OrderStatus, PaymentStatus } from "@prisma/client";
import { z } from "zod";
import { limitSchema, pageSchema } from "../../common/utils/pagination";

const uuidSchema = z.string().uuid("ID phải là UUID hợp lệ.");

export const orderIdParamsSchema = z.object({ id: uuidSchema }).strict();

export const listMyOrdersQuerySchema = z
  .object({
    page: pageSchema,
    limit: limitSchema,
    status: z.nativeEnum(OrderStatus).optional(),
  })
  .strict();

export const cancelOrderSchema = z
  .object({
    reason: z.string().trim().max(500).nullable().optional(),
  })
  .strict()
  .default({});

export const adminListOrdersQuerySchema = z
  .object({
    page: pageSchema,
    limit: limitSchema,
    status: z.nativeEnum(OrderStatus).optional(),
    paymentStatus: z.nativeEnum(PaymentStatus).optional(),
    search: z.string().trim().min(1).max(100).optional(),
  })
  .strict();

export const adminUpdateOrderStatusSchema = z
  .object({
    status: z.enum([
      OrderStatus.CONFIRMED,
      OrderStatus.PREPARING,
      OrderStatus.SHIPPING,
      OrderStatus.COMPLETED,
      OrderStatus.CANCELLED,
    ]),
    note: z.string().trim().max(500).nullable().optional(),
  })
  .strict();

export type ListMyOrdersQuery = z.infer<typeof listMyOrdersQuerySchema>;
export type CancelOrderInput = z.infer<typeof cancelOrderSchema>;
export type AdminListOrdersQuery = z.infer<typeof adminListOrdersQuerySchema>;
export type AdminUpdateOrderStatusInput = z.infer<
  typeof adminUpdateOrderStatusSchema
>;
