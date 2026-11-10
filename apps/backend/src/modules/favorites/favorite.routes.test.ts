import assert from "node:assert/strict";
import { Socket } from "node:net";
import { IncomingMessage, ServerResponse } from "node:http";
import { Duplex } from "node:stream";
import { describe, it } from "node:test";
import express, { NextFunction, Request, Response, RequestHandler } from "express";
import { errorHandler } from "../../middlewares/error-handler";
import { requestIdMiddleware } from "../../middlewares/request-id.middleware";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { FavoriteController } from "./favorite.controller";
import { FavoriteService } from "./favorite.service";
import { createFavoriteRoutes } from "./favorite.routes";

const PROFILE_ID = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
const PRODUCT_ID = "11111111-1111-4111-8111-111111111111";
const mockAuth = (req: Request, _res: Response, next: NextFunction) => {
  req.auth = { userId: PROFILE_ID };
  next();
};

class FakeFavoriteService {
  calls: unknown[] = [];
  async list(profileId: string) {
    this.calls.push(profileId);
    return [{ id: PRODUCT_ID, price: 250000, favoritedAt: new Date("2026-11-11T12:00:00Z") }];
  }
  async listIds(profileId: string) {
    this.calls.push(profileId);
    return [PRODUCT_ID];
  }
  async add(profileId: string, productId: string) {
    this.calls.push({ profileId, productId });
    return { productId };
  }
  async remove(profileId: string, productId: string) {
    this.calls.push({ profileId, productId });
  }
}

async function request(
  service: FakeFavoriteService, path = "", method = "GET",
  middlewares: RequestHandler[] = [mockAuth],
) {
  const app = express();
  app.use(express.json());
  app.use(requestIdMiddleware);
  app.use("/api/v1/favorites", createFavoriteRoutes(
    new FavoriteController(service as unknown as FavoriteService), middlewares,
  ));
  app.use(errorHandler);
  // Chạy đầy đủ Express pipeline bằng HTTP stream trong bộ nhớ, không mở cổng.
  const chunks: Buffer[] = [];
  const socket = new Duplex({
    read() {},
    write(chunk, _encoding, callback) {
      chunks.push(Buffer.from(chunk));
      callback();
    },
  });
  const req = new IncomingMessage(socket as Socket);
  req.method = method;
  req.url = `/api/v1/favorites${path}`;
  req.headers = { host: "localhost" };
  req.httpVersion = "1.1";
  req.httpVersionMajor = 1;
  req.httpVersionMinor = 1;
  req.push(null);
  const res = new ServerResponse(req);
  res.assignSocket(socket as Socket);
  await new Promise<void>((resolve, reject) => {
    res.once("finish", resolve);
    res.once("error", reject);
    app(req, res);
  });
  socket.destroy();
  const raw = Buffer.concat(chunks).toString("utf8");
  return {
    response: { status: res.statusCode },
    text: raw.slice(raw.indexOf("\r\n\r\n") + 4),
  };
}

describe("Favorite Routes", () => {
  it("GET trả envelope chuẩn và favoritedAt", async () => {
    const service = new FakeFavoriteService();
    const { response, text } = await request(service);
    const body = JSON.parse(text);
    assert.equal(response.status, 200);
    assert.equal(body.success, true);
    assert.equal(body.data.items[0].favoritedAt, "2026-11-11T12:00:00.000Z");
    assert.ok(body.meta.requestId);
    assert.deepEqual(service.calls, [PROFILE_ID]);
  });
  it("GET /ids trả productIds, không coi ids là UUID", async () => {
    const { response, text } = await request(new FakeFavoriteService(), "/ids");
    assert.equal(response.status, 200);
    assert.deepEqual(JSON.parse(text).data, { productIds: [PRODUCT_ID] });
  });
  it("PUT lặp lại vẫn 200 và không nhận hồ sơ từ client", async () => {
    const service = new FakeFavoriteService();
    for (let i = 0; i < 2; i++) {
      const { response, text } = await request(service, `/${PRODUCT_ID}?profileId=other`, "PUT");
      assert.equal(response.status, 200);
      assert.deepEqual(JSON.parse(text).data, { productId: PRODUCT_ID });
    }
    assert.deepEqual(service.calls, Array(2).fill({ profileId: PROFILE_ID, productId: PRODUCT_ID }));
  });
  it("DELETE lặp lại trả 204 với body rỗng", async () => {
    const service = new FakeFavoriteService();
    for (let i = 0; i < 2; i++) {
      const { response, text } = await request(service, `/${PRODUCT_ID}`, "DELETE");
      assert.equal(response.status, 204);
      assert.equal(text, "");
    }
    assert.deepEqual(service.calls[0], { profileId: PROFILE_ID, productId: PRODUCT_ID });
  });
  it("PUT và DELETE từ chối UUID sai trước khi gọi service", async () => {
    const service = new FakeFavoriteService();
    for (const method of ["PUT", "DELETE"]) {
      const { response, text } = await request(service, "/invalid", method);
      assert.equal(response.status, 422);
      assert.equal(JSON.parse(text).error.code, "VALIDATION_ERROR");
    }
    assert.deepEqual(service.calls, []);
  });
  it("thiếu xác thực trả 401", async () => {
    const service = new FakeFavoriteService();
    const { response } = await request(service, "", "GET", [(_req, _res, next) => next()]);
    assert.equal(response.status, 401);
    assert.deepEqual(service.calls, []);
  });
  it("chạy đủ middleware trước controller và chặn tài khoản bị khoá", async () => {
    const calls: number[] = [];
    const service = new FakeFavoriteService();
    const { response } = await request(service, "", "GET", [
      (req, res, next) => { calls.push(1); mockAuth(req, res, next); },
      (_req, _res, next) => { calls.push(2); next(); },
      (_req, _res, next) => {
        calls.push(3);
        next(new AppError(403, ErrorCodes.FORBIDDEN, "Tài khoản bị khoá."));
      },
    ]);
    assert.equal(response.status, 403);
    assert.deepEqual(calls, [1, 2, 3]);
    assert.deepEqual(service.calls, []);
  });
  it("chuyển lỗi PRODUCT_NOT_FOUND sang error envelope", async () => {
    const service = new FakeFavoriteService();
    service.add = async () => { throw new AppError(404, ErrorCodes.PRODUCT_NOT_FOUND, "Không tìm thấy sản phẩm."); };
    const { response, text } = await request(service, `/${PRODUCT_ID}`, "PUT");
    assert.equal(response.status, 404);
    assert.equal(JSON.parse(text).error.code, "PRODUCT_NOT_FOUND");
  });
});
