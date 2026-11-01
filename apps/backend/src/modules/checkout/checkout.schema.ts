import { z } from "zod";
import { PaymentMethod } from "@prisma/client";
import { voucherCodeSchema } from "../vouchers/voucher.schema";

export const checkoutSchema = z.object({
    receiverName: z.string().trim().min(1, "Tên người nhận không được để trống.").max(100, "Tên người nhận không được vượt quá 100 ký tự."),
    phone: z.string().trim().regex(/^(0|\+84)[35789][0-9]{8}$/).refine((value) => value.length >= 10 && value.length <= 15, "Số điện thoại không hợp lệ. Vui lòng nhập số điện thoại hợp lệ từ 10 đến 15 chữ số, có thể bắt đầu bằng dấu +."),
    address: z.string().trim().min(1, "Địa chỉ không được để trống.").max(200, "Địa chỉ không được vượt quá 200 ký tự.").optional(),
    latitude: z.number().min(-90, "Vĩ độ không hợp lệ.").max(90, "Vĩ độ không hợp lệ.").optional(),
    longitude: z.number().min(-180, "Kinh độ không hợp lệ.").max(180, "Kinh độ không hợp lệ.").optional(),
    pickupStoreId: z.string().uuid("Cửa hàng nhận hoa không hợp lệ.").optional(),
    pickupAt: z.string().datetime({ offset: true, message: "Thời gian nhận hoa không hợp lệ." }).optional(),
    paymentMethod: z.enum([PaymentMethod.SEPAY, PaymentMethod.COD], {
      errorMap: () => ({
        message:
          "Phương thức thanh toán không hợp lệ. Vui lòng chọn COD hoặc SEPAY.",
      }),
    }),
    note: z.string().trim().max(500, "Ghi chú không được vượt quá 500 ký tự.").nullable().optional(),
    voucherCode: voucherCodeSchema.nullable().optional(),
    shippingVoucherCode: voucherCodeSchema.nullable().optional(),
    // Mua ngay: chỉ đặt sản phẩm này, giỏ hàng giữ nguyên.
    buyNow: z.object({
      productId: z.string().uuid("Sản phẩm không hợp lệ."),
      quantity: z.number().int().min(1, "Số lượng phải từ 1 trở lên.").max(100, "Số lượng không được vượt quá 100."),
    }).strict().optional(),
}).strict().superRefine((input, ctx) => {
    // Nhận tại quán lấy địa chỉ từ cửa hàng; giao hàng bắt buộc có địa chỉ và tọa độ.
    const required = input.pickupStoreId
      ? (["pickupAt"] as const)
      : (["address", "latitude", "longitude"] as const);
    for (const field of required) {
      if (input[field] === undefined) {
        ctx.addIssue({ code: z.ZodIssueCode.custom, path: [field], message: "Thông tin này là bắt buộc." });
      }
    }
});

export const idempotencyKeySchema = z
  .string()
  .trim()
  .min(1, "Idempotency-Key không được để trống.")
  .max(200, "Idempotency-Key không được vượt quá 200 ký tự.");

export type CheckoutInput = z.infer<typeof checkoutSchema>;
