import { Role } from "@prisma/client";
import { accountStatusMiddleware } from "./account-status.middleware";
import { authMiddleware } from "./auth.middleware";
import { profileMiddleware } from "./profile.middleware";
import { requireRole } from "./role.middleware";

/**
 * adminGuard:
 * - Mọi /api/v1/admin/* cần token hợp lệ, role ADMIN và status ACTIVE (spec mục 9)
 */
export const adminGuard = [
  authMiddleware,
  profileMiddleware,
  accountStatusMiddleware,
  requireRole(Role.ADMIN),
];

export const userGuard = [
  authMiddleware,
  profileMiddleware,
  accountStatusMiddleware,
  requireRole(Role.USER),
];
