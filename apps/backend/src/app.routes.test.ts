import assert from "node:assert/strict";
import { AddressInfo } from "node:net";
import { after, before, describe, it } from "node:test";
import type { Server } from "node:http";
import { Prisma } from "@prisma/client";
import { createApp } from "./app";
import { buildSepayQrUrl } from "./modules/checkout/checkout.service";
import { adminUpdateOrderStatusSchema } from "./modules/orders/order.schema";
import {
  createProductSchema,
  updateProductSchema,
} from "./modules/products/product.schema";

const ID = "11111111-1111-4111-8111-111111111111";

let server: Server;
let baseUrl: string;

before(async () => {
  server = createApp().listen(0, "127.0.0.1");
  await new Promise<void>((resolve) => server.once("listening", resolve));
  baseUrl = `http://127.0.0.1:${(server.address() as AddressInfo).port}/api/v1`;
});

after(() => {
  server.close();
});

describe("Route protection", () => {
  const protectedRoutes: Array<[string, string]> = [
    ["GET", "/orders"],
    ["GET", `/orders/${ID}`],
    ["PATCH", `/orders/${ID}/cancel`],
    ["GET", "/invoices"],
    ["GET", `/invoices/${ID}`],
    ["GET", "/admin/dashboard"],
    ["GET", "/admin/users"],
    ["GET", `/admin/users/${ID}`],
    ["PATCH", `/admin/users/${ID}`],
    ["GET", "/admin/products"],
    ["GET", `/admin/products/${ID}`],
    ["GET", "/admin/orders"],
    ["GET", `/admin/orders/${ID}`],
    ["PATCH", `/admin/orders/${ID}/status`],
    ["GET", "/admin/invoices"],
    ["GET", `/admin/invoices/${ID}`],
    ["GET", "/admin/payments"],
    ["GET", "/admin/sepay-transactions"],
    ["POST", `/admin/sepay-transactions/${ID}/match`],
    ["GET", "/admin/categories"],
  ];

  for (const [method, path] of protectedRoutes) {
    it(`${method} ${path} cần Bearer token`, async () => {
      const response = await fetch(baseUrl + path, { method });
      const body = (await response.json()) as { error: { code: string } };
      assert.equal(response.status, 401);
      assert.equal(body.error.code, "AUTH_TOKEN_MISSING");
    });
  }

  it("POST /auth/login validate body trước khi gọi Supabase", async () => {
    const response = await fetch(`${baseUrl}/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: "not-an-email" }),
    });
    const body = (await response.json()) as { error: { code: string } };
    assert.equal(response.status, 422);
    assert.equal(body.error.code, "VALIDATION_ERROR");
  });
});

describe("Admin app payload compatibility", () => {
  it("nhận body sản phẩm admin app gửi (không có sku/taxRate, có field thừa)", () => {
    const parsed = createProductSchema.parse({
      id: "",
      name: "Lan hồ điệp",
      slug: "",
      description: null,
      price: 350000,
      salePrice: null,
      stock: 4,
      categoryId: ID,
      categoryName: "Hoa",
      imageUrl: "https://example.com/lan.jpg",
      isActive: true,
    });
    assert.equal(parsed.sku, undefined);
    assert.equal(parsed.taxRate, 0);
    assert.deepEqual(parsed.imageUrls, ["https://example.com/lan.jpg"]);
    assert.equal("categoryName" in parsed, false);
  });

  it("update giữ nguyên ảnh khi không gửi imageUrl/imageUrls", () => {
    const parsed = updateProductSchema.parse({
      name: "Lan",
      price: 1000,
      stock: 1,
      categoryId: ID,
    });
    assert.equal(parsed.imageUrls, undefined);
    assert.equal(parsed.taxRate, undefined);
  });

  it("chỉ nhận trạng thái đơn theo spec", () => {
    assert.equal(adminUpdateOrderStatusSchema.safeParse({ status: "PREPARING" }).success, true);
    assert.equal(adminUpdateOrderStatusSchema.safeParse({ status: "DELIVERED" }).success, false);
  });
});

describe("SePay QR", () => {
  const config = {
    SEPAY_BANK_ACCOUNT: "0123456789",
    SEPAY_BANK_CODE: "MBBank",
    SEPAY_QR_BASE_URL: "https://qr.sepay.vn/img",
  };

  it("tạo link VietQR với nội dung CK là paymentCode", () => {
    const url = new URL(
      buildSepayQrUrl("PAY20261031ABCDEF123456", new Prisma.Decimal(350000), config)!
    );
    assert.equal(url.origin + url.pathname, "https://qr.sepay.vn/img");
    assert.equal(url.searchParams.get("acc"), "0123456789");
    assert.equal(url.searchParams.get("bank"), "MBBank");
    assert.equal(url.searchParams.get("amount"), "350000");
    assert.equal(url.searchParams.get("des"), "PAY20261031ABCDEF123456");
  });

  it("trả null khi chưa cấu hình tài khoản nhận", () => {
    assert.equal(
      buildSepayQrUrl("PAY1", new Prisma.Decimal(1), { ...config, SEPAY_BANK_ACCOUNT: undefined }),
      null
    );
  });
});

describe("Swagger", () => {
  it("phục vụ trang /api/docs và tài liệu JSON", async () => {
    const root = `${baseUrl.replace("/api/v1", "")}`;
    const page = await fetch(`${root}/api/docs/`);
    assert.equal(page.status, 200);
    const doc = (await (await fetch(`${root}/api/docs.json`)).json()) as {
      openapi: string;
      paths: Record<string, unknown>;
    };
    assert.equal(doc.openapi, "3.0.3");
    assert.ok(doc.paths["/admin/orders/{id}/status"]);
  });
});
