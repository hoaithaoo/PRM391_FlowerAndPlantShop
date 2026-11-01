import {
  Prisma,
  PrismaClient,
  Voucher,
  VoucherScope,
  VoucherType,
} from "@prisma/client";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { prisma } from "../../lib/prisma";
import { calculateDiscount } from "./voucher-pricing";
import {
  AvailableVoucherItem,
  AvailableVouchersResponse,
  ValidateVoucherResponse,
  VoucherEvaluationResult,
  VoucherPreview,
} from "./voucher.type";

type VoucherDatabase = Pick<PrismaClient, "voucher" | "voucherRedemption" | "cart">;

/** Voucher ship giảm trên phí ship; đơn tối thiểu của mọi loại vẫn tính theo tiền hàng. */
const discountOf = (
  voucher: Voucher,
  subtotal: Prisma.Decimal,
  shippingFee: Prisma.Decimal
): Prisma.Decimal =>
  calculateDiscount(
    voucher,
    voucher.scope === VoucherScope.SHIPPING ? shippingFee : subtotal
  );

export class VoucherService {
  constructor(private readonly db: VoucherDatabase = prisma) {}

  /**
   * Tính tạm tính của giỏ hàng trên server. Chỉ tính các sản phẩm isActive.
   * Giỏ trống hoặc không tồn tại trả về 0.
   */
  async getCartSubtotal(
    tx: Prisma.TransactionClient | VoucherDatabase,
    userId: string
  ): Promise<Prisma.Decimal> {
    const cart = await tx.cart.findUnique({
      where: { userId },
      include: {
        items: {
          include: {
            product: {
              select: {
                id: true,
                price: true,
                isActive: true,
              },
            },
          },
        },
      },
    });

    if (!cart || !cart.items.length) {
      return new Prisma.Decimal(0);
    }

    return cart.items
      .filter((item) => item.product.isActive)
      .reduce(
        (total, item) => total.add(item.product.price.times(item.quantity)),
        new Prisma.Decimal(0)
      );
  }

  /**
   * Hàm kiểm tra dùng chung cho available, validate và checkout.
   * 4 điều kiện kiểm tra theo đúng thứ tự quy định:
   * 1. Voucher tồn tại và isActive = true -> VOUCHER_NOT_FOUND
   * 2. startsAt <= now < endsAt -> VOUCHER_EXPIRED
   * 3. usedCount < usageLimit và userRedemptions < perUserLimit -> VOUCHER_USAGE_EXCEEDED
   * 4. subtotal >= minOrderAmount -> VOUCHER_MIN_ORDER_NOT_MET
   */
  async evaluateVoucher(
    voucher: Voucher,
    userId: string,
    subtotal: Prisma.Decimal,
    now: Date,
    tx: Prisma.TransactionClient | VoucherDatabase,
    shippingFee: Prisma.Decimal = new Prisma.Decimal(0)
  ): Promise<VoucherEvaluationResult> {
    // 1. Voucher active
    if (!voucher.isActive) {
      return {
        eligible: false,
        discountAmount: new Prisma.Decimal(0),
        reasonCode: ErrorCodes.VOUCHER_NOT_FOUND,
        ineligibleReason: "Mã voucher không tồn tại hoặc đã ngừng áp dụng.",
        missingAmount: 0,
      };
    }

    // 2. Thời hạn hiệu lực: startsAt <= now < endsAt
    if (now < voucher.startsAt || now >= voucher.endsAt) {
      return {
        eligible: false,
        discountAmount: new Prisma.Decimal(0),
        reasonCode: ErrorCodes.VOUCHER_EXPIRED,
        ineligibleReason: "Voucher đã hết hạn sử dụng.",
        missingAmount: 0,
      };
    }

    // 3. Lượt sử dụng
    if (voucher.usageLimit !== null && voucher.usedCount >= voucher.usageLimit) {
      return {
        eligible: false,
        discountAmount: new Prisma.Decimal(0),
        reasonCode: ErrorCodes.VOUCHER_USAGE_EXCEEDED,
        ineligibleReason: "Voucher đã hết tổng lượt sử dụng.",
        missingAmount: 0,
      };
    }

    const activeUserRedemptions = await tx.voucherRedemption.count({
      where: {
        voucherId: voucher.id,
        userId,
        releasedAt: null,
      },
    });

    if (activeUserRedemptions >= voucher.perUserLimit) {
      return {
        eligible: false,
        discountAmount: new Prisma.Decimal(0),
        reasonCode: ErrorCodes.VOUCHER_USAGE_EXCEEDED,
        ineligibleReason: "Bạn đã dùng hết số lượt cho phép của voucher này.",
        missingAmount: 0,
      };
    }

    // 4. Giá trị đơn tối thiểu
    if (subtotal.lessThan(voucher.minOrderAmount)) {
      const missing = Number(voucher.minOrderAmount.minus(subtotal).toString());
      const missingAmount = missing > 0 ? missing : 0;
      const formattedMissing = new Intl.NumberFormat("vi-VN").format(missingAmount);
      return {
        eligible: false,
        discountAmount: new Prisma.Decimal(0),
        reasonCode: ErrorCodes.VOUCHER_MIN_ORDER_NOT_MET,
        ineligibleReason: `Mua thêm ${formattedMissing}đ để dùng`,
        missingAmount,
      };
    }

    // Đạt đủ điều kiện: tính discount
    const discountAmount = discountOf(voucher, subtotal, shippingFee);
    return {
      eligible: true,
      discountAmount,
      reasonCode: null,
      ineligibleReason: null,
      missingAmount: 0,
    };
  }

