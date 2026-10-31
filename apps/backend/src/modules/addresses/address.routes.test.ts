import assert from "node:assert/strict";
import { AddressInfo } from "node:net";
import { describe, it } from "node:test";
import express, { NextFunction, Request, Response } from "express";

import { errorHandler } from "../../middlewares/error-handler";
import { requestIdMiddleware } from "../../middlewares/request-id.middleware";
import { createAddressRoutes } from "./address.routes";
import { AddressController } from "./address.controller";
import { AddressResponse } from "./address.service";

const USER_ID = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
const ADDR_ID = "11111111-1111-4111-8111-111111111111";

class FakeAddressService {
  listCalls: string[] = [];
  getCalls: Array<{ userId: string; id: string }> = [];
  createCalls: Array<{ userId: string; input: unknown }> = [];
  deleteCalls: Array<{ userId: string; id: string }> = [];

  sampleAddress: AddressResponse = {
    id: ADDR_ID,
    userId: USER_ID,
    label: "Nhà riêng",
    recipientName: "Nguyen Minh Anh",
    recipientPhone: "0901234567",
    phone: "0901234567",
    addressLine: "15 Nguyễn Thiện Thuật, Phường 2, Quận 3, TP. Hồ Chí Minh",
    address: "15 Nguyễn Thiện Thuật, Phường 2, Quận 3, TP. Hồ Chí Minh",
    deliveryNote: "Giao tại sảnh",
    driverNote: "Giao tại sảnh",
    isDefault: true,
    isDelete: false,
    latitude: 10.7703,
    longitude: 106.6822,
    createdAt: new Date("2026-10-20T00:00:00Z"),
    updatedAt: new Date("2026-10-20T00:00:00Z"),
  };

  async listUserAddresses(userId: string): Promise<AddressResponse[]> {
    this.listCalls.push(userId);
    return [this.sampleAddress];
  }

  async getAddressById(userId: string, id: string): Promise<AddressResponse> {
    this.getCalls.push({ userId, id });
    return this.sampleAddress;
  }

  async createAddress(userId: string, input: unknown): Promise<AddressResponse> {
    this.createCalls.push({ userId, input });
    return this.sampleAddress;
  }

  async updateAddress(userId: string, id: string, input: unknown): Promise<AddressResponse> {
    return this.sampleAddress;
  }

  async deleteAddress(userId: string, id: string): Promise<void> {
    this.deleteCalls.push({ userId, id });
  }

  async setDefaultAddress(userId: string, id: string): Promise<AddressResponse> {
    return this.sampleAddress;
  }
}

const mockAuth = (req: Request, _res: Response, next: NextFunction) => {
  req.auth = { userId: USER_ID };
  next();
};

async function request(
  service: FakeAddressService,
  path: string,
  init?: RequestInit
): Promise<{ response: globalThis.Response; text: string }> {
  const app = express();
  app.use(express.json());
  app.use(requestIdMiddleware);

  const controller = new AddressController(service as any);
  app.use("/api/v1/user-addresses", createAddressRoutes(controller, [mockAuth]));
  app.use(errorHandler);

  const server = app.listen(0);
  await new Promise<void>((resolve) => server.once("listening", resolve));
  const port = (server.address() as AddressInfo).port;

  try {
    const response = await fetch(`http://127.0.0.1:${port}${path}`, init);
    const text = await response.text();
    return { response, text };
  } finally {
    await new Promise<void>((resolve, reject) =>
      server.close((err) => (err ? reject(err) : resolve()))
    );
  }
}

describe("Address Routes", () => {
  it("GET /api/v1/user-addresses returns standard success response with address items", async () => {
    const service = new FakeAddressService();
    const { response, text } = await request(service, "/api/v1/user-addresses");

    assert.equal(response.status, 200);
    const body = JSON.parse(text);
    assert.equal(body.success, true);
    assert.equal(body.data.items.length, 1);
    assert.equal(body.data.items[0].latitude, 10.7703);
    assert.equal(body.data.items[0].longitude, 106.6822);
    assert.equal(service.listCalls[0], USER_ID);
  });

  it("POST /api/v1/user-addresses validates body and creates address", async () => {
    const service = new FakeAddressService();
    const { response, text } = await request(service, "/api/v1/user-addresses", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        recipientName: "Nguyen Minh Anh",
        phone: "0901234567",
        addressLine: "15 Nguyễn Thiện Thuật",
        isDefault: true,
      }),
    });

    assert.equal(response.status, 201);
    const body = JSON.parse(text);
    assert.equal(body.success, true);
    assert.equal(service.createCalls.length, 1);
  });

  it("POST /api/v1/user-addresses rejects invalid phone format", async () => {
    const service = new FakeAddressService();
    const { response, text } = await request(service, "/api/v1/user-addresses", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        recipientName: "Nguyen Minh Anh",
        phone: "12345", // invalid phone
        addressLine: "15 Nguyễn Thiện Thuật",
      }),
    });

    assert.equal(response.status, 422);
    const body = JSON.parse(text);
    assert.equal(body.success, false);
    assert.equal(body.error.code, "VALIDATION_ERROR");
  });

  it("DELETE /api/v1/user-addresses/:id returns 204", async () => {
    const service = new FakeAddressService();
    const { response } = await request(service, `/api/v1/user-addresses/${ADDR_ID}`, {
      method: "DELETE",
    });

    assert.equal(response.status, 204);
    assert.equal(service.deleteCalls.length, 1);
    assert.equal(service.deleteCalls[0].id, ADDR_ID);
  });
});
