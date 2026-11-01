import { Prisma, VoucherScope, VoucherType } from "@prisma/client";
import { ErrorCode } from "../../common/errors/error-codes";

/** Số app gửi để xem trước; thiếu subtotal thì tính theo giỏ hàng. */
export interface VoucherPreview {
  subtotal?: number;
  shippingFee?: number;
}

export interface VoucherEvaluationResult {
  eligible: boolean;
  discountAmount: Prisma.Decimal;
  reasonCode: ErrorCode | null;
  ineligibleReason: string | null;
  missingAmount: number;
}

export interface AvailableVoucherItem {
  code: string;
  type: VoucherType;
  scope: VoucherScope;
  value: number;
  maxDiscount: number | null;
  minOrderAmount: number;
  endsAt: Date;
  eligible: boolean;
  discountAmount: number;
  ineligibleReason: string | null;
  missingAmount: number;
}

export interface AvailableVouchersResponse {
  items: AvailableVoucherItem[];
  subtotal: number;
}

export interface ValidateVoucherResponse {
  code: string;
  type: VoucherType;
  scope: VoucherScope;
  value: number;
  maxDiscount: number | null;
  discountAmount: number;
  subtotal: number;
}

