import type { NextFunction, Request, Response } from "express";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { sendSuccess } from "../../common/utils/response";
import { paymentService } from "./payment.service";

export class PaymentController {
  async getStatus(
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

      const result = await paymentService.getStatus(
        userId,
        req.params.id as string
      );
      sendSuccess(req, res, result);
    } catch (error) {
      next(error);
    }
  }
}

export const paymentController = new PaymentController();
