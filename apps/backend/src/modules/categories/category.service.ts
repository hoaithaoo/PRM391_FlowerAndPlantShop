import { Prisma } from "@prisma/client";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { prisma } from "../../lib/prisma";
import {
  CreateCategoryInput,
  ListCategoriesQuery,
  UpdateCategoryInput,
} from "./category.schema";

const categorySelect = {
  id: true,
  name: true,
  slug: true,
  imageUrl: true,
  isActive: true,
} satisfies Prisma.CategorySelect;

const notFound = () =>
  new AppError(
    404,
    ErrorCodes.CATEGORY_NOT_FOUND,
    "Không tìm thấy danh mục sản phẩm."
  );

const slugExists = () =>
  new AppError(
    409,
    ErrorCodes.CATEGORY_SLUG_EXISTS,
    "Slug danh mục đã tồn tại."
  );

const inUse = () =>
  new AppError(
    409,
    ErrorCodes.CATEGORY_IN_USE,
    "Danh mục vẫn còn sản phẩm; hãy chuyển sản phẩm hoặc ẩn bằng isActive=false."
  );

export class CategoryService {
  async list(query: ListCategoriesQuery, options: { includeInactive: boolean }) {
    const where: Prisma.CategoryWhereInput = {
      ...(!options.includeInactive && { isActive: true }),
      ...(query.search && {
        name: { contains: query.search, mode: "insensitive" as const },
      }),
    };

    return prisma.category.findMany({
      where,
      orderBy: { name: "asc" },
      select: categorySelect,
    });
  }

  async create(input: CreateCategoryInput) {
    await this.assertSlugAvailable(input.slug);

    try {
      return await prisma.category.create({
        data: {
          name: input.name,
          slug: input.slug,
          imageUrl: input.imageUrl ?? null,
          isActive: input.isActive,
        },
        select: categorySelect,
      });
    } catch (error) {
      this.handleWriteError(error);
      throw error;
    }
  }

  async update(id: string, input: UpdateCategoryInput) {
    const existing = await prisma.category.findUnique({
      where: { id },
      select: { id: true },
    });
    if (!existing) throw notFound();

    await this.assertSlugAvailable(input.slug, id);

    try {
      return await prisma.category.update({
        where: { id },
        data: {
          name: input.name,
          slug: input.slug,
          ...(input.imageUrl !== undefined && { imageUrl: input.imageUrl }),
          ...(input.isActive !== undefined && { isActive: input.isActive }),
        },
        select: categorySelect,
      });
    } catch (error) {
      this.handleWriteError(error);
      throw error;
    }
  }

  async delete(id: string): Promise<void> {
    const category = await prisma.category.findUnique({
      where: { id },
      select: { id: true, _count: { select: { products: true } } },
    });
    if (!category) throw notFound();
    if (category._count.products > 0) throw inUse();

    try {
      await prisma.category.delete({ where: { id } });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === "P2003"
      ) {
        throw inUse();
      }
      this.handleWriteError(error);
      throw error;
    }
  }

  private async assertSlugAvailable(
    slug: string,
    excludedId?: string
  ): Promise<void> {
    const category = await prisma.category.findFirst({
      where: { slug, ...(excludedId && { id: { not: excludedId } }) },
      select: { id: true },
    });
    if (category) throw slugExists();
  }

  private handleWriteError(error: unknown): void {
    if (!(error instanceof Prisma.PrismaClientKnownRequestError)) return;
    if (error.code === "P2002") throw slugExists();
    if (error.code === "P2025") throw notFound();
  }
}

export const categoryService = new CategoryService();
