import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { Prisma, VoucherType } from "@prisma/client";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { VoucherService } from "./voucher.service";

describe("VoucherService Admin Operations", () => {
  it("adminDelete throws VOUCHER_IN_USE if voucher has redemptions", async () => {
    const fakePrisma = {
      voucher: {
        findUnique: async () => ({ id: "v-1", code: "HOA50K" }),
      },
      voucherRedemption: {
        count: async () => 1,
      },
    } as any;
    const service = new VoucherService(fakePrisma);

    await assert.rejects(
      service.adminDelete("v-1"),
      (err: any) => {
        assert.ok(err instanceof AppError);
        assert.equal(err.statusCode, 409);
        assert.equal(err.code, ErrorCodes.VOUCHER_IN_USE);
        return true;
      }
    );
  });

  it("adminCreate throws VOUCHER_CODE_EXISTS if voucher code already exists", async () => {
    const fakePrisma = {
      voucher: {
        findUnique: async () => ({ id: "v-1", code: "HOA50K" }),
      },
    } as any;
    const service = new VoucherService(fakePrisma);

    await assert.rejects(
      service.adminCreate({
        code: "HOA50K",
        type: VoucherType.FIXED,
        value: 50000,
        startsAt: new Date(),
        endsAt: new Date(Date.now() + 86400000),
      }),
      (err: any) => {
        assert.ok(err instanceof AppError);
        assert.equal(err.statusCode, 409);
        assert.equal(err.code, ErrorCodes.VOUCHER_CODE_EXISTS);
        return true;
      }
    );
  });
});
