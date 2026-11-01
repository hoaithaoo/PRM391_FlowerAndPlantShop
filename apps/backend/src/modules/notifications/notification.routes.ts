import { Router } from "express";
import { accountStatusMiddleware } from "../../middlewares/account-status.middleware";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { profileMiddleware } from "../../middlewares/profile.middleware";
import { validateRequest } from "../../middlewares/validate.middleware";
import { notificationController } from "./notification.controller";
import {
  listNotificationsQuerySchema,
  notificationIdParamsSchema,
} from "./notification.schema";

export const notificationRoutes = Router();

notificationRoutes.use(
  authMiddleware,
  profileMiddleware,
  accountStatusMiddleware
);

notificationRoutes.get(
  "/",
  validateRequest({ query: listNotificationsQuerySchema }),
  (req, res, next) => notificationController.list(req, res, next)
);
notificationRoutes.patch(
  "/read-all",
  (req, res, next) => notificationController.markAllRead(req, res, next)
);
notificationRoutes.patch(
  "/:id/read",
  validateRequest({ params: notificationIdParamsSchema }),
  (req, res, next) => notificationController.markRead(req, res, next)
);
