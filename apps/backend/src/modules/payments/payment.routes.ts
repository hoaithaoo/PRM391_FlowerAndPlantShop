import { Role } from "@prisma/client";
import { Router } from "express";
import { accountStatusMiddleware } from "../../middlewares/account-status.middleware";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { profileMiddleware } from "../../middlewares/profile.middleware";
import { requireRole } from "../../middlewares/role.middleware";
import { validateRequest } from "../../middlewares/validate.middleware";
import { paymentController } from "./payment.controller";
import { adminGuard } from "../../middlewares/admin-guard.middleware";
import {
  adminListPaymentsQuerySchema,
  adminListSepayTransactionsQuerySchema,
  adminMatchSepayTransactionSchema,
  paymentIdParamsSchema,
  sepayTransactionIdParamsSchema,
} from "./payment.schema";

export const paymentRoutes = Router();
export const adminPaymentRoutes = Router();
export const adminSepayTransactionRoutes = Router();

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

adminPaymentRoutes.use(...adminGuard);
adminPaymentRoutes.get(
  "/",
  validateRequest({ query: adminListPaymentsQuerySchema }),
  (req, res, next) => paymentController.adminListPayments(req, res, next)
);

adminSepayTransactionRoutes.use(...adminGuard);
adminSepayTransactionRoutes.get(
  "/",
  validateRequest({ query: adminListSepayTransactionsQuerySchema }),
  (req, res, next) => paymentController.adminListSepayTransactions(req, res, next)
);
adminSepayTransactionRoutes.post(
  "/:id/match",
  validateRequest({
    params: sepayTransactionIdParamsSchema,
    body: adminMatchSepayTransactionSchema,
  }),
  (req, res, next) => paymentController.adminMatchSepayTransaction(req, res, next)
);
