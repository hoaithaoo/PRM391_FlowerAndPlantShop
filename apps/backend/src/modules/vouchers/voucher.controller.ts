import type { NextFunction, Request, Response } from "express";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { sendSuccess } from "../../common/utils/response";
import { voucherService } from "./voucher.service";

export class VoucherController {
  private getUserId(req: Request): string {
    const userId = req.auth?.userId;
    if (!userId) {
      throw new AppError(
        401,
        ErrorCodes.AUTH_TOKEN_MISSING,
        "Vui lòng đăng nhập để tiếp tục."
      );
    }
    return userId;
  }

  // Khách: GET /api/v1/vouchers/available
  async getAvailable(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = this.getUserId(req);
      const data = await voucherService.getAvailableVouchers(userId);
      sendSuccess(req, res, data);
    } catch (error) {
      next(error);
    }
  }

  // Khách: POST /api/v1/vouchers/validate
  async validate(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = this.getUserId(req);
      const data = await voucherService.validateVoucher(userId, req.body.code);
      sendSuccess(req, res, data);
    } catch (error) {
      next(error);
    }
  }

  // Admin: GET /api/v1/admin/vouchers
  async adminList(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await voucherService.adminList(req.query as any);
      sendSuccess(req, res, data);
    } catch (error) {
      next(error);
    }
  }

  // Admin: GET /api/v1/admin/vouchers/:id
  async adminGetById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await voucherService.adminGetById(req.params.id as string);
      sendSuccess(req, res, data);
    } catch (error) {
      next(error);
    }
  }

  // Admin: POST /api/v1/admin/vouchers
  async adminCreate(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await voucherService.adminCreate(req.body);
      sendSuccess(req, res, data, 201);
    } catch (error) {
      next(error);
    }
  }

  // Admin: PUT /api/v1/admin/vouchers/:id
  async adminUpdate(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await voucherService.adminUpdate(req.params.id as string, req.body);
      sendSuccess(req, res, data);
    } catch (error) {
      next(error);
    }
  }

  // Admin: DELETE /api/v1/admin/vouchers/:id
  async adminDelete(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await voucherService.adminDelete(req.params.id as string);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  }
}

export const voucherController = new VoucherController();
