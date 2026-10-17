import type { NextFunction, Request, Response } from "express";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { sendSuccess } from "../../common/utils/response";
import { idempotencyKeySchema } from "./checkout.schema";
import { checkoutService } from "./checkout.service";

export class CheckoutController {
  async checkout(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const userId = req.auth?.userId;
      if (!userId) {
        throw new AppError(
          401,
          ErrorCodes.AUTH_TOKEN_MISSING,
          "Chưa xác thực người dùng."
        );
      }

      const rawIdempotencyKey = req.get("Idempotency-Key");
      const idempotencyKey = rawIdempotencyKey
        ? idempotencyKeySchema.parse(rawIdempotencyKey)
        : undefined;
      const result = await checkoutService.checkout(
        userId,
        req.body,
        idempotencyKey
      );
      sendSuccess(req, res, result, 201);
    } catch (error) {
      next(error);
    }
  }
}

export const checkoutController = new CheckoutController();
