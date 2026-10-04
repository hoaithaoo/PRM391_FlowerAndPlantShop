import { Request, Response, NextFunction } from "express";
import { Role } from "@prisma/client";
import { AppError } from "../common/errors/app-error";
import { ErrorCodes } from "../common/errors/error-codes";

/**
 * requireRole:
 * - Checks profile.role against allowed roles list
 * - Returns 403 FORBIDDEN if role does not match
 */
export const requireRole = (...allowedRoles: Role[]) => {
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (!req.profile) {
      return next(
        new AppError(
          401,
          ErrorCodes.AUTH_TOKEN_MISSING,
          "Chưa xác thực thông tin tài khoản."
        )
      );
    }

    if (!allowedRoles.includes(req.profile.role)) {
      return next(
        new AppError(
          403,
          ErrorCodes.FORBIDDEN,
          "Bạn không có quyền truy cập vào tài nguyên này."
        )
      );
    }

    next();
  };
};
