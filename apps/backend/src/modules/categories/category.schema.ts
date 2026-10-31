import { z } from "zod";

const uuidSchema = z.string().uuid("ID phải là UUID hợp lệ.");
const slugSchema = z
  .string()
  .trim()
  .toLowerCase()
  .min(1)
  .max(180)
  .regex(
    /^[a-z0-9]+(?:-[a-z0-9]+)*$/,
    "Slug chỉ gồm chữ thường không dấu, số và dấu gạch ngang."
  );
const imageUrlSchema = z
  .string()
  .trim()
  .url("Ảnh danh mục phải là một URL hợp lệ.")
  .nullable()
  .optional();

export const categoryIdParamsSchema = z
  .object({ id: uuidSchema })
  .strict();

export const listCategoriesQuerySchema = z
  .object({
    search: z.string().trim().min(1).max(100).optional(),
  })
  .strict();

// Không dùng .strict() cho body: admin app gửi kèm id/description/sortOrder
// (chưa có cột tương ứng), các field thừa sẽ bị bỏ qua.
export const createCategorySchema = z.object({
  name: z.string().trim().min(1).max(120),
  slug: slugSchema,
  imageUrl: imageUrlSchema,
  isActive: z.boolean().optional().default(true),
});

export const updateCategorySchema = z.object({
  name: z.string().trim().min(1).max(120),
  slug: slugSchema,
  imageUrl: imageUrlSchema,
  // Spec yêu cầu isActive, nhưng admin app hiện chưa gửi nên giữ nguyên nếu thiếu.
  isActive: z.boolean().optional(),
});

export type ListCategoriesQuery = z.infer<typeof listCategoriesQuerySchema>;
export type CreateCategoryInput = z.infer<typeof createCategorySchema>;
export type UpdateCategoryInput = z.infer<typeof updateCategorySchema>;
