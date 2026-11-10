import { RequestHandler, Router } from "express";
import { FavoriteController, favoriteController } from "./favorite.controller";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { profileMiddleware } from "../../middlewares/profile.middleware";
import { accountStatusMiddleware } from "../../middlewares/account-status.middleware";
import { validateRequest } from "../../middlewares/validate.middleware";
import { favoriteProductIdParamSchema } from "./favorite.schema";

export function createFavoriteRoutes(
  controller: FavoriteController = favoriteController,
  authenticationMiddlewares: RequestHandler[] = [
    authMiddleware,
    profileMiddleware,
    accountStatusMiddleware,
  ]
): Router {
  const router = Router();
  router.use(...authenticationMiddlewares);

  // Đặt /ids trước các route có tham số sản phẩm.
  router.get("/ids", (req, res, next) => {
    controller.listIds(req, res, next);
  });
  router.get("/", (req, res, next) => {
    controller.list(req, res, next);
  });
  router.put("/:productId", validateRequest({ params: favoriteProductIdParamSchema }), (req, res, next) => {
    controller.add(req, res, next);
  });
  router.delete("/:productId", validateRequest({ params: favoriteProductIdParamSchema }), (req, res, next) => {
    controller.remove(req, res, next);
  });

  return router;
}

export const favoriteRoutes = createFavoriteRoutes();
