import type { NextFunction, Request, Response } from "express";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { sendSuccess } from "../../common/utils/response";
import type { AdminListUsersQuery } from "./user.schema";
import { userService } from "./user.service";

export class UserController {
  async adminList(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await userService.adminList(
        req.query as unknown as AdminListUsersQuery
      );
      sendSuccess(req, res, { items: result.items }, 200, result.meta);
    } catch (error) {
      next(error);
    }
  }

  async adminGet(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = await userService.adminGet(req.params.id as string);
      sendSuccess(req, res, user);
    } catch (error) {
      next(error);
    }
  }

  async adminUpdate(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const actorId = req.profile?.id;
      if (!actorId) {
        throw new AppError(401, ErrorCodes.AUTH_TOKEN_MISSING, "Chưa xác thực.");
      }
      const user = await userService.adminUpdate(
        actorId,
        req.params.id as string,
        req.body
      );
      sendSuccess(req, res, user);
    } catch (error) {
      next(error);
    }
  }
}

export const userController = new UserController();
