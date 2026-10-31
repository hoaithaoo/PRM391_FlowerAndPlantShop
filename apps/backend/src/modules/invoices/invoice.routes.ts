import { Router } from "express";
import { adminGuard, userGuard } from "../../middlewares/admin-guard.middleware";
import { validateRequest } from "../../middlewares/validate.middleware";
import { invoiceController } from "./invoice.controller";
import {
  adminListInvoicesQuerySchema,
  invoiceIdParamsSchema,
  listMyInvoicesQuerySchema,
} from "./invoice.schema";

export const invoiceRoutes = Router();
export const adminInvoiceRoutes = Router();

invoiceRoutes.use(...userGuard);
invoiceRoutes.get(
  "/",
  validateRequest({ query: listMyInvoicesQuerySchema }),
  (req, res, next) => invoiceController.listMine(req, res, next)
);
invoiceRoutes.get(
  "/:id",
  validateRequest({ params: invoiceIdParamsSchema }),
  (req, res, next) => invoiceController.getMine(req, res, next)
);

adminInvoiceRoutes.use(...adminGuard);
adminInvoiceRoutes.get(
  "/",
  validateRequest({ query: adminListInvoicesQuerySchema }),
  (req, res, next) => invoiceController.adminList(req, res, next)
);
adminInvoiceRoutes.get(
  "/:id",
  validateRequest({ params: invoiceIdParamsSchema }),
  (req, res, next) => invoiceController.adminGet(req, res, next)
);
