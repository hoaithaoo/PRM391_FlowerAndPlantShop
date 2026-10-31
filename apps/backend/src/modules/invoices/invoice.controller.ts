import type { NextFunction, Request, Response } from "express";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { sendSuccess } from "../../common/utils/response";
import type {
  AdminListInvoicesQuery,
  ListMyInvoicesQuery,
} from "./invoice.schema";
import { invoiceService } from "./invoice.service";

export class InvoiceController {
  async listMine(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await invoiceService.listMine(
        this.getUserId(req),
        req.query as unknown as ListMyInvoicesQuery
      );
      sendSuccess(req, res, { items: result.items }, 200, result.meta);
    } catch (error) {
      next(error);
    }
  }

  async getMine(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const invoice = await invoiceService.getMine(
        this.getUserId(req),
        req.params.id as string
      );
      sendSuccess(req, res, invoice);
    } catch (error) {
      next(error);
    }
  }

  async adminList(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await invoiceService.adminList(
        req.query as unknown as AdminListInvoicesQuery
      );
      sendSuccess(req, res, { items: result.items }, 200, result.meta);
    } catch (error) {
      next(error);
    }
  }

  async adminGet(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const invoice = await invoiceService.adminGet(req.params.id as string);
      sendSuccess(req, res, invoice);
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

export const invoiceController = new InvoiceController();