  /**
   * GET /api/v1/vouchers/available
   * Trả voucher public, active, còn hạn, còn tổng lượt và user chưa dùng hết.
   * Chưa đủ đơn tối thiểu vẫn trả với eligible = false.
   * Chỉ để xem trước: [preview] do app gửi, checkout mới tính lại số thật.
   */
  async getAvailableVouchers(
    userId: string,
    preview: VoucherPreview = {}
  ): Promise<AvailableVouchersResponse> {
    const now = new Date();
    const subtotal = await this.previewSubtotal(userId, preview);
    const shippingFee = new Prisma.Decimal(preview.shippingFee ?? 0);

    // Lọc voucher public, active, còn hạn
    const candidates = await this.db.voucher.findMany({
      where: {
        isPublic: true,
        isActive: true,
        startsAt: { lte: now },
        endsAt: { gt: now },
      },
    });

    const evaluatedItems: AvailableVoucherItem[] = [];

    for (const voucher of candidates) {
      // Bỏ qua nếu đã hết tổng lượt
      if (voucher.usageLimit !== null && voucher.usedCount >= voucher.usageLimit) {
        continue;
      }

      // Đếm số lần user đã dùng chưa trả
      const userRedemptions = await this.db.voucherRedemption.count({
        where: {
          voucherId: voucher.id,
          userId,
          releasedAt: null,
        },
      });

      if (userRedemptions >= voucher.perUserLimit) {
        continue;
      }

      const evalResult = await this.evaluateVoucher(
        voucher,
        userId,
        subtotal,
        now,
        this.db,
        shippingFee
      );

      // Nếu không eligible vì lý do khác VOUCHER_MIN_ORDER_NOT_MET thì bỏ qua
      if (!evalResult.eligible && evalResult.reasonCode !== ErrorCodes.VOUCHER_MIN_ORDER_NOT_MET) {
        continue;
      }

      const calculatedDiscount = discountOf(voucher, subtotal, shippingFee);

      evaluatedItems.push({
        code: voucher.code,
        type: voucher.type,
        scope: voucher.scope,
        value: Number(voucher.value.toString()),
        maxDiscount: voucher.maxDiscount ? Number(voucher.maxDiscount.toString()) : null,
        minOrderAmount: Number(voucher.minOrderAmount.toString()),
        endsAt: voucher.endsAt,
        eligible: evalResult.eligible,
        discountAmount: evalResult.eligible
          ? Number(evalResult.discountAmount.toString())
          : Number(calculatedDiscount.toString()),
        ineligibleReason: evalResult.ineligibleReason,
        missingAmount: evalResult.missingAmount,
      });
    }

    // Sắp xếp: eligible trước, rồi discountAmount giảm dần, rồi endsAt tăng dần
    evaluatedItems.sort((a, b) => {
      if (a.eligible !== b.eligible) {
        return a.eligible ? -1 : 1;
      }
      if (b.discountAmount !== a.discountAmount) {
        return b.discountAmount - a.discountAmount;
      }
      return a.endsAt.getTime() - b.endsAt.getTime();
    });

    return {
      items: evaluatedItems,
      subtotal: Number(subtotal.toString()),
    };
  }

