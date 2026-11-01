import { Prisma, VoucherType } from "@prisma/client";

export interface VoucherPricingInput {
  type: VoucherType | "PERCENT" | "FIXED";
  value: Prisma.Decimal;
  maxDiscount?: Prisma.Decimal | null;
}

/**
 * Tính số tiền giảm giá từ voucher và subtotal.
 * Luôn dùng Prisma.Decimal, không dùng số thực JS.
 * - FIXED: value
 * - PERCENT: floor(subtotal * value / 100), chặn bởi maxDiscount nếu có.
 * - Luôn chặn tối đa bằng subtotal.
 */
export function calculateDiscount(
  voucher: VoucherPricingInput,
  subtotal: Prisma.Decimal
): Prisma.Decimal {
  if (subtotal.isZero() || subtotal.lessThan(0)) {
    return new Prisma.Decimal(0);
  }

  let discount: Prisma.Decimal;

  if (voucher.type === "FIXED") {
    discount = new Prisma.Decimal(voucher.value);
  } else {
    // PERCENT: floor(subtotal * value / 100)
    discount = subtotal.times(voucher.value).dividedBy(100).floor();
    if (voucher.maxDiscount != null && voucher.maxDiscount.greaterThan(0)) {
      if (discount.greaterThan(voucher.maxDiscount)) {
        discount = new Prisma.Decimal(voucher.maxDiscount);
      }
    }
  }

  // Luôn chặn tối đa bằng subtotal
  if (discount.greaterThan(subtotal)) {
    discount = subtotal;
  }

  if (discount.lessThan(0)) {
    discount = new Prisma.Decimal(0);
  }

  return discount.floor();
}

/**
 * Chia giảm giá cho từng dòng theo tỷ lệ bằng làm tròn cộng dồn:
 * alloc_i = floor(D * cum_i / S) - floor(D * cum_(i-1) / S)
 * Đảm bảo tổng đúng bằng D và không dòng nào âm.
 */
export function allocateDiscount(
  discount: Prisma.Decimal,
  lineSubtotals: Prisma.Decimal[]
): Prisma.Decimal[] {
  if (lineSubtotals.length === 0) {
    return [];
  }

  if (discount.isZero() || discount.lessThan(0)) {
    return lineSubtotals.map(() => new Prisma.Decimal(0));
  }

  const S = lineSubtotals.reduce(
    (acc, val) => acc.add(val),
    new Prisma.Decimal(0)
  );

  if (S.isZero() || S.lessThan(0)) {
    return lineSubtotals.map(() => new Prisma.Decimal(0));
  }

  // D không vượt quá S
  const D = discount.greaterThan(S) ? S : discount;

  const allocations: Prisma.Decimal[] = [];
  let cum_i = new Prisma.Decimal(0);
  let prevAlloc = new Prisma.Decimal(0);

  for (let i = 0; i < lineSubtotals.length; i++) {
    cum_i = cum_i.add(lineSubtotals[i]!);
    const cumAlloc = D.times(cum_i).dividedBy(S).floor();
    const alloc_i = cumAlloc.minus(prevAlloc);
    prevAlloc = cumAlloc;
    allocations.push(alloc_i);
  }

  return allocations;
}
