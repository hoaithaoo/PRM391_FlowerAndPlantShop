import { Request, Response, NextFunction } from "express";
import { prisma } from "../lib/prisma";
import { AppError } from "../common/errors/app-error";
import { ErrorCodes } from "../common/errors/error-codes";
import { logger } from "../lib/logger";

/**
 * profileMiddleware:
 * - Finds existing profile in PostgreSQL using verified Supabase userId
 * - First-login sync: automatically creates profile with role=USER and status=ACTIVE
 * - Prevents client from manipulating role or status
 * - Binds profile to req.profile
 */
export const profileMiddleware = async (
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    if (!req.auth || !req.auth.userId) {
      throw new AppError(
        401,
        ErrorCodes.AUTH_TOKEN_MISSING,
        "Yêu cầu xác thực tài khoản trước khi lấy hồ sơ."
      );
    }

    const { userId, email, fullName, avatarUrl } = req.auth;

    // Find profile in application database
    let profile = await prisma.profile.findUnique({
      where: { id: userId },
    });

    // First-login profile synchronization
    if (!profile) {
      try {
        // Upsert prevents duplicate-key errors when two first requests arrive
        // concurrently after a new Supabase Auth login.
        profile = await prisma.profile.upsert({
          where: { id: userId },
          create: {
            id: userId,
            email: email ?? null,
            fullName: fullName ?? null,
            avatarUrl: avatarUrl ?? null,
            role: "USER",
            status: "ACTIVE",
          },
          update: {},
        });

        logger.info("New profile created on first login", { userId });
      } catch (dbErr) {
        logger.error("Failed to sync/create profile in DB", {
          userId,
          error: dbErr,
        });

        throw new AppError(
          500,
          ErrorCodes.PROFILE_SYNC_FAILED,
          "Không thể đồng bộ hoặc khởi tạo hồ sơ người dùng trong hệ thống."
        );
      }
    }

    req.profile = profile;
    next();
  } catch (err) {
    next(err);
  }
};
