import { z } from "zod";

export const pageSchema = z.coerce.number().int().min(1).safe().default(1);
export const limitSchema = z.coerce.number().int().min(1).max(100).default(20);

export interface PageQuery {
  page: number;
  limit: number;
}

export const toSkipTake = ({ page, limit }: PageQuery) => ({
  skip: (page - 1) * limit,
  take: limit,
});

export const toPageMeta = ({ page, limit }: PageQuery, total: number) => ({
  page,
  limit,
  total,
  totalPages: Math.ceil(total / limit),
});
