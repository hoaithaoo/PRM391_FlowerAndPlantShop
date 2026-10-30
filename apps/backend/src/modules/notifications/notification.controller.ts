import type { NextFunction, Request, Response } from "express";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { sendSuccess } from "../../common/utils/response";
import type { ListNotificationsQuery } from "./notification.schema";
import { notificationService } from "./notification.service";

export class NotificationController {
  async list(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await notificationService.list(
        this.getUserId(req),
        req.query as unknown as ListNotificationsQuery
      );
      sendSuccess(req, res, { items: result.items }, 200, {
        page: result.page,
        total: result.total,
        totalPages: result.totalPages,
        unreadCount: result.unreadCount,
      });
    } catch (error) {
      next(error);
    }
  }

  async markRead(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const notification = await notificationService.markRead(
        this.getUserId(req),
        req.params.id as string
      );
      sendSuccess(req, res, notification);
    } catch (error) {
      next(error);
    }
  }

  async markAllRead(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const result = await notificationService.markAllRead(this.getUserId(req));
      sendSuccess(req, res, result);
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

export const notificationController = new NotificationController();
