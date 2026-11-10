import { Role } from "@prisma/client";
import { Router } from "express";
import { accountStatusMiddleware } from "../../middlewares/account-status.middleware";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { profileMiddleware } from "../../middlewares/profile.middleware";
import { requireRole } from "../../middlewares/role.middleware";
import { validateRequest } from "../../middlewares/validate.middleware";
import { voucherController } from "./voucher.controller";
import {
  availableVouchersQuerySchema,
  createAdminVoucherSchema,
  listAdminVouchersQuerySchema,
  updateAdminVoucherSchema,
  validateVoucherSchema,
  voucherIdParamsSchema,
} from "./voucher.schema";

export const voucherRoutes = Router();
export const adminVoucherRoutes = Router();

// Khách: authMiddleware, profileMiddleware, accountStatusMiddleware
voucherRoutes.use(authMiddleware, profileMiddleware, accountStatusMiddleware);

voucherRoutes.get(
  "/available",
  validateRequest({ query: availableVouchersQuerySchema }),
  (req, res, next) => voucherController.getAvailable(req, res, next)
);

voucherRoutes.post(
  "/validate",
  validateRequest({ body: validateVoucherSchema }),
  (req, res, next) => voucherController.validate(req, res, next)
);

// Admin: authMiddleware, profileMiddleware, accountStatusMiddleware, requireRole(Role.ADMIN)
adminVoucherRoutes.use(
  authMiddleware,
  profileMiddleware,
  accountStatusMiddleware,
  requireRole(Role.ADMIN)
);

adminVoucherRoutes.get(
  "/",
  validateRequest({ query: listAdminVouchersQuerySchema }),
  (req, res, next) => voucherController.adminList(req, res, next)
);

adminVoucherRoutes.get(
  "/:id",
  validateRequest({ params: voucherIdParamsSchema }),
  (req, res, next) => voucherController.adminGetById(req, res, next)
);

adminVoucherRoutes.post(
  "/",
  validateRequest({ body: createAdminVoucherSchema }),
  (req, res, next) => voucherController.adminCreate(req, res, next)
);

adminVoucherRoutes.put(
  "/:id",
  validateRequest({
    params: voucherIdParamsSchema,
    body: updateAdminVoucherSchema,
  }),
  (req, res, next) => voucherController.adminUpdate(req, res, next)
);

adminVoucherRoutes.delete(
  "/:id",
  validateRequest({ params: voucherIdParamsSchema }),
  (req, res, next) => voucherController.adminDelete(req, res, next)
);

