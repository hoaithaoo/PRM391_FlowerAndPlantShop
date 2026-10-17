import type { NextFunction, Request, Response } from "express";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { sendSuccess } from "../../common/utils/response";
import { cartService } from "./cart.service";

export class CartController {
  async getCart(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const cart = await cartService.getCart(this.getUserId(req));
      sendSuccess(req, res, cart);
    } catch (error) {
      next(error);
    }
  }

  async addItemToCart(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const item = await cartService.addItemToCart(
        this.getUserId(req),
        req.body
      );
      sendSuccess(req, res, item, 201);
    } catch (error) {
      next(error);
    }
  }

  async updateCartItem(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const item = await cartService.updateCartItem(
        this.getUserId(req),
        req.params.id as string,
        req.body
      );
      sendSuccess(req, res, item);
    } catch (error) {
      next(error);
    }
  }

  async removeCartItem(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      await cartService.removeCartItem(
        this.getUserId(req),
        req.params.id as string
      );
      res.status(204).send();
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

export const cartController = new CartController();
