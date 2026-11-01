import { Prisma, Voucher, VoucherType } from "@prisma/client";
import { ErrorCode } from "../../common/errors/error-codes";

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
  discountAmount: number;
  subtotal: number;
}

