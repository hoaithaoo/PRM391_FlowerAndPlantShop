import { Router } from "express";
import { accountStatusMiddleware } from "../../middlewares/account-status.middleware";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { profileMiddleware } from "../../middlewares/profile.middleware";
import { validateRequest } from "../../middlewares/validate.middleware";
import { cartController } from "./cart.controller";
import {
  addCartItemSchema,
  cartItemIdParamsSchema,
  updateCartItemSchema,
} from "./cart.schema";

export const cartRoutes = Router();

// USER and ADMIN can both use their own cart, as specified for user-facing APIs.
cartRoutes.use(authMiddleware, profileMiddleware, accountStatusMiddleware);

cartRoutes.get("/", (req, res, next) => cartController.getCart(req, res, next));
cartRoutes.post(
  "/items",
  validateRequest({ body: addCartItemSchema }),
  (req, res, next) => cartController.addItemToCart(req, res, next)
);
cartRoutes.put(
  "/items/:id",
  validateRequest({ params: cartItemIdParamsSchema, body: updateCartItemSchema }),
  (req, res, next) => cartController.updateCartItem(req, res, next)
);
cartRoutes.delete(
  "/items/:id",
  validateRequest({ params: cartItemIdParamsSchema }),
  (req, res, next) => cartController.removeCartItem(req, res, next)
);
