import { Router } from "express";
import { validateRequest } from "../../middlewares/validate.middleware";
import { authController } from "./auth.controller";
import { loginSchema, refreshSchema } from "./auth.schema";

export const authRoutes = Router();

authRoutes.post(
  "/login",
  validateRequest({ body: loginSchema }),
  (req, res, next) => authController.login(req, res, next)
);
authRoutes.post(
  "/refresh",
  validateRequest({ body: refreshSchema }),
  (req, res, next) => authController.refresh(req, res, next)
);
