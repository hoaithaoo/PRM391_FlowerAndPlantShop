import { Router } from "express";
import { adminGuard } from "../../middlewares/admin-guard.middleware";
import { validateRequest } from "../../middlewares/validate.middleware";
import { userController } from "./user.controller";
import {
  adminListUsersQuerySchema,
  adminUpdateUserSchema,
  userIdParamsSchema,
} from "./user.schema";

export const adminUserRoutes = Router();

adminUserRoutes.use(...adminGuard);
adminUserRoutes.get(
  "/",
  validateRequest({ query: adminListUsersQuerySchema }),
  (req, res, next) => userController.adminList(req, res, next)
);
adminUserRoutes.get(
  "/:id",
  validateRequest({ params: userIdParamsSchema }),
  (req, res, next) => userController.adminGet(req, res, next)
);
adminUserRoutes.patch(
  "/:id",
  validateRequest({ params: userIdParamsSchema, body: adminUpdateUserSchema }),
  (req, res, next) => userController.adminUpdate(req, res, next)
);
