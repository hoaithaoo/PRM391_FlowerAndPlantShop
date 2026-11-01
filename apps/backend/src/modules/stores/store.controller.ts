import { Request, Response, NextFunction } from "express";
import { storeService } from "./store.service";
import { sendSuccess } from "../../common/utils/response";

export class StoreController {
  async list(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const latitude = req.query.latitude ? Number(req.query.latitude) : undefined;
      const longitude = req.query.longitude ? Number(req.query.longitude) : undefined;

      const result = await storeService.listStores(latitude, longitude);
      sendSuccess(req, res, result);
    } catch (err) {
      next(err);
    }
  }

  async estimateShipping(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      // Support both POST (body) and GET (query) for flexibility
      const data = req.method === "POST" ? req.body : req.query;
      const latitude = Number(data.latitude);
      const longitude = Number(data.longitude);
      const storeId = typeof data.storeId === "string" ? data.storeId : undefined;

      const result = await storeService.estimateShipping(latitude, longitude, storeId);
      sendSuccess(req, res, result);
    } catch (err) {
      next(err);
    }
  }

  async getById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const storeId = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const store = await storeService.getStoreById(storeId);
      sendSuccess(req, res, store);
    } catch (err) {
      next(err);
    }
  }
}

export const storeController = new StoreController();
