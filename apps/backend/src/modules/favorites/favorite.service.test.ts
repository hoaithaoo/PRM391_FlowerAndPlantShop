import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { Prisma } from "@prisma/client";
import { FavoriteService } from "./favorite.service";
import { productSummarySelect } from "../products/product.service";

const PROFILE_ID = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
const PRODUCT_ID = "11111111-1111-4111-8111-111111111111";

// Mock tại ranh giới Prisma như module sổ địa chỉ, không dùng DB thật.
describe("FavoriteService", () => {
  it("lọc theo hồ sơ, chỉ lấy sản phẩm hoạt động và sắp xếp mới nhất trước", async () => {
    let query: any;
    const createdAt = new Date("2026-11-11T12:00:00Z");
    const product = {
      id: PRODUCT_ID, sku: "HOA-01", name: "Hoa hồng", price: new Prisma.Decimal(250000),
      stock: 5, imageUrl: null, category: { id: "category", name: "Hoa tươi" },
    };
    const service = new FavoriteService({ prisma: {
      favorite: { findMany: async (args: any) => {
        query = args;
        return [{ product, createdAt }];
      } },
    } as any });
    const result = await service.list(PROFILE_ID);
    assert.deepEqual(query.where, { profileId: PROFILE_ID, product: { isActive: true } });
    assert.deepEqual(query.orderBy, [{ createdAt: "desc" }, { id: "desc" }]);
    assert.deepEqual(query.select.product.select, productSummarySelect);
    assert.deepEqual(result, [{ ...product, price: 250000, favoritedAt: createdAt }]);
  });

  it("lấy danh sách ID với cùng bộ lọc sản phẩm hoạt động", async () => {
    const service = new FavoriteService({ prisma: {
      favorite: { findMany: async (query: any) => {
        assert.deepEqual(query.where, { profileId: PROFILE_ID, product: { isActive: true } });
        assert.deepEqual(query.select, { productId: true });
        return [{ productId: PRODUCT_ID }];
      } },
    } as any });
    assert.deepEqual(await service.listIds(PROFILE_ID), [PRODUCT_ID]);
  });

  it("thêm lặp lại bỏ qua trùng và giữ nguyên thời gian đã lưu", async () => {
    let writes = 0;
    const service = new FavoriteService({ prisma: {
      product: { findUnique: async ({ where }: any) => {
        assert.deepEqual(where, { id: PRODUCT_ID });
        return { id: PRODUCT_ID };
      } },
      favorite: { createMany: async (query: any) => {
        writes++;
        assert.deepEqual(query, {
          data: [{ profileId: PROFILE_ID, productId: PRODUCT_ID }], skipDuplicates: true,
        });
        return { count: writes === 1 ? 1 : 0 };
      } },
    } as any });
    assert.deepEqual(await service.add(PROFILE_ID, PRODUCT_ID), { productId: PRODUCT_ID });
    await service.add(PROFILE_ID, PRODUCT_ID);
    assert.equal(writes, 2);
  });

  it("trả PRODUCT_NOT_FOUND cho sản phẩm không tồn tại", async () => {
    const service = new FavoriteService({ prisma: {
      product: { findUnique: async () => null },
    } as any });
    await assert.rejects(service.add(PROFILE_ID, PRODUCT_ID), {
      statusCode: 404, code: "PRODUCT_NOT_FOUND",
    });
  });

  it("bỏ yêu thích chỉ trong hồ sơ hiện tại, không lỗi khi chưa lưu", async () => {
    let calls = 0;
    const service = new FavoriteService({ prisma: {
      favorite: { deleteMany: async (query: any) => {
        calls++;
        assert.deepEqual(query.where, { profileId: PROFILE_ID, productId: PRODUCT_ID });
        return { count: 0 };
      } },
    } as any });
    await service.remove(PROFILE_ID, PRODUCT_ID);
    await service.remove(PROFILE_ID, PRODUCT_ID);
    assert.equal(calls, 2);
  });
});
