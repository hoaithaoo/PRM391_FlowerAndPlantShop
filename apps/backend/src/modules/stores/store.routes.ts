import { Router } from "express";
import { storeController } from "./store.controller";
import { validateRequest } from "../../middlewares/validate.middleware";
import {
  listStoresQuerySchema,
  shippingEstimateSchema,
} from "./store.schema";

const router = Router();

/**
 * @route   GET /api/v1/stores
 * @desc    Get all active stores. Optional query lat & lng calculates distance & shipping fee.
 * @access  Public
 */
router.get(
  "/",
  validateRequest({ query: listStoresQuerySchema }),
  (req, res, next) => {
    storeController.list(req, res, next);
  }
);

/**
 * @route   POST /api/v1/stores/shipping-estimate
 * @desc    Calculate distance, shipping fee, and delivery time to user's coordinates
 * @access  Public
 */
router.post(
  "/shipping-estimate",
  validateRequest({ body: shippingEstimateSchema }),
  (req, res, next) => {
    storeController.estimateShipping(req, res, next);
  }
);

/**
 * @route   GET /api/v1/stores/shipping-estimate
 * @desc    Query-based shipping fee calculation
 * @access  Public
 */
router.get(
  "/shipping-estimate",
  validateRequest({ query: shippingEstimateSchema }),
  (req, res, next) => {
    storeController.estimateShipping(req, res, next);
  }
);

/**
 * @route   GET /api/v1/stores/:id
 * @desc    Get store details by ID
 * @access  Public
 */
router.get("/:id", (req, res, next) => {
  storeController.getById(req, res, next);
});

export const storeRoutes = router;
