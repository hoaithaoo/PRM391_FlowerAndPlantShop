import { z } from "zod";

const vietnamesePhoneRegex = /^(0|\+84)(3|5|7|8|9)[0-9]{8}$/;

export const createAddressSchema = z
  .object({
    recipientName: z
      .string({ required_error: "Tên người nhận là bắt buộc." })
      .trim()
      .min(1, "Tên người nhận không được để trống.")
      .max(100, "Tên người nhận tối đa 100 ký tự."),
    recipientPhone: z
      .string()
      .trim()
      .regex(vietnamesePhoneRegex, "Số điện thoại không đúng định dạng Việt Nam (ví dụ: 0901234567).")
      .optional(),
    phone: z
      .string()
      .trim()
      .regex(vietnamesePhoneRegex, "Số điện thoại không đúng định dạng Việt Nam (ví dụ: 0901234567).")
      .optional(),
    addressLine: z.string().trim().optional(),
    address: z.string().trim().optional(),
    label: z.string().trim().max(50).optional().default("Nhà riêng"),
    deliveryNote: z.string().trim().max(255).optional(),
    driverNote: z.string().trim().max(255).optional(),
    isDefault: z.boolean().default(true),
    latitude: z.number().min(-90).max(90).optional(),
    longitude: z.number().min(-180).max(180).optional(),
  })
  .superRefine((data, ctx) => {
    // Validate phone
    const hasPhone = Boolean(data.recipientPhone || data.phone);
    if (!hasPhone) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ["recipientPhone"],
        message: "Số điện thoại người nhận là bắt buộc.",
      });
    }

    // Validate address
    const hasAddress = Boolean(data.addressLine || data.address);
    if (!hasAddress) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ["addressLine"],
        message: "Vui lòng nhập địa chỉ cụ thể.",
      });
    }
  });

export const updateAddressSchema = z.object({
  recipientName: z.string().trim().min(1).max(100).optional(),
  recipientPhone: z.string().trim().regex(vietnamesePhoneRegex, "Số điện thoại không đúng định dạng.").optional(),
  phone: z.string().trim().regex(vietnamesePhoneRegex, "Số điện thoại không đúng định dạng.").optional(),
  addressLine: z.string().trim().optional(),
  address: z.string().trim().optional(),
  label: z.string().trim().max(50).optional(),
  deliveryNote: z.string().trim().max(255).optional(),
  driverNote: z.string().trim().max(255).optional(),
  isDefault: z.boolean().optional(),
  latitude: z.number().min(-90).max(90).optional(),
  longitude: z.number().min(-180).max(180).optional(),
});

export const addressIdParamSchema = z.object({
  id: z.string().uuid("ID địa chỉ phải là định dạng UUID hợp lệ."),
});

export type CreateAddressInput = z.infer<typeof createAddressSchema>;
export type UpdateAddressInput = z.infer<typeof updateAddressSchema>;
