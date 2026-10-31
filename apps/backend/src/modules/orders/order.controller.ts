import type { NextFunction, Request, Response } from "express";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { sendSuccess } from "../../common/utils/response";
import type { AdminListOrdersQuery, ListMyOrdersQuery } from "./order.schema";
import { orderService } from "./order.service";

export class OrderController {
  async listMine(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await orderService.listMine(
        this.getUserId(req),
        req.query as unknown as ListMyOrdersQuery
      );
      sendSuccess(req, res, { items: result.items }, 200, result.meta);
    } catch (error) {
      next(error);
    }
  }

  async getMine(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const order = await orderService.getMine(
        this.getUserId(req),
        req.params.id as string
      );
      sendSuccess(req, res, order);
    } catch (error) {
      next(error);
    }
  }

  async cancelMine(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await orderService.cancelMine(
        this.getUserId(req),
        req.params.id as string,
        req.body ?? {}
      );
      sendSuccess(req, res, result);
    } catch (error) {
      next(error);
    }
  }

  async adminList(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await orderService.adminList(
        req.query as unknown as AdminListOrdersQuery
      );
      sendSuccess(req, res, { items: result.items }, 200, result.meta);
    } catch (error) {
      next(error);
    }
  }

  async adminGet(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const order = await orderService.adminGet(req.params.id as string);
      sendSuccess(req, res, order);
    } catch (error) {
      next(error);
    }
  }

  async adminUpdateStatus(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const order = await orderService.adminUpdateStatus(
        req.params.id as string,
        req.body
      );
      sendSuccess(req, res, order);
    } catch (error) {
      next(error);
    }
  }

  private getUserId(req: Request): string {
    const userId = req.auth?.userId;
    if (!userId) {
      throw new AppError(401, ErrorCodes.AUTH_TOKEN_MISSING, "Chưa xác thực.");
    }
    return userId;
  }
}

export const orderController = new OrderController();
