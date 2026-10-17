import { Role } from "@prisma/client";
import { Router } from "express";
import { accountStatusMiddleware } from "../../middlewares/account-status.middleware";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { profileMiddleware } from "../../middlewares/profile.middleware";
import { requireRole } from "../../middlewares/role.middleware";
import { validateRequest } from "../../middlewares/validate.middleware";
import { checkoutController } from "./checkout.controller";
import { checkoutSchema } from "./checkout.schema";

export const checkoutRoutes = Router();

checkoutRoutes.use(
  authMiddleware,
  profileMiddleware,
  accountStatusMiddleware,
  requireRole(Role.USER)
);

checkoutRoutes.post(
  "/",
  validateRequest({ body: checkoutSchema }),
  (req, res, next) => checkoutController.checkout(req, res, next)
);
