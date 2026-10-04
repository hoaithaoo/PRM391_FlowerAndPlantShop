import { Router } from "express";
import { profileController } from "./profile.controller";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { profileMiddleware } from "../../middlewares/profile.middleware";
import { accountStatusMiddleware } from "../../middlewares/account-status.middleware";
import { validateRequest } from "../../middlewares/validate.middleware";
import { updateProfileSchema } from "./profile.schema";

const router = Router();

// Standard middleware chain: auth -> profile -> accountStatus
router.use(authMiddleware, profileMiddleware, accountStatusMiddleware);

/**
 * @route   GET /api/v1/profile
 * @desc    Get currently logged in user profile
 * @access  Protected (USER, ADMIN)
 */
router.get("/", (req, res, next) => {
  profileController.getMe(req, res, next);
});

/**
 * @route   PUT /api/v1/profile
 * @desc    Update current user profile (fullName, phone, avatarUrl)
 * @access  Protected (USER, ADMIN)
 */
router.put("/", validateRequest({ body: updateProfileSchema }), (req, res, next) => {
  profileController.updateMe(req, res, next);
});

export const profileRoutes = router;
