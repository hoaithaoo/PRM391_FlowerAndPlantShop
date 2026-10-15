import { Prisma } from "@prisma/client";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { prisma } from "../../lib/prisma";
import {
  CreateProductInput,
  ListProductsQuery,
  UpdateProductInput,
} from "./product.schema";

const productCategorySelect = {
  id: true,
  name: true,
} satisfies Prisma.CategorySelect;

const toNumber = (value: Prisma.Decimal): number => Number(value.toString());

const slugify = (value: string): string => {
  const slug = value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/đ/g, "d")
    .replace(/Đ/g, "D")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 180);

  return slug || "san-pham";
};

const mapSummary = (product: {
  id: string;
  sku: string;
  name: string;
  price: Prisma.Decimal;
  stock: number;
  imageUrl: string | null;
  category: { id: string; name: string };
}) => ({
  ...product,
  price: toNumber(product.price),
});

const mapDetail = (product: {
  id: string;
  sku: string;
  name: string;
  description: string | null;
  price: Prisma.Decimal;
  stock: number;
  taxRate: Prisma.Decimal;
  images: string[];
  isActive: boolean;
  category: { id: string; name: string };
}) => ({
  id: product.id,
  sku: product.sku,
  name: product.name,
  description: product.description,
  price: toNumber(product.price),
  stock: product.stock,
  taxRate: toNumber(product.taxRate),
  imageUrls: product.images,
  category: product.category,
  isActive: product.isActive,
});

const mapCreatedProduct = (product: {
  id: string;
  sku: string;
  name: string;
  price: Prisma.Decimal;
  stock: number;
  taxRate: Prisma.Decimal;
  categoryId: string;
  isActive: boolean;
}) => ({
  ...product,
  price: toNumber(product.price),
  taxRate: toNumber(product.taxRate),
});

const mapUpdatedProduct = (product: {
  id: string;
  sku: string;
  name: string;
  price: Prisma.Decimal;
  stock: number;
  updatedAt: Date;
}) => ({
  ...product,
  price: toNumber(product.price),
});

export class ProductService {
  async list(query: ListProductsQuery) {
    const where: Prisma.ProductWhereInput = {
      isActive: true,
      ...(query.categoryId && { categoryId: query.categoryId }),
      ...(query.search && {
        OR: [
          { name: { contains: query.search, mode: "insensitive" as const } },
          { sku: { contains: query.search, mode: "insensitive" as const } },
        ],
      }),
      ...((query.minPrice !== undefined || query.maxPrice !== undefined) && {
        price: {
          ...(query.minPrice !== undefined && {
            gte: new Prisma.Decimal(query.minPrice),
          }),
          ...(query.maxPrice !== undefined && {
            lte: new Prisma.Decimal(query.maxPrice),
          }),
        },
      }),
    };
    const orderBy: Prisma.ProductOrderByWithRelationInput =
      query.sort === "price_asc"
        ? { price: "asc" }
        : query.sort === "price_desc"
          ? { price: "desc" }
          : { createdAt: "desc" };

    const [products, total] = await prisma.$transaction([
      prisma.product.findMany({
        where,
        orderBy,
        skip: (query.page - 1) * query.limit,
        take: query.limit,
        select: {
          id: true,
          sku: true,
          name: true,
          price: true,
          stock: true,
          imageUrl: true,
          category: { select: productCategorySelect },
        },
      }),
      prisma.product.count({ where }),
    ]);

    return {
      items: products.map(mapSummary),
      page: query.page,
      total,
      totalPages: Math.ceil(total / query.limit),
    };
  }

  async getActiveById(id: string) {
    const product = await prisma.product.findFirst({
      where: { id, isActive: true },
      select: {
        id: true,
        sku: true,
        name: true,
        description: true,
        price: true,
        stock: true,
        taxRate: true,
        images: true,
        isActive: true,
        category: { select: productCategorySelect },
      },
    });

    if (!product) {
      throw new AppError(
        404,
        ErrorCodes.PRODUCT_NOT_FOUND,
        "Không tìm thấy sản phẩm."
      );
    }

    return mapDetail(product);
  }

  async create(input: CreateProductInput) {
    await this.assertCategoryExists(input.categoryId);
    await this.assertSkuAvailable(input.sku);
    const slug = await this.createUniqueSlug(input.name);

    try {
      const product = await prisma.product.create({
        data: {
          categoryId: input.categoryId,
          sku: input.sku,
          name: input.name,
          slug,
          description: input.description,
          price: new Prisma.Decimal(input.price.toString()),
          stock: input.stock,
          taxRate: new Prisma.Decimal(input.taxRate.toString()),
          imageUrl: input.imageUrls?.[0] ?? null,
          images: input.imageUrls ?? [],
          isActive: input.isActive,
        },
        select: {
          id: true,
          sku: true,
          name: true,
          price: true,
          stock: true,
          taxRate: true,
          categoryId: true,
          isActive: true,
        },
      });

      return mapCreatedProduct(product);
    } catch (error) {
      this.handleWriteError(error);
      throw error;
    }
  }

