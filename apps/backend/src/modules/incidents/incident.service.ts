import { randomUUID } from "node:crypto";
import { IncidentStatus, Prisma, PrismaClient } from "@prisma/client";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { prisma } from "../../lib/prisma";
import type { CreateIncidentInput, ListIncidentsQuery, UpdateIncidentInput } from "./incident.schema";

// Nhãn tiếng Việt của trạng thái, dùng ghép vào nội dung thông báo gửi khách.
const STATUS_LABELS: Record<IncidentStatus, string> = {
  OPEN: "đã tiếp nhận",
  IN_PROGRESS: "đang được xử lý",
  RESOLVED: "đã được giải quyết",
  REJECTED: "đã bị từ chối",
};

// Các cột trả cho khách (app mobile): thông tin phiếu + đơn liên quan.
const incidentSelect = {
  id: true,
  code: true,
  category: true,
  title: true,
  description: true,
  status: true,
  adminNote: true,
  resolvedAt: true,
  createdAt: true,
  updatedAt: true,
  order: { select: { id: true, orderNumber: true, status: true } },
} satisfies Prisma.IncidentReportSelect;

// Admin cần thêm thông tin người gửi để liên hệ.
const adminIncidentSelect = {
  ...incidentSelect,
  user: { select: { id: true, fullName: true, email: true, phone: true } },
} satisfies Prisma.IncidentReportSelect;

// Mã phiếu dễ đọc cho khách, dạng SC-YYYYMMDD-XXXXXX (6 ký tự ngẫu nhiên).
const createCode = (): string => {
  const date = new Date().toISOString().slice(0, 10).replaceAll("-", "");
  return `SC-${date}-${randomUUID().replaceAll("-", "").slice(0, 6).toUpperCase()}`;
};

const notFound = () => new AppError(404, ErrorCodes.INCIDENT_NOT_FOUND, "Không tìm thấy phiếu sự cố.");

/** Phiếu báo sự cố: khách gửi (từ chat hoặc chi tiết đơn), admin xử lý và phản hồi. */
export class IncidentService {
  constructor(private readonly db: PrismaClient = prisma) {}

  /** Khách tạo phiếu. Nếu gắn đơn thì đơn phải là của chính khách. */
  async create(userId: string, input: CreateIncidentInput) {
    if (input.orderId) {
      const order = await this.db.order.findFirst({
        where: { id: input.orderId, userId },
        select: { id: true },
      });
      if (!order) throw new AppError(404, ErrorCodes.ORDER_NOT_FOUND, "Không tìm thấy đơn hàng.");
    }

    return this.db.incidentReport.create({
      data: {
        code: createCode(),
        userId,
        orderId: input.orderId ?? null,
        category: input.category,
        title: input.title,
        description: input.description,
      },
      select: incidentSelect,
    });
  }

  /** Danh sách phiếu của khách đang đăng nhập, lọc theo trạng thái nếu có. */
  async listMine(userId: string, query: ListIncidentsQuery) {
    return this.page({ userId, ...(query.status ? { status: query.status } : {}) }, query, incidentSelect);
  }

  /** Admin xem tất cả phiếu: lọc trạng thái/loại, tìm theo mã phiếu, tiêu đề, mã đơn, email khách. */
  async adminList(query: ListIncidentsQuery) {
    const search = query.search;
    const where: Prisma.IncidentReportWhereInput = {
      ...(query.status ? { status: query.status } : {}),
      ...(query.category ? { category: query.category } : {}),
      ...(search
        ? {
            OR: [
              { code: { contains: search, mode: "insensitive" } },
              { title: { contains: search, mode: "insensitive" } },
              { order: { orderNumber: { contains: search, mode: "insensitive" } } },
              { user: { email: { contains: search, mode: "insensitive" } } },
            ],
          }
        : {}),
    };
    return this.page(where, query, adminIncidentSelect);
  }

  /**
   * Admin đổi trạng thái + ghi chú phản hồi.
   * Chạy trong transaction để cập nhật phiếu và tạo thông báo cùng thành công hoặc cùng thất bại.
   */
  async adminUpdate(id: string, input: UpdateIncidentInput) {
    return this.db.$transaction(async (tx) => {
      const current = await tx.incidentReport.findUnique({ where: { id }, select: { status: true } });
      if (!current) throw notFound();

      // Đóng phiếu (giải quyết/từ chối) thì ghi thời điểm; mở lại thì xóa thời điểm.
      const closed = input.status === "RESOLVED" || input.status === "REJECTED";
      const updated = await tx.incidentReport.update({
        where: { id },
        data: {
          status: input.status,
          ...(input.adminNote !== undefined ? { adminNote: input.adminNote || null } : {}),
          resolvedAt: closed ? new Date() : null,
        },
        select: adminIncidentSelect,
      });

      // Chỉ báo khách khi trạng thái đổi, tránh spam khi admin chỉ sửa ghi chú.
      if (current.status !== input.status) {
        await tx.notification.create({
          data: {
            userId: updated.user.id,
            type: "SYSTEM",
            title: "Cập nhật phiếu sự cố",
            message: `Phiếu ${updated.code} ${STATUS_LABELS[input.status]}.${updated.adminNote ? ` ${updated.adminNote}` : ""}`,
            data: { incidentId: updated.id, status: input.status },
          },
        });
      }
      return updated;
    });
  }

  /** Phân trang dùng chung: đếm tổng + lấy 1 trang, mới nhất trước. */
  private async page<S extends Prisma.IncidentReportSelect>(
    where: Prisma.IncidentReportWhereInput,
    query: ListIncidentsQuery,
    select: S
  ) {
    const [total, items] = await Promise.all([
      this.db.incidentReport.count({ where }),
      this.db.incidentReport.findMany({
        where,
        select,
        skip: (query.page - 1) * query.limit,
        take: query.limit,
        orderBy: [{ createdAt: "desc" }, { id: "desc" }],
      }),
    ]);
    return { items, meta: { page: query.page, limit: query.limit, total, totalPages: Math.ceil(total / query.limit) } };
  }
}

export const incidentService = new IncidentService();
