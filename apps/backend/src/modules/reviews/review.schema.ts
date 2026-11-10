import { z } from "zod";

export const MAX_REVIEW_IMAGES = 3;

// Body khách gửi đánh giá: 1 sản phẩm trong 1 đơn, 1–5 sao, bình luận và ảnh tùy chọn.
// imageUrls là link ảnh đã upload lên Supabase Storage (service kiểm tra đúng thư mục của khách).
export const createReviewSchema = z
  .object({
    orderId: z.string().uuid("ID đơn không hợp lệ"),
    productId: z.string().uuid("ID sản phẩm không hợp lệ"),
    rating: z.number().int().min(1, "Chọn từ 1 đến 5 sao").max(5, "Chọn từ 1 đến 5 sao"),
    comment: z.string().trim().max(1000).nullable().optional(),
    imageUrls: z.array(z.string().url()).max(MAX_REVIEW_IMAGES, `Tối đa ${MAX_REVIEW_IMAGES} ảnh`).default([]),
  })
  .strict();

const pageQuery = {
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
};

export const productReviewsParamsSchema = z.object({
  productId: z.string().uuid("ID sản phẩm không hợp lệ"),
});

export const listProductReviewsQuerySchema = z.object(pageQuery);

// Khách lấy đánh giá của mình trong 1 đơn để biết món nào đã đánh giá.
export const myReviewsQuerySchema = z.object({
  orderId: z.string().uuid("ID đơn không hợp lệ"),
});

// Admin lọc theo số sao, trạng thái ẩn ("true"/"false" từ query string), từ khóa.
export const adminListReviewsQuerySchema = z.object({
  ...pageQuery,
  rating: z.coerce.number().int().min(1).max(5).optional(),
  hidden: z
    .enum(["true", "false"])
    .transform((v) => v === "true")
    .optional(),
  search: z.string().trim().min(1).optional(),
});

export const reviewIdParamsSchema = z.object({
  id: z.string().uuid("ID đánh giá không hợp lệ"),
});

// Admin ẩn/hiện đánh giá (không xóa, để còn lịch sử).
export const updateReviewVisibilitySchema = z.object({ isHidden: z.boolean() }).strict();

export type CreateReviewInput = z.infer<typeof createReviewSchema>;
export type PageQuery = z.infer<typeof listProductReviewsQuerySchema>;
export type AdminListReviewsQuery = z.infer<typeof adminListReviewsQuerySchema>;
