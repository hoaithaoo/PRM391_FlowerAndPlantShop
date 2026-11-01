import type { NextFunction, Request, Response } from "express";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { sendSuccess } from "../../common/utils/response";
import { paymentAdminService } from "./payment-admin.service";
import type {
  AdminListPaymentsQuery,
  AdminListSepayTransactionsQuery,
} from "./payment.schema";
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

  async adminListPayments(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const result = await paymentAdminService.listPayments(
        req.query as unknown as AdminListPaymentsQuery
      );
      sendSuccess(req, res, { items: result.items }, 200, result.meta);
    } catch (error) {
      next(error);
    }
  }

  async adminListSepayTransactions(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const result = await paymentAdminService.listTransactions(
        req.query as unknown as AdminListSepayTransactionsQuery
      );
      sendSuccess(req, res, { items: result.items }, 200, result.meta);
    } catch (error) {
      next(error);
    }
  }

  async adminMatchSepayTransaction(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const transaction = await paymentAdminService.matchTransaction(
        req.params.id as string,
        req.body
      );
      sendSuccess(req, res, transaction);
    } catch (error) {
      next(error);
    }
  }
}

export const paymentController = new PaymentController();
