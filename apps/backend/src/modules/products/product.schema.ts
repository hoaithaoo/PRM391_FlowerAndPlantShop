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

export const adminListProductsQuerySchema = z
  .object({
    page: z.coerce.number().int().min(1).default(1),
    limit: z.coerce.number().int().min(1).max(100).default(20),
    search: z.string().trim().min(1).max(100).optional(),
    categoryId: uuidSchema.optional(),
    // Admin app gửi `category` thay cho `categoryId`.
    category: uuidSchema.optional(),
    isActive: z
      .enum(["true", "false"])
      .transform((value) => value === "true")
      .optional(),
  })
  .strict();

// Body không dùng .strict(): admin app gửi kèm id/slug/categoryName/salePrice,
// các field thừa bị bỏ qua. `imageUrl` đơn lẻ được nhận như một phần tử của imageUrls.
const productBodyBase = {
  name: z.string().trim().min(1).max(200),
  description: z.string().trim().max(5000).nullable().optional(),
  price: moneySchema,
  stock: z.number().int().min(0),
  categoryId: uuidSchema,
  imageUrls: imageUrlsSchema.optional(),
  imageUrl: z.string().url("Ảnh phải là một URL hợp lệ.").nullable().optional(),
};

const resolveImageUrls = <T extends { imageUrls?: string[]; imageUrl?: string | null }>({
  imageUrl,
  ...rest
}: T) => ({
  ...rest,
  imageUrls:
    rest.imageUrls ??
    (imageUrl === undefined ? undefined : imageUrl === null ? [] : [imageUrl]),
});

export const createProductSchema = z
  .object({
    ...productBodyBase,
    // SKU tự sinh nếu thiếu; thuế suất mặc định 0%.
    sku: z.string().trim().min(1).max(100).optional(),
    taxRate: taxRateSchema.optional().default(0),
    isActive: z.boolean().optional().default(true),
  })
  .transform(resolveImageUrls);

export const updateProductSchema = z
  .object({
    ...productBodyBase,
    // Thiếu sku/taxRate/isActive thì giữ nguyên giá trị hiện tại.
    sku: z.string().trim().min(1).max(100).optional(),
    taxRate: taxRateSchema.optional(),
    isActive: z.boolean().optional(),
  })
  .transform(resolveImageUrls);

export type ListProductsQuery = z.infer<typeof listProductsQuerySchema>;
export type AdminListProductsQuery = z.infer<typeof adminListProductsQuerySchema>;
export type CreateProductInput = z.infer<typeof createProductSchema>;
export type UpdateProductInput = z.infer<typeof updateProductSchema>;
