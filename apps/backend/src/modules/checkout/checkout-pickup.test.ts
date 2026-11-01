import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { Prisma } from "@prisma/client";
import { checkoutSchema } from "./checkout.schema";
import { CheckoutService } from "./checkout.service";

const STORE_ID = "33333333-3333-4333-8333-333333333333";
const base = {
  receiverName: "Lan",
  phone: "0901234567",
  paymentMethod: "COD",
};
const inHours = (hours: number) =>
  new Date(Date.now() + hours * 60 * 60 * 1000).toISOString();

describe("checkoutSchema nhận tại quán", () => {
  it("không cần địa chỉ khi có pickupStoreId và pickupAt", () => {
    const input = { ...base, pickupStoreId: STORE_ID, pickupAt: inHours(2) };
    assert.equal(checkoutSchema.safeParse(input).success, true);
  });

  it("thiếu pickupAt bị từ chối", () => {
    const input = { ...base, pickupStoreId: STORE_ID };
    assert.equal(checkoutSchema.safeParse(input).success, false);
  });

  it("giao hàng vẫn bắt buộc địa chỉ và tọa độ", () => {
    assert.equal(checkoutSchema.safeParse(base).success, false);
  });
});

describe("resolvePickup", () => {
  const service = new CheckoutService({} as any) as any;
  const tx = (store: unknown) => ({
    store: { findFirst: async () => store },
  });
  const store = {
    address: "1 Đồng Khởi",
    latitude: new Prisma.Decimal("10.7"),
    longitude: new Prisma.Decimal("106.7"),
  };

  it("miễn phí ship và dùng địa chỉ cửa hàng", async () => {
    const result = await service.resolvePickup(tx(store), STORE_ID, inHours(2));
    assert.equal(result.address, store.address);
    assert.equal(result.shippingFee.toNumber(), 0);
  });

  it("cửa hàng không hoạt động trả STORE_NOT_FOUND", async () => {
    await assert.rejects(service.resolvePickup(tx(null), STORE_ID, inHours(2)), {
      code: "STORE_NOT_FOUND",
    });
  });

  it("giờ đã qua hoặc quá xa trả PICKUP_TIME_INVALID", async () => {
    for (const hours of [-1, 24 * 32]) {
      await assert.rejects(
        service.resolvePickup(tx(store), STORE_ID, inHours(hours)),
        { code: "PICKUP_TIME_INVALID" }
      );
    }
  });
});
