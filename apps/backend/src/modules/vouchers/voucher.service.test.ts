import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { Prisma, VoucherType } from "@prisma/client";
import { ErrorCodes } from "../../common/errors/error-codes";
import { VoucherService } from "./voucher.service";

describe("VoucherService.evaluateVoucher", () => {
  const service = new VoucherService();
  const now = new Date("2026-11-02T12:00:00.000Z");

  const baseVoucher = {
    id: "voucher-1",
    code: "TEST50K",
    type: VoucherType.FIXED,
    value: new Prisma.Decimal("50000"),
    maxDiscount: null,
    minOrderAmount: new Prisma.Decimal("200000"),
    startsAt: new Date("2026-11-01T00:00:00.000Z"),
    endsAt: new Date("2026-11-30T00:00:00.000Z"),
    usageLimit: 100,
    perUserLimit: 1,
    usedCount: 0,
    isPublic: true,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  };

  it("fails if voucher is inactive", async () => {
    const voucher = { ...baseVoucher, isActive: false };
    const mockTx = {
      voucherRedemption: { count: async () => 0 },
    } as any;

    const res = await service.evaluateVoucher(
      voucher,
      "user-1",
      new Prisma.Decimal("250000"),
      now,
      mockTx
    );

    assert.equal(res.eligible, false);
    assert.equal(res.reasonCode, ErrorCodes.VOUCHER_NOT_FOUND);
  });

  it("fails if voucher has expired", async () => {
    const voucher = {
      ...baseVoucher,
      endsAt: new Date("2026-11-01T00:00:00.000Z"),
    };
    const mockTx = {
      voucherRedemption: { count: async () => 0 },
    } as any;

    const res = await service.evaluateVoucher(
      voucher,
      "user-1",
      new Prisma.Decimal("250000"),
      now,
      mockTx
    );

    assert.equal(res.eligible, false);
    assert.equal(res.reasonCode, ErrorCodes.VOUCHER_EXPIRED);
  });

  it("fails if voucher usage limit is exceeded", async () => {
    const voucher = {
      ...baseVoucher,
      usageLimit: 10,
      usedCount: 10,
    };
    const mockTx = {
      voucherRedemption: { count: async () => 0 },
    } as any;

    const res = await service.evaluateVoucher(
      voucher,
      "user-1",
      new Prisma.Decimal("250000"),
      now,
      mockTx
    );

    assert.equal(res.eligible, false);
    assert.equal(res.reasonCode, ErrorCodes.VOUCHER_USAGE_EXCEEDED);
  });

  it("fails if user exceeded perUserLimit", async () => {
    const mockTx = {
      voucherRedemption: { count: async () => 1 },
    } as any;

    const res = await service.evaluateVoucher(
      baseVoucher,
      "user-1",
      new Prisma.Decimal("250000"),
      now,
      mockTx
    );

    assert.equal(res.eligible, false);
    assert.equal(res.reasonCode, ErrorCodes.VOUCHER_USAGE_EXCEEDED);
  });

  it("allows usage if previous redemptions were released (releasedAt not null)", async () => {
    // When querying count in tx, where releasedAt: null returns 0
    const mockTx = {
      voucherRedemption: {
        count: async (args: any) => {
          assert.equal(args.where.releasedAt, null);
          return 0;
        },
      },
    } as any;

    const res = await service.evaluateVoucher(
      baseVoucher,
      "user-1",
      new Prisma.Decimal("250000"),
      now,
      mockTx
    );

    assert.equal(res.eligible, true);
    assert.equal(res.discountAmount.toString(), "50000");
  });

  it("fails if subtotal < minOrderAmount and calculates missingAmount", async () => {
    const mockTx = {
      voucherRedemption: { count: async () => 0 },
    } as any;

    const res = await service.evaluateVoucher(
      baseVoucher,
      "user-1",
      new Prisma.Decimal("150000"),
      now,
      mockTx
    );

    assert.equal(res.eligible, false);
    assert.equal(res.reasonCode, ErrorCodes.VOUCHER_MIN_ORDER_NOT_MET);
    assert.equal(res.missingAmount, 50000);
    assert.match(res.ineligibleReason ?? "", /50\.000đ/);
  });

  it("succeeds when all conditions are satisfied", async () => {
    const mockTx = {
      voucherRedemption: { count: async () => 0 },
    } as any;

    const res = await service.evaluateVoucher(
      baseVoucher,
      "user-1",
      new Prisma.Decimal("300000"),
      now,
      mockTx
    );

    assert.equal(res.eligible, true);
    assert.equal(res.discountAmount.toString(), "50000");
    assert.equal(res.missingAmount, 0);
    assert.equal(res.ineligibleReason, null);
  });
});

