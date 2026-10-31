import { Router } from "express";
import { adminGuard } from "../../middlewares/admin-guard.middleware";
import { validateRequest } from "../../middlewares/validate.middleware";
import { dashboardController } from "./dashboard.controller";
import { dashboardQuerySchema } from "./dashboard.schema";

export const adminDashboardRoutes = Router();

adminDashboardRoutes.use(...adminGuard);
adminDashboardRoutes.get(
  "/",
  validateRequest({ query: dashboardQuerySchema }),
  (req, res, next) => dashboardController.getStats(req, res, next)
);