  /**
   * POST /api/v1/vouchers/validate
   * Không giữ lượt, không ghi database.
   * Áp dụng được cả mã isPublic = false.
   */
  async validateVoucher(
    userId: string,
    rawCode: string,
    preview: VoucherPreview = {}
  ): Promise<ValidateVoucherResponse> {
    const code = rawCode.trim().toUpperCase();
    const now = new Date();

    const voucher = await this.db.voucher.findUnique({
      where: { code },
    });

    if (!voucher || !voucher.isActive) {
      throw new AppError(
        404,
        ErrorCodes.VOUCHER_NOT_FOUND,
        "Mã voucher không tồn tại."
      );
    }

    const subtotal = await this.previewSubtotal(userId, preview);

    const evalResult = await this.evaluateVoucher(
      voucher,
      userId,
      subtotal,
      now,
      this.db,
      new Prisma.Decimal(preview.shippingFee ?? 0)
    );

    if (!evalResult.eligible) {
      switch (evalResult.reasonCode) {
        case ErrorCodes.VOUCHER_EXPIRED:
          throw new AppError(
            422,
            ErrorCodes.VOUCHER_EXPIRED,
            "Voucher đã hết hạn."
          );
        case ErrorCodes.VOUCHER_USAGE_EXCEEDED:
          throw new AppError(
            409,
            ErrorCodes.VOUCHER_USAGE_EXCEEDED,
            "Voucher đã hết lượt sử dụng."
          );
        case ErrorCodes.VOUCHER_MIN_ORDER_NOT_MET:
          throw new AppError(
            422,
            ErrorCodes.VOUCHER_MIN_ORDER_NOT_MET,
            "Đơn hàng chưa đạt giá trị tối thiểu của voucher.",
            { missingAmount: evalResult.missingAmount }
          );
        default:
          throw new AppError(
            404,
            ErrorCodes.VOUCHER_NOT_FOUND,
            "Mã voucher không tồn tại."
          );
      }
    }

    return {
      code: voucher.code,
      type: voucher.type,
      scope: voucher.scope,
      value: Number(voucher.value.toString()),
      maxDiscount: voucher.maxDiscount
        ? Number(voucher.maxDiscount.toString())
        : null,
      discountAmount: Number(evalResult.discountAmount.toString()),
      subtotal: Number(subtotal.toString()),
    };
  }

  /** Mua ngay không dùng giỏ nên app gửi tạm tính của sản phẩm đang mua. */
  private previewSubtotal(
    userId: string,
    preview: VoucherPreview
  ): Promise<Prisma.Decimal> {
    return preview.subtotal === undefined
      ? this.getCartSubtotal(this.db, userId)
      : Promise.resolve(new Prisma.Decimal(preview.subtotal));
  }

  // Admin APIs
  async adminList(query: {
    page: number;
    limit: number;
    search?: string;
    isActive?: boolean;
    isPublic?: boolean;
  }) {
    const where: Prisma.VoucherWhereInput = {
      ...(query.search
        ? { code: { contains: query.search.trim().toUpperCase() } }
        : {}),
      ...(query.isActive !== undefined ? { isActive: query.isActive } : {}),
      ...(query.isPublic !== undefined ? { isPublic: query.isPublic } : {}),
    };

    const [total, items] = await Promise.all([
      this.db.voucher.count({ where }),
      this.db.voucher.findMany({
        where,
        skip: (query.page - 1) * query.limit,
        take: query.limit,
        orderBy: { createdAt: "desc" },
      }),
    ]);

    return {
      items: items.map((item) => ({
        ...item,
        value: Number(item.value.toString()),
        maxDiscount: item.maxDiscount ? Number(item.maxDiscount.toString()) : null,
        minOrderAmount: Number(item.minOrderAmount.toString()),
      })),
      pagination: {
        page: query.page,
        limit: query.limit,
        total,
        totalPages: Math.ceil(total / query.limit),
      },
    };
  }

  async adminGetById(id: string) {
    const voucher = await this.db.voucher.findUnique({
      where: { id },
    });

    if (!voucher) {
      throw new AppError(
        404,
        ErrorCodes.VOUCHER_NOT_FOUND,
        "Voucher không tồn tại."
      );
    }

    return {
      ...voucher,
      value: Number(voucher.value.toString()),
      maxDiscount: voucher.maxDiscount ? Number(voucher.maxDiscount.toString()) : null,
      minOrderAmount: Number(voucher.minOrderAmount.toString()),
    };
  }

