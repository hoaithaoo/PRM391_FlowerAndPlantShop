import { PrismaClient } from "@prisma/client";
import { prisma as defaultPrisma } from "../../lib/prisma";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { mapSummary, productSummarySelect } from "../products/product.service";

export class FavoriteService {
  private readonly prisma: PrismaClient;

  constructor(deps: { prisma?: PrismaClient } = {}) {
    this.prisma = deps.prisma ?? defaultPrisma;
  }

  async list(profileId: string) {
    const favorites = await this.prisma.favorite.findMany({
      where: { profileId, product: { isActive: true } },
      orderBy: [{ createdAt: "desc" }, { id: "desc" }],
      select: { createdAt: true, product: { select: productSummarySelect } },
    });
    return favorites.map(({ product, createdAt }) => ({
      ...mapSummary(product),
      favoritedAt: createdAt,
    }));
  }

  async listIds(profileId: string): Promise<string[]> {
    const favorites = await this.prisma.favorite.findMany({
      where: { profileId, product: { isActive: true } },
      orderBy: [{ createdAt: "desc" }, { id: "desc" }],
      select: { productId: true },
    });
    return favorites.map(({ productId }) => productId);
  }

  async add(profileId: string, productId: string) {
    const product = await this.prisma.product.findUnique({
      where: { id: productId },
      select: { id: true },
    });
    if (!product) {
      throw new AppError(404, ErrorCodes.PRODUCT_NOT_FOUND, "Không tìm thấy sản phẩm.");
    }
    // Bỏ qua bản ghi trùng ngay tại DB, kể cả khi hai yêu cầu đến cùng lúc.
    await this.prisma.favorite.createMany({
      data: [{ profileId, productId }],
      skipDuplicates: true,
    });
    return { productId };
  }

  async remove(profileId: string, productId: string): Promise<void> {
    // Chỉ xoá của người hiện tại; chưa lưu yêu thích vẫn thành công.
    await this.prisma.favorite.deleteMany({ where: { profileId, productId } });
  }
}

export const favoriteService = new FavoriteService();
