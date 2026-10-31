import { InvoiceStatus } from "@prisma/client";
import { z } from "zod";
import { limitSchema, pageSchema } from "../../common/utils/pagination";

const uuidSchema = z.string().uuid("ID phải là UUID hợp lệ.");

export const invoiceIdParamsSchema = z.object({ id: uuidSchema }).strict();

export const listMyInvoicesQuerySchema = z
  .object({
    page: pageSchema,
    limit: limitSchema,
    status: z.nativeEnum(InvoiceStatus).optional(),
  })
  .strict();

export const adminListInvoicesQuerySchema = z
  .object({
    page: pageSchema,
    limit: limitSchema,
    status: z.nativeEnum(InvoiceStatus).optional(),
    search: z.string().trim().min(1).max(100).optional(),
  })
  .strict();

export type ListMyInvoicesQuery = z.infer<typeof listMyInvoicesQuerySchema>;
export type AdminListInvoicesQuery = z.infer<typeof adminListInvoicesQuerySchema>;
