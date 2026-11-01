import { z } from "zod";

export const loginSchema = z
  .object({
    email: z.string().trim().toLowerCase().email("Email không hợp lệ."),
    password: z.string().min(1, "Mật khẩu không được để trống.").max(200),
  })
  .strict();

export const refreshSchema = z
  .object({
    refreshToken: z.string().trim().min(1),
  })
  .strict();

export type LoginInput = z.infer<typeof loginSchema>;
export type RefreshInput = z.infer<typeof refreshSchema>;
