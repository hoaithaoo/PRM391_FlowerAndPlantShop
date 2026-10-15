import { Role } from "@prisma/client";
import { Router } from "express";
import { accountStatusMiddleware } from "../../middlewares/account-status.middleware";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { profileMiddleware } from "../../middlewares/profile.middleware";
import { requireRole } from "../../middlewares/role.middleware";
import { validateRequest } from "../../middlewares/validate.middleware";
import { productController } from "./product.controller";
import {
  createProductSchema,
  listProductsQuerySchema,
  productIdParamsSchema,
  updateProductSchema,
} from "./product.schema";

export const productRoutes = Router();
export const adminProductRoutes = Router();

productRoutes.get(
  "/",
  validateRequest({ query: listProductsQuerySchema }),
  (req, res, next) => productController.list(req, res, next)
);
productRoutes.get(
  "/:id",
  validateRequest({ params: productIdParamsSchema }),
  (req, res, next) => productController.getById(req, res, next)
);

adminProductRoutes.use(
  authMiddleware,
  profileMiddleware,
  accountStatusMiddleware,
  requireRole(Role.ADMIN)
);
adminProductRoutes.post(
  "/",
  validateRequest({ body: createProductSchema }),
  (req, res, next) => productController.create(req, res, next)
);
adminProductRoutes.put(
  "/:id",
  validateRequest({ params: productIdParamsSchema, body: updateProductSchema }),
  (req, res, next) => productController.update(req, res, next)
);
adminProductRoutes.delete(
  "/:id",
  validateRequest({ params: productIdParamsSchema }),
  (req, res, next) => productController.delete(req, res, next)
);
