import { Prisma, PrismaClient } from "@prisma/client";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { env } from "../../config/env";
import { prisma } from "../../lib/prisma";
import type { AdminListReviewsQuery, CreateReviewInput, PageQuery } from "./review.schema";

const REVIEW_BUCKET = "review-images";

const publicReviewSelect = {
  id: true,
  rating: true,
  comment: true,
  imageUrls: true,
  createdAt: true,
  user: { select: { fullName: true, avatarUrl: true } },
} satisfies Prisma.ProductReviewSelect;

const myReviewSelect = {
  id: true,
  orderId: true,
  productId: true,
  rating: true,
  comment: true,
  imageUrls: true,
  createdAt: true,
} satisfies Prisma.ProductReviewSelect;

const adminReviewSelect = {
  ...myReviewSelect,
  isHidden: true,
  product: { select: { id: true, name: true } },
  order: { select: { orderNumber: true } },
  user: { select: { fullName: true, email: true } },
} satisfies Prisma.ProductReviewSelect;

const round1 = (value: number | null) => Math.round((value ?? 0) * 10) / 10;

const pageMeta = (query: PageQuery, total: number) => ({
  page: query.page,
  limit: query.limit,
  total,
  totalPages: Math.ceil(total / query.limit),
});

export class ReviewService {
  /** storageBaseUrl = `${SUPABASE_URL}/storage/v1/object/public`; tách ra để test không cần env thật. */
  constructor(
    private readonly db: PrismaClient = prisma,
    private readonly storageBaseUrl: string = `${env.SUPABASE_URL.replace(/\/$/, "")}/storage/v1/object/public`
  ) {}

  async create(userId: string, input: CreateReviewInput) {
    // Ảnh phải nằm trong thư mục của chính khách trên bucket review-images.
    const allowedPrefix = `${this.storageBaseUrl}/${REVIEW_BUCKET}/${userId}/`;
    if (input.imageUrls.some((url) => !url.startsWith(allowedPrefix))) {
      throw new AppError(400, ErrorCodes.VALIDATION_ERROR, "Ảnh đánh giá không hợp lệ.");
    }

    const order = await this.db.order.findFirst({
      where: { id: input.orderId, userId },
      select: { status: true, items: { where: { productId: input.productId }, select: { id: true } } },
    });
    if (!order) throw new AppError(404, ErrorCodes.ORDER_NOT_FOUND, "Không tìm thấy đơn hàng.");
    if (order.status !== "COMPLETED") {
      throw new AppError(409, ErrorCodes.REVIEW_NOT_ALLOWED, "Chỉ đánh giá được khi đơn đã hoàn tất.");
    }
    if (order.items.length === 0) {
      throw new AppError(409, ErrorCodes.REVIEW_NOT_ALLOWED, "Sản phẩm không có trong đơn này.");
    }

    try {
      return await this.db.productReview.create({
        data: {
          userId,
          orderId: input.orderId,
          productId: input.productId,
          rating: input.rating,
          comment: input.comment || null,
          imageUrls: input.imageUrls,
        },
        select: myReviewSelect,
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2002") {
        throw new AppError(409, ErrorCodes.REVIEW_ALREADY_EXISTS, "Bạn đã đánh giá sản phẩm này trong đơn.");
      }
      throw error;
    }
  }

  /** Đánh giá của khách trong một đơn, để app biết món nào đã đánh giá. */
  async listMineForOrder(userId: string, orderId: string) {
    return this.db.productReview.findMany({
      where: { userId, orderId },
      select: myReviewSelect,
      orderBy: { createdAt: "asc" },
    });
  }

  async listForProduct(productId: string, query: PageQuery) {
    const where: Prisma.ProductReviewWhereInput = { productId, isHidden: false };
    const [stats, items] = await Promise.all([
      this.db.productReview.aggregate({ where, _avg: { rating: true }, _count: { _all: true } }),
      this.db.productReview.findMany({
        where,
        select: publicReviewSelect,
        skip: (query.page - 1) * query.limit,
        take: query.limit,
        orderBy: [{ createdAt: "desc" }, { id: "desc" }],
      }),
    ]);
    const total = stats._count._all;
    return {
      items,
      summary: { averageRating: round1(stats._avg.rating), totalReviews: total },
      meta: pageMeta(query, total),
    };
  }

  async adminList(query: AdminListReviewsQuery) {
    const search = query.search;
    const where: Prisma.ProductReviewWhereInput = {
      ...(query.rating ? { rating: query.rating } : {}),
      ...(query.hidden !== undefined ? { isHidden: query.hidden } : {}),
      ...(search
        ? {
            OR: [
              { comment: { contains: search, mode: "insensitive" } },
              { product: { name: { contains: search, mode: "insensitive" } } },
              { order: { orderNumber: { contains: search, mode: "insensitive" } } },
              { user: { email: { contains: search, mode: "insensitive" } } },
            ],
          }
        : {}),
    };
    const [total, items, stats] = await Promise.all([
      this.db.productReview.count({ where }),
      this.db.productReview.findMany({
        where,
        select: adminReviewSelect,
        skip: (query.page - 1) * query.limit,
        take: query.limit,
        orderBy: [{ createdAt: "desc" }, { id: "desc" }],
      }),
      this.db.productReview.aggregate({ where: { isHidden: false }, _avg: { rating: true }, _count: { _all: true } }),
    ]);
    return {
      items,
      meta: { ...pageMeta(query, total), averageRating: round1(stats._avg.rating), visibleReviews: stats._count._all },
    };
  }

  async setHidden(id: string, isHidden: boolean) {
    try {
      return await this.db.productReview.update({ where: { id }, data: { isHidden }, select: adminReviewSelect });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2025") {
        throw new AppError(404, ErrorCodes.REVIEW_NOT_FOUND, "Không tìm thấy đánh giá.");
      }
      throw error;
    }
  }
}

export const reviewService = new ReviewService();
