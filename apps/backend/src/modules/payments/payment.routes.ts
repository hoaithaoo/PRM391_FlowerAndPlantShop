import { Role } from "@prisma/client";
import { Router } from "express";
import { accountStatusMiddleware } from "../../middlewares/account-status.middleware";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { profileMiddleware } from "../../middlewares/profile.middleware";
import { requireRole } from "../../middlewares/role.middleware";
import { validateRequest } from "../../middlewares/validate.middleware";
import { paymentController } from "./payment.controller";
import { paymentIdParamsSchema } from "./payment.schema";

export const paymentRoutes = Router();

paymentRoutes.use(
  authMiddleware,
  profileMiddleware,
  accountStatusMiddleware,
  requireRole(Role.USER)
);

paymentRoutes.get(
  "/:id/status",
  validateRequest({ params: paymentIdParamsSchema }),
  (req, res, next) => paymentController.getStatus(req, res, next)
);
