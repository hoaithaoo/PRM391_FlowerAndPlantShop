import { z } from "zod";

export const updateProfileSchema = z.object({
  fullName: z
    .string()
    .min(1, "Họ và tên phải có ít nhất 1 ký tự.")
    .max(100, "Họ và tên không được vượt quá 100 ký tự.")
    .optional(),
  phone: z
    .string()
    .regex(/^(0|\+84)[3|5|7|8|9][0-9]{8}$/, "Số điện thoại không đúng định dạng Việt Nam.")
    .optional(),
  avatarUrl: z
    .string()
    .url("avatarUrl phải là một URL hợp lệ.")
    .nullable()
    .optional(),
});

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;
