import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { Prisma } from "@prisma/client";
import {
  calculateDiscount,
  allocateDiscount,
} from "./voucher-pricing";

describe("voucher-pricing", () => {
  describe("calculateDiscount", () => {
    it("calculates PERCENT discount correctly", () => {
      const discount = calculateDiscount(
        {
          type: "PERCENT",
          value: new Prisma.Decimal(20),
        },
        new Prisma.Decimal(320000)
      );
      assert.equal(discount.toString(), "64000");
    });

    it("caps PERCENT discount with maxDiscount", () => {
      const discount = calculateDiscount(
        {
          type: "PERCENT",
          value: new Prisma.Decimal(20),
          maxDiscount: new Prisma.Decimal(50000),
        },
        new Prisma.Decimal(320000)
      );
      assert.equal(discount.toString(), "50000");
    });

    it("caps FIXED discount when greater than subtotal", () => {
      const discount = calculateDiscount(
        {
          type: "FIXED",
          value: new Prisma.Decimal(100000),
        },
        new Prisma.Decimal(75000)
      );
      assert.equal(discount.toString(), "75000");
    });

    it("handles odd numbers with floor rounding", () => {
      const discount = calculateDiscount(
        {
          type: "PERCENT",
          value: new Prisma.Decimal(15),
        },
        new Prisma.Decimal(333333)
      );
      // 333333 * 15 / 100 = 49999.95 -> floor = 49999
      assert.equal(discount.toString(), "49999");
    });
  });

  describe("allocateDiscount", () => {
    it("allocates across multiple lines with exact sum = D and non-negative lines", () => {
      const discount = new Prisma.Decimal(50000);
      const lines = [
        new Prisma.Decimal(100000),
        new Prisma.Decimal(200000),
        new Prisma.Decimal(300000),
      ];

      const allocated = allocateDiscount(discount, lines);
      assert.equal(allocated.length, 3);

      const sum = allocated.reduce((acc, d) => acc.add(d), new Prisma.Decimal(0));
      assert.equal(sum.toString(), "50000");

      for (const a of allocated) {
        assert.ok(a.greaterThanOrEqualTo(0));
      }
    });

    it("allocates accurately with odd amounts / rounding remainders", () => {
      const discount = new Prisma.Decimal(10000);
      const lines = [
        new Prisma.Decimal(33333),
        new Prisma.Decimal(33333),
        new Prisma.Decimal(33334),
      ];

      const allocated = allocateDiscount(discount, lines);
      const sum = allocated.reduce((acc, d) => acc.add(d), new Prisma.Decimal(0));
      assert.equal(sum.toString(), "10000");

      for (const a of allocated) {
        assert.ok(a.greaterThanOrEqualTo(0));
      }
    });

    it("returns zeros when discount is zero", () => {
      const allocated = allocateDiscount(new Prisma.Decimal(0), [
        new Prisma.Decimal(100000),
      ]);
      assert.equal(allocated[0]?.toString(), "0");
    });
  });
});

