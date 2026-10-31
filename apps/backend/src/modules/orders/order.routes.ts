import { Router } from "express";
import { adminGuard, userGuard } from "../../middlewares/admin-guard.middleware";
import { validateRequest } from "../../middlewares/validate.middleware";
import { orderController } from "./order.controller";
import {
  adminListOrdersQuerySchema,
  adminUpdateOrderStatusSchema,
  cancelOrderSchema,
  listMyOrdersQuerySchema,
  orderIdParamsSchema,
} from "./order.schema";

export const orderRoutes = Router();
export const adminOrderRoutes = Router();

orderRoutes.use(...userGuard);
orderRoutes.get(
  "/",
  validateRequest({ query: listMyOrdersQuerySchema }),
  (req, res, next) => orderController.listMine(req, res, next)
);
orderRoutes.get(
  "/:id",
  validateRequest({ params: orderIdParamsSchema }),
  (req, res, next) => orderController.getMine(req, res, next)
);
orderRoutes.patch(
  "/:id/cancel",
  validateRequest({ params: orderIdParamsSchema, body: cancelOrderSchema }),
  (req, res, next) => orderController.cancelMine(req, res, next)
);

adminOrderRoutes.use(...adminGuard);
adminOrderRoutes.get(
  "/",
  validateRequest({ query: adminListOrdersQuerySchema }),
  (req, res, next) => orderController.adminList(req, res, next)
);
adminOrderRoutes.get(
  "/:id",
  validateRequest({ params: orderIdParamsSchema }),
  (req, res, next) => orderController.adminGet(req, res, next)
);
adminOrderRoutes.patch(
  "/:id/status",
  validateRequest({ params: orderIdParamsSchema, body: adminUpdateOrderStatusSchema }),
  (req, res, next) => orderController.adminUpdateStatus(req, res, next)
);
