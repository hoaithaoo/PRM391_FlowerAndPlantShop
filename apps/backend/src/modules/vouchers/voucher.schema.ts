import { z } from "zod";
import { VoucherScope, VoucherType } from "@prisma/client";

export const voucherCodeSchema = z
  .string()
  .trim()
  .toUpperCase()
  .min(3, "Mã voucher tối thiểu 3 ký tự")
  .max(32, "Mã voucher tối đa 32 ký tự")
  .regex(/^[A-Z0-9_-]+$/, "Mã voucher chỉ gồm chữ in hoa, số, dấu gạch dưới và gạch ngang");

const previewFields = {
  subtotal: z.coerce.number().int().min(0).optional(),
  shippingFee: z.coerce.number().int().min(0).optional(),
};

export const availableVouchersQuerySchema = z.object(previewFields);

export const validateVoucherSchema = z
  .object({
    code: voucherCodeSchema,
    ...previewFields,
  })
  .strict();

export const listAdminVouchersQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  search: z.string().trim().optional(),
  isActive: z
    .enum(["true", "false"])
    .transform((val) => val === "true")
    .optional(),
  isPublic: z
    .enum(["true", "false"])
    .transform((val) => val === "true")
    .optional(),
});

export const voucherIdParamsSchema = z.object({
  id: z.string().uuid("ID voucher không hợp lệ"),
});

export const createAdminVoucherSchema = z
  .object({
    code: voucherCodeSchema,
    type: z.nativeEnum(VoucherType),
    scope: z.nativeEnum(VoucherScope).default(VoucherScope.ORDER),
    value: z.coerce.number().int().positive("Giá trị voucher phải lớn hơn 0"),
    maxDiscount: z.coerce.number().int().positive("Giảm tối đa phải lớn hơn 0").nullable().optional(),
    minOrderAmount: z.coerce.number().int().min(0, "Đơn tối thiểu không âm").default(0),
    startsAt: z.coerce.date(),
    endsAt: z.coerce.date(),
    usageLimit: z.coerce.number().int().positive("Tổng lượt dùng phải lớn hơn 0").nullable().optional(),
    perUserLimit: z.coerce.number().int().positive("Lượt dùng mỗi người phải lớn hơn 0").default(1),
    isPublic: z.boolean().default(true),
    isActive: z.boolean().default(true),
  })
  .strict()
  .refine((data) => data.endsAt > data.startsAt, {
    message: "Thời gian kết thúc phải sau thời gian bắt đầu",
    path: ["endsAt"],
  })
  .refine(
    (data) => {
      if (data.type === VoucherType.PERCENT) {
        return data.value >= 1 && data.value <= 100;
      }
      return true;
    },
    {
      message: "Voucher phần trăm phải có giá trị từ 1 đến 100",
      path: ["value"],
    }
  )
  .refine(
    (data) => {
      if (data.type === VoucherType.FIXED) {
        return data.maxDiscount == null;
      }
      return true;
    },
    {
      message: "Voucher cố định không được có maxDiscount",
      path: ["maxDiscount"],
    }
  );

export const updateAdminVoucherSchema = z
  .object({
    maxDiscount: z.coerce.number().int().positive().nullable().optional(),
    minOrderAmount: z.coerce.number().int().min(0).optional(),
    startsAt: z.coerce.date().optional(),
    endsAt: z.coerce.date().optional(),
    usageLimit: z.coerce.number().int().positive().nullable().optional(),
    perUserLimit: z.coerce.number().int().positive().optional(),
    isPublic: z.boolean().optional(),
    isActive: z.boolean().optional(),
  })
  .strict()
  .refine(
    (data) => {
      if (data.startsAt && data.endsAt) {
        return data.endsAt > data.startsAt;
      }
      return true;
    },
    {
      message: "Thời gian kết thúc phải sau thời gian bắt đầu",
      path: ["endsAt"],
    }
  );

