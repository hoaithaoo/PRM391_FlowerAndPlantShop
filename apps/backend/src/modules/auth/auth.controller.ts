import type { NextFunction, Request, Response } from "express";
import { sendSuccess } from "../../common/utils/response";
import { authService } from "./auth.service";

export class AuthController {
  async login(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const session = await authService.login(req.body);
      sendSuccess(req, res, session);
    } catch (error) {
      next(error);
    }
  }

  async refresh(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const session = await authService.refresh(req.body);
      sendSuccess(req, res, session);
    } catch (error) {
      next(error);
    }
  }
}

export const authController = new AuthController();