  async update(id: string, input: UpdateProductInput) {
    const existing = await prisma.product.findUnique({
      where: { id },
      select: { id: true, name: true, slug: true },
    });
    if (!existing) {
      throw new AppError(
        404,
        ErrorCodes.PRODUCT_NOT_FOUND,
        "Không tìm thấy sản phẩm."
      );
    }

    await this.assertCategoryExists(input.categoryId);
    await this.assertSkuAvailable(input.sku, id);
    const slug =
      input.name === existing.name
        ? existing.slug
        : await this.createUniqueSlug(input.name, id);

    try {
      const product = await prisma.product.update({
        where: { id },
        data: {
          categoryId: input.categoryId,
          sku: input.sku,
          name: input.name,
          slug,
          description: input.description,
          price: new Prisma.Decimal(input.price.toString()),
          stock: input.stock,
          taxRate: new Prisma.Decimal(input.taxRate.toString()),
          ...(input.imageUrls !== undefined && {
            imageUrl: input.imageUrls[0] ?? null,
            images: input.imageUrls,
          }),
          isActive: input.isActive,
        },
        select: {
          id: true,
          sku: true,
          name: true,
          price: true,
          stock: true,
          updatedAt: true,
        },
      });

      return mapUpdatedProduct(product);
    } catch (error) {
      this.handleWriteError(error);
      throw error;
    }
  }

  async delete(id: string): Promise<void> {
    const product = await prisma.product.findUnique({
      where: { id },
      select: {
        id: true,
        _count: {
          select: { cartItems: true, orderItems: true, invoiceItems: true },
        },
      },
    });

    if (!product) {
      throw new AppError(
        404,
        ErrorCodes.PRODUCT_NOT_FOUND,
        "Không tìm thấy sản phẩm."
      );
    }

    const isInUse = Object.values(product._count).some((count) => count > 0);
    if (isInUse) {
      throw new AppError(
        409,
        ErrorCodes.PRODUCT_IN_USE,
        "Sản phẩm đã được tham chiếu; hãy ngừng bán bằng isActive=false."
      );
    }

    try {
      await prisma.product.delete({ where: { id } });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === "P2003"
      ) {
        throw new AppError(
          409,
          ErrorCodes.PRODUCT_IN_USE,
          "Sản phẩm đã được tham chiếu; hãy ngừng bán bằng isActive=false."
        );
      }
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === "P2025"
      ) {
        throw new AppError(
          404,
          ErrorCodes.PRODUCT_NOT_FOUND,
          "Không tìm thấy sản phẩm."
        );
      }
      throw error;
    }
  }

  private async assertCategoryExists(categoryId: string): Promise<void> {
    const category = await prisma.category.findUnique({
      where: { id: categoryId },
      select: { id: true },
    });
    if (!category) {
      throw new AppError(
        404,
        ErrorCodes.CATEGORY_NOT_FOUND,
        "Không tìm thấy danh mục sản phẩm."
      );
    }
  }

  private async assertSkuAvailable(
    sku: string,
    excludedId?: string
  ): Promise<void> {
    const product = await prisma.product.findFirst({
      where: { sku, ...(excludedId && { id: { not: excludedId } }) },
      select: { id: true },
    });
    if (product) {
      throw new AppError(
        409,
        ErrorCodes.PRODUCT_SKU_EXISTS,
        "SKU sản phẩm đã tồn tại."
      );
    }
  }

  private async createUniqueSlug(
    name: string,
    excludedId?: string
  ): Promise<string> {
    const base = slugify(name);
    let candidate = base;

    for (let suffix = 2; suffix <= 1000; suffix += 1) {
      const existing = await prisma.product.findFirst({
        where: {
          slug: candidate,
          ...(excludedId && { id: { not: excludedId } }),
        },
        select: { id: true },
      });
      if (!existing) return candidate;
      candidate = `${base.slice(0, 175)}-${suffix}`;
    }

    return `${base.slice(0, 169)}-${Date.now()}`;
  }

  private handleWriteError(error: unknown): void {
    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === "P2002"
    ) {
      const target = Array.isArray(error.meta?.target)
        ? error.meta.target.map(String)
        : [String(error.meta?.target ?? "")];
      if (target.some((field) => field.includes("sku"))) {
        throw new AppError(
          409,
          ErrorCodes.PRODUCT_SKU_EXISTS,
          "SKU sản phẩm đã tồn tại."
        );
      }

      throw new AppError(
        409,
        ErrorCodes.TRANSACTION_CONFLICT,
        "Dữ liệu sản phẩm vừa bị thay đổi, vui lòng thử lại."
      );
    }

    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === "P2025"
    ) {
      throw new AppError(
        404,
        ErrorCodes.PRODUCT_NOT_FOUND,
        "Không tìm thấy sản phẩm."
      );
    }

    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === "P2003"
    ) {
      throw new AppError(
        404,
        ErrorCodes.CATEGORY_NOT_FOUND,
        "Không tìm thấy danh mục sản phẩm."
      );
    }
  }
}

export const productService = new ProductService();
