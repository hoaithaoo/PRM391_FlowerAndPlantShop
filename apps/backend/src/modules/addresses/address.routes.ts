import { RequestHandler, Router } from "express";
import { addressController, AddressController } from "./address.controller";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { profileMiddleware } from "../../middlewares/profile.middleware";
import { accountStatusMiddleware } from "../../middlewares/account-status.middleware";
import { validateRequest } from "../../middlewares/validate.middleware";
import {
  createAddressSchema,
  updateAddressSchema,
  addressIdParamSchema,
} from "./address.schema";

export function createAddressRoutes(
  controller: AddressController = addressController,
  authenticationMiddlewares: RequestHandler[] = [
    authMiddleware,
    profileMiddleware,
    accountStatusMiddleware,
  ]
): Router {
  const router = Router();

  router.use(...authenticationMiddlewares);

  /**
   * @route   GET /api/v1/user-addresses
   * @desc    List all addresses of current authenticated user (auto-resolves missing lat/lng)
   */
  router.get("/", (req, res, next) => {
    controller.list(req, res, next);
  });

  /**
   * @route   POST /api/v1/user-addresses
   * @desc    Create new address for current user
   */
  router.post("/", validateRequest({ body: createAddressSchema }), (req, res, next) => {
    controller.create(req, res, next);
  });

  /**
   * @route   GET /api/v1/user-addresses/:id
   * @desc    Get address details by ID (auto-resolves missing lat/lng)
   */
  router.get("/:id", validateRequest({ params: addressIdParamSchema }), (req, res, next) => {
    controller.getById(req, res, next);
  });

  /**
   * @route   PUT /api/v1/user-addresses/:id
   * @desc    Update address by ID
   */
  router.put(
    "/:id",
    validateRequest({ params: addressIdParamSchema, body: updateAddressSchema }),
    (req, res, next) => {
      controller.update(req, res, next);
    }
  );

  /**
   * @route   DELETE /api/v1/user-addresses/:id
   * @desc    Delete address by ID
   */
  router.delete("/:id", validateRequest({ params: addressIdParamSchema }), (req, res, next) => {
    controller.delete(req, res, next);
  });

  /**
   * @route   PATCH /api/v1/user-addresses/:id/default
   * @desc    Set address as default
   */
  router.patch("/:id/default", validateRequest({ params: addressIdParamSchema }), (req, res, next) => {
    controller.setDefault(req, res, next);
  });

  return router;
}

export const addressRoutes = createAddressRoutes();
