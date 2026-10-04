import { Request, Response, NextFunction } from "express";
import { supabase } from "../lib/supabase";
import { AppError } from "../common/errors/app-error";
import { ErrorCodes } from "../common/errors/error-codes";
import { logger } from "../lib/logger";

/**
 * authMiddleware:
 * - Reads Bearer token from Authorization header
 * - Verifies token with Supabase Auth (supabase.auth.getUser)
 * - Injects verified userId & email into req.auth
 * - Handles 401 AUTH_TOKEN_MISSING, 401 AUTH_TOKEN_INVALID, 503 AUTH_PROVIDER_UNAVAILABLE
 */
export const authMiddleware = async (
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      throw new AppError(
        401,
        ErrorCodes.AUTH_TOKEN_MISSING,
        "Không có Authorization header hoặc sai định dạng Bearer token."
      );
    }

    const token = authHeader.substring(7).trim();

    if (!token) {
      throw new AppError(
        401,
        ErrorCodes.AUTH_TOKEN_MISSING,
        "Access token không được để trống."
      );
    }

    // Verify token with Supabase Auth
    const { data, error } = await supabase.auth.getUser(token);

    if (error) {
      logger.warn("Supabase auth verification failed", {
        code: error.status,
        name: error.name,
      });

      // Provider/network unavailable or timeout
      if (error.status && error.status >= 500) {
        throw new AppError(
          503,
          ErrorCodes.AUTH_PROVIDER_UNAVAILABLE,
          "Dịch vụ xác thực Supabase tạm thời không khả dụng."
        );
      }

      throw new AppError(
        401,
        ErrorCodes.AUTH_TOKEN_INVALID,
        "Token không hợp lệ hoặc đã hết hạn."
      );
    }

    if (!data.user) {
      throw new AppError(
        401,
        ErrorCodes.AUTH_TOKEN_INVALID,
        "Không tìm thấy thông tin người dùng từ token."
      );
    }

    // Bind trusted identity to request object
    req.auth = {
      userId: data.user.id,
      email: data.user.email ?? null,
    };

    next();
  } catch (err) {
    next(err);
  }
};
