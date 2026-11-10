import assert from "node:assert/strict";
import { describe, test } from "node:test";
import type { PrismaClient } from "@prisma/client";
import { AppError } from "../../common/errors/app-error";
import { ReviewService } from "./review.service";

const USER_ID = "11111111-1111-4111-8111-111111111111";
const ORDER_ID = "22222222-2222-4222-8222-222222222222";
const PRODUCT_ID = "33333333-3333-4333-8333-333333333333";
const STORAGE = "https://demo.supabase.co/storage/v1/object/public";

function fakeDb(order: { status: string; hasProduct: boolean } | null) {
  const created: unknown[] = [];
  const db = {
    order: {
      findFirst: async () =>
        order && { status: order.status, items: order.hasProduct ? [{ id: "item" }] : [] },
    },
    productReview: {
      create: async (args: { data: unknown }) => {
        created.push(args.data);
        return args.data;
      },
    },
  };
  return { db: db as unknown as PrismaClient, created };
}

const input = (imageUrls: string[] = []) => ({
  orderId: ORDER_ID,
  productId: PRODUCT_ID,
  rating: 5,
  comment: "Hoa tươi, gói đẹp",
  imageUrls,
});

const rejectsWith = (status: number) => (error: unknown) =>
  error instanceof AppError && error.statusCode === status;

describe("ReviewService.create", () => {
  test("only allows reviewing a product from a completed order", async () => {
    const shipping = fakeDb({ status: "SHIPPING", hasProduct: true });
    await assert.rejects(new ReviewService(shipping.db, STORAGE).create(USER_ID, input()), rejectsWith(409));

    const missingItem = fakeDb({ status: "COMPLETED", hasProduct: false });
    await assert.rejects(new ReviewService(missingItem.db, STORAGE).create(USER_ID, input()), rejectsWith(409));

    const notOwned = fakeDb(null);
    await assert.rejects(new ReviewService(notOwned.db, STORAGE).create(USER_ID, input()), rejectsWith(404));

    assert.equal(shipping.created.length + missingItem.created.length + notOwned.created.length, 0);
  });

  test("accepts images only from the user's own folder in the review bucket", async () => {
    const own = `${STORAGE}/review-images/${USER_ID}/a.jpg`;
    const ok = fakeDb({ status: "COMPLETED", hasProduct: true });
    await new ReviewService(ok.db, STORAGE).create(USER_ID, input([own]));
    assert.deepEqual((ok.created[0] as { imageUrls: string[] }).imageUrls, [own]);

    for (const bad of [
      `${STORAGE}/review-images/someone-else/a.jpg`,
      `${STORAGE}/avatars/${USER_ID}/a.jpg`,
      "https://evil.example/a.jpg",
    ]) {
      const rejected = fakeDb({ status: "COMPLETED", hasProduct: true });
      await assert.rejects(new ReviewService(rejected.db, STORAGE).create(USER_ID, input([bad])), rejectsWith(400));
      assert.equal(rejected.created.length, 0);
    }
  });
});