  async adminCreate(data: {
    code: string;
    type: VoucherType;
    scope?: VoucherScope;
    value: number;
    maxDiscount?: number | null;
    minOrderAmount?: number;
    startsAt: Date;
    endsAt: Date;
    usageLimit?: number | null;
    perUserLimit?: number;
    isPublic?: boolean;
    isActive?: boolean;
  }) {
    const existing = await this.db.voucher.findUnique({
      where: { code: data.code },
    });

    if (existing) {
      throw new AppError(
        409,
        ErrorCodes.VOUCHER_CODE_EXISTS,
        "Mã voucher đã tồn tại."
      );
    }

    const created = await this.db.voucher.create({
      data: {
        code: data.code,
        type: data.type,
        scope: data.scope ?? VoucherScope.ORDER,
        value: new Prisma.Decimal(data.value),
        maxDiscount: data.maxDiscount != null ? new Prisma.Decimal(data.maxDiscount) : null,
        minOrderAmount: new Prisma.Decimal(data.minOrderAmount ?? 0),
        startsAt: data.startsAt,
        endsAt: data.endsAt,
        usageLimit: data.usageLimit ?? null,
        perUserLimit: data.perUserLimit ?? 1,
        isPublic: data.isPublic ?? true,
        isActive: data.isActive ?? true,
      },
    });

    return {
      ...created,
      value: Number(created.value.toString()),
      maxDiscount: created.maxDiscount ? Number(created.maxDiscount.toString()) : null,
      minOrderAmount: Number(created.minOrderAmount.toString()),
    };
  }

  async adminUpdate(
    id: string,
    data: {
      maxDiscount?: number | null;
      minOrderAmount?: number;
      startsAt?: Date;
      endsAt?: Date;
      usageLimit?: number | null;
      perUserLimit?: number;
      isPublic?: boolean;
      isActive?: boolean;
    }
  ) {
    const existing = await this.db.voucher.findUnique({ where: { id } });
    if (!existing) {
      throw new AppError(
        404,
        ErrorCodes.VOUCHER_NOT_FOUND,
        "Voucher không tồn tại."
      );
    }

    if (existing.type === VoucherType.FIXED && data.maxDiscount !== undefined && data.maxDiscount !== null) {
      throw new AppError(
        400,
        ErrorCodes.BAD_REQUEST,
        "Voucher cố định không được có maxDiscount."
      );
    }

    const updated = await this.db.voucher.update({
      where: { id },
      data: {
        ...(data.maxDiscount !== undefined
          ? { maxDiscount: data.maxDiscount != null ? new Prisma.Decimal(data.maxDiscount) : null }
          : {}),
        ...(data.minOrderAmount !== undefined
          ? { minOrderAmount: new Prisma.Decimal(data.minOrderAmount) }
          : {}),
        ...(data.startsAt !== undefined ? { startsAt: data.startsAt } : {}),
        ...(data.endsAt !== undefined ? { endsAt: data.endsAt } : {}),
        ...(data.usageLimit !== undefined ? { usageLimit: data.usageLimit } : {}),
        ...(data.perUserLimit !== undefined ? { perUserLimit: data.perUserLimit } : {}),
        ...(data.isPublic !== undefined ? { isPublic: data.isPublic } : {}),
        ...(data.isActive !== undefined ? { isActive: data.isActive } : {}),
      },
    });

    return {
      ...updated,
      value: Number(updated.value.toString()),
      maxDiscount: updated.maxDiscount ? Number(updated.maxDiscount.toString()) : null,
      minOrderAmount: Number(updated.minOrderAmount.toString()),
    };
  }

  async adminDelete(id: string) {
    const existing = await this.db.voucher.findUnique({ where: { id } });
    if (!existing) {
      throw new AppError(
        404,
        ErrorCodes.VOUCHER_NOT_FOUND,
        "Voucher không tồn tại."
      );
    }

    const redemptionsCount = await this.db.voucherRedemption.count({
      where: { voucherId: id },
    });

    if (redemptionsCount > 0) {
      throw new AppError(
        409,
        ErrorCodes.VOUCHER_IN_USE,
        "Không thể xóa voucher đã có lượt sử dụng. Vui lòng tắt kích hoạt."
      );
    }

    await this.db.voucher.delete({ where: { id } });
  }
}

export const voucherService = new VoucherService();
