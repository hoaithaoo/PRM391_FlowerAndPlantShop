import { Role, UserStatus } from "@prisma/client";
import { z } from "zod";
import { limitSchema, pageSchema } from "../../common/utils/pagination";

const uuidSchema = z.string().uuid("ID phải là UUID hợp lệ.");

export const userIdParamsSchema = z.object({ id: uuidSchema }).strict();

export const adminListUsersQuerySchema = z
  .object({
    page: pageSchema,
    limit: limitSchema,
    search: z.string().trim().min(1).max(100).optional(),
    role: z.nativeEnum(Role).optional(),
    status: z.nativeEnum(UserStatus).optional(),
  })
  .strict();

export const adminUpdateUserSchema = z
  .object({
    role: z.nativeEnum(Role).optional(),
    status: z.nativeEnum(UserStatus).optional(),
  })
  .strict()
  .refine((value) => value.role !== undefined || value.status !== undefined, {
    message: "Cần gửi ít nhất role hoặc status.",
  });

export type AdminListUsersQuery = z.infer<typeof adminListUsersQuerySchema>;
export type AdminUpdateUserInput = z.infer<typeof adminUpdateUserSchema>;
