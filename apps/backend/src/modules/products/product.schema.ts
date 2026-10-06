import { z } from "zod";

const uuidSchema = z.string().uuid("ID phải là UUID hợp lệ.");
const moneySchema = z
  .number()
  .int("Giá tiền phải là số nguyên VND.")
  .positive("Giá tiền phải lớn hơn 0.")
  .safe("Giá tiền vượt quá giới hạn an toàn.");
const imageUrlsSchema = z
  .array(z.string().url("Mỗi ảnh phải là một URL hợp lệ."))
  .max(10, "Sản phẩm không được có quá 10 ảnh.");
const taxRateSchema = z
  .number()
  .min(0)
  .max(100)
  .multipleOf(0.01, "Thuế suất chỉ được có tối đa 2 chữ số thập phân.");

export const productIdParamsSchema = z
  .object({ id: uuidSchema })
  .strict();

export const listProductsQuerySchema = z
  .object({
    page: z.coerce.number().int().min(1).default(1),
    limit: z.coerce.number().int().min(1).max(100).default(20),
    search: z.string().trim().min(1).max(100).optional(),
    categoryId: uuidSchema.optional(),
    minPrice: z.coerce.number().int().min(0).safe().optional(),
    maxPrice: z.coerce.number().int().min(0).safe().optional(),
    sort: z.enum(["price_asc", "price_desc", "newest"]).default("newest"),
  })
  .strict()
  .refine(
    ({ minPrice, maxPrice }) =>
      minPrice === undefined || maxPrice === undefined || minPrice <= maxPrice,
    {
      message: "minPrice không được lớn hơn maxPrice.",
      path: ["minPrice"],
    }
  );

export const createProductSchema = z
  .object({
    sku: z.string().trim().min(1).max(100),
    name: z.string().trim().min(1).max(200),
    description: z.string().trim().max(5000).nullable().optional(),
    price: moneySchema,
    stock: z.number().int().min(0),
    taxRate: taxRateSchema,
    categoryId: uuidSchema,
    imageUrls: imageUrlsSchema.optional().default([]),
    isActive: z.boolean().optional().default(true),
  })
  .strict();

export const updateProductSchema = z
  .object({
    sku: z.string().trim().min(1).max(100),
    name: z.string().trim().min(1).max(200),
    description: z.string().trim().max(5000).nullable().optional(),
    price: moneySchema,
    stock: z.number().int().min(0),
    taxRate: taxRateSchema,
    categoryId: uuidSchema,
    imageUrls: imageUrlsSchema.optional(),
    isActive: z.boolean(),
  })
  .strict();

export type ListProductsQuery = z.infer<typeof listProductsQuerySchema>;
export type CreateProductInput = z.infer<typeof createProductSchema>;
export type UpdateProductInput = z.infer<typeof updateProductSchema>;
