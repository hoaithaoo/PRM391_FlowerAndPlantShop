import { Role } from "@prisma/client";
import { Router } from "express";
import { accountStatusMiddleware } from "../../middlewares/account-status.middleware";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { profileMiddleware } from "../../middlewares/profile.middleware";
import { requireRole } from "../../middlewares/role.middleware";
import { validateRequest } from "../../middlewares/validate.middleware";
import { categoryController } from "./category.controller";
import {
  categoryIdParamsSchema,
  createCategorySchema,
  listCategoriesQuerySchema,
  updateCategorySchema,
} from "./category.schema";

export const categoryRoutes = Router();
export const adminCategoryRoutes = Router();

categoryRoutes.get(
  "/",
  validateRequest({ query: listCategoriesQuerySchema }),
  (req, res, next) => categoryController.list(req, res, next)
);

adminCategoryRoutes.use(
  authMiddleware,
  profileMiddleware,
  accountStatusMiddleware,
  requireRole(Role.ADMIN)
);
adminCategoryRoutes.get(
  "/",
  validateRequest({ query: listCategoriesQuerySchema }),
  (req, res, next) => categoryController.adminList(req, res, next)
);
adminCategoryRoutes.post(
  "/",
  validateRequest({ body: createCategorySchema }),
  (req, res, next) => categoryController.create(req, res, next)
);
// Spec dùng PUT; admin app hiện gọi PATCH nên nhận cả hai.
adminCategoryRoutes.put(
  "/:id",
  validateRequest({ params: categoryIdParamsSchema, body: updateCategorySchema }),
  (req, res, next) => categoryController.update(req, res, next)
);
adminCategoryRoutes.patch(
  "/:id",
  validateRequest({ params: categoryIdParamsSchema, body: updateCategorySchema }),
  (req, res, next) => categoryController.update(req, res, next)
);
adminCategoryRoutes.delete(
  "/:id",
  validateRequest({ params: categoryIdParamsSchema }),
  (req, res, next) => categoryController.delete(req, res, next)
);
