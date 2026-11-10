import { Request, Response, NextFunction } from "express";
import { FavoriteService, favoriteService } from "./favorite.service";
import { sendSuccess } from "../../common/utils/response";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";

export class FavoriteController {
  constructor(private readonly service: FavoriteService = favoriteService) {}

  private getUserId(req: Request): string {
    const userId = req.auth?.userId;
    if (!userId) {
      throw new AppError(401, ErrorCodes.AUTH_TOKEN_MISSING, "Chưa xác thực.");
    }
    return userId;
  }

  private getProductId(req: Request): string {
    const id = req.params.productId;
    return Array.isArray(id) ? id[0] : (id ?? "");
  }

  async list(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const items = await this.service.list(this.getUserId(req));
      sendSuccess(req, res, { items });
    } catch (err) {
      next(err);
    }
  }

  async listIds(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const productIds = await this.service.listIds(this.getUserId(req));
      sendSuccess(req, res, { productIds });
    } catch (err) {
      next(err);
    }
  }

  async add(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await this.service.add(this.getUserId(req), this.getProductId(req));
      sendSuccess(req, res, result);
    } catch (err) {
      next(err);
    }
  }

  async remove(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await this.service.remove(this.getUserId(req), this.getProductId(req));
      res.status(204).send();
    } catch (err) {
      next(err);
    }
  }
}

export const favoriteController = new FavoriteController();
