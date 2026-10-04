import { Request, Response, NextFunction } from "express";
import { AppError } from "../common/errors/app-error";
import { ErrorCodes } from "../common/errors/error-codes";

/**
 * accountStatusMiddleware:
 * - Checks profile.status
 * - If DISABLED -> 403 ACCOUNT_DISABLED
 */
export const accountStatusMiddleware = (
  req: Request,
  _res: Response,
  next: NextFunction
): void => {
  if (!req.profile) {
    return next(
      new AppError(
        401,
        ErrorCodes.AUTH_TOKEN_MISSING,
        "Chưa xác thực thông tin hồ sơ người dùng."
      )
    );
  }

  if (req.profile.status === "DISABLED") {
    return next(
      new AppError(
        403,
        ErrorCodes.ACCOUNT_DISABLED,
        "Tài khoản của bạn đã bị tạm khóa. Vui lòng liên hệ quản trị viên."
      )
    );
  }

  next();
};
