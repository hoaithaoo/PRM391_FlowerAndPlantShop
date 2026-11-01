// cspell:disable
import { z } from "zod";

/**
 * Validation schemas for cart item operations and their corresponding input types.
 */
const uuidSchema = z.string().uuid("ID phải là UUID hợp lệ.");

const quantitySchema = z
  .number()
  .int("Số lượng phải là số nguyên.")
  .min(1, "Số lượng phải ít nhất là 1.")
  .max(2147483647, "Số lượng vượt quá giới hạn cho phép.");

export const cartItemIdParamsSchema = z
  .object({
    id: uuidSchema,
  })
  .strict();

export const addCartItemSchema = z
  .object({
    productId: uuidSchema,
    quantity: quantitySchema,
  })
  .strict();

export const updateCartItemSchema = z
  .object({
    quantity: quantitySchema,
  })
  .strict();

export type AddCartItemInput = z.infer<typeof addCartItemSchema>;
export type UpdateCartItemInput = z.infer<typeof updateCartItemSchema>;
