import { z } from "zod";
import { PaymentMethod } from "@prisma/client";

export const checkoutSchema = z
  .object({
    receiverName: z
      .string()
      .trim()
      .min(1, "Tên người nhận không được để trống.")
      .max(100, "Tên người nhận không được vượt quá 100 ký tự."),
    phone: z
      .string()
      .trim()
      .regex(
        /^(0|\+84)[35789][0-9]{8}$/,
        "Số điện thoại Việt Nam không hợp lệ."
      ),
    address: z
      .string()
      .trim()
      .min(1, "Địa chỉ không được để trống.")
      .max(200, "Địa chỉ không được vượt quá 200 ký tự."),
    latitude: z
      .number()
      .min(-90, "Vĩ độ không hợp lệ.")
      .max(90, "Vĩ độ không hợp lệ."),
    longitude: z
      .number()
      .min(-180, "Kinh độ không hợp lệ.")
      .max(180, "Kinh độ không hợp lệ."),
    paymentMethod: z.nativeEnum(PaymentMethod, {
      errorMap: () => ({
        message: "Phương thức thanh toán không hợp lệ; chỉ chấp nhận COD hoặc SEPAY.",
      }),
    }),
    note: z
      .string()
      .trim()
      .max(500, "Ghi chú không được vượt quá 500 ký tự.")
      .nullable()
      .optional(),
  })
  .strict();

export const idempotencyKeySchema = z
  .string()
  .trim()
  .min(1, "Idempotency-Key không được để trống.")
  .max(200, "Idempotency-Key không được vượt quá 200 ký tự.");

export type CheckoutInput = z.infer<typeof checkoutSchema>;
