import { IncidentCategory, IncidentStatus } from "@prisma/client";
import { z } from "zod";

// Body khách gửi khi tạo phiếu. orderId tùy chọn: sự cố có thể không gắn đơn nào.
export const createIncidentSchema = z
  .object({
    category: z.nativeEnum(IncidentCategory),
    title: z.string().trim().min(3, "Tiêu đề tối thiểu 3 ký tự").max(120),
    description: z.string().trim().min(10, "Mô tả tối thiểu 10 ký tự").max(2000),
    orderId: z.string().uuid().nullable().optional(),
  })
  .strict();

// Query phân trang + lọc; dùng chung cho khách và admin (category/search chỉ admin dùng).
export const listIncidentsQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  status: z.nativeEnum(IncidentStatus).optional(),
  category: z.nativeEnum(IncidentCategory).optional(),
  search: z.string().trim().min(1).optional(),
});

export const incidentIdParamsSchema = z.object({
  id: z.string().uuid("ID phiếu không hợp lệ"),
});

// Body admin cập nhật phiếu: trạng thái bắt buộc, ghi chú phản hồi tùy chọn.
export const updateIncidentSchema = z
  .object({
    status: z.nativeEnum(IncidentStatus),
    adminNote: z.string().trim().max(2000).nullable().optional(),
  })
  .strict();

export type CreateIncidentInput = z.infer<typeof createIncidentSchema>;
export type ListIncidentsQuery = z.infer<typeof listIncidentsQuerySchema>;
export type UpdateIncidentInput = z.infer<typeof updateIncidentSchema>;
