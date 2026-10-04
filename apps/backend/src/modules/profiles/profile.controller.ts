import { Request, Response, NextFunction } from "express";
import { profileService } from "./profile.service";
import { sendSuccess } from "../../common/utils/response";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";

export class ProfileController {
  async getMe(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.auth?.userId;
      if (!userId) {
        throw new AppError(401, ErrorCodes.AUTH_TOKEN_MISSING, "Chưa xác thực.");
      }

      const profile = await profileService.getProfile(userId);
      sendSuccess(req, res, profile);
    } catch (err) {
      next(err);
    }
  }

  async updateMe(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.auth?.userId;
      if (!userId) {
        throw new AppError(401, ErrorCodes.AUTH_TOKEN_MISSING, "Chưa xác thực.");
      }

      const updated = await profileService.updateProfile(userId, req.body);
      sendSuccess(req, res, updated);
    } catch (err) {
      next(err);
    }
  }
}

export const profileController = new ProfileController();
