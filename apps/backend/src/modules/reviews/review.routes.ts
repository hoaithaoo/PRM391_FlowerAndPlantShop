import { Role } from "@prisma/client";
import { NextFunction, Request, Response, Router } from "express";
import { sendSuccess } from "../../common/utils/response";
import { accountStatusMiddleware } from "../../middlewares/account-status.middleware";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { profileMiddleware } from "../../middlewares/profile.middleware";
import { requireRole } from "../../middlewares/role.middleware";
import { validateRequest } from "../../middlewares/validate.middleware";
import {
  AdminListReviewsQuery,
  adminListReviewsQuerySchema,
  createReviewSchema,
  listProductReviewsQuerySchema,
  myReviewsQuerySchema,
  PageQuery,
  productReviewsParamsSchema,
  reviewIdParamsSchema,
  updateReviewVisibilitySchema,
} from "./review.schema";
import { reviewService } from "./review.service";

type Handler = (req: Request, res: Response) => Promise<unknown>;
const handle = (fn: Handler) => (req: Request, res: Response, next: NextFunction) => {
  fn(req, res).catch(next);
};
// authMiddleware luôn gắn req.auth trước khi tới đây.
const userId = (req: Request) => req.auth!.userId;
const customer = [authMiddleware, profileMiddleware, accountStatusMiddleware];

export const reviewRoutes = Router();
export const adminReviewRoutes = Router();

// GET /api/v1/reviews/products/:productId: công khai, kèm điểm trung bình
reviewRoutes.get(
  "/products/:productId",
  validateRequest({ params: productReviewsParamsSchema, query: listProductReviewsQuerySchema }),
  handle(async (req, res) => {
    const result = await reviewService.listForProduct(
      req.params.productId as string,
      req.query as unknown as PageQuery
    );
    sendSuccess(req, res, { items: result.items, summary: result.summary }, 200, result.meta);
  })
);

// GET /api/v1/reviews/mine?orderId=: đánh giá của khách trong một đơn
reviewRoutes.get(
  "/mine",
  ...customer,
  validateRequest({ query: myReviewsQuerySchema }),
  handle(async (req, res) =>
    sendSuccess(req, res, {
      items: await reviewService.listMineForOrder(userId(req), req.query.orderId as string),
    })
  )
);

// POST /api/v1/reviews: khách đánh giá sản phẩm trong đơn đã hoàn tất
reviewRoutes.post(
  "/",
  ...customer,
  validateRequest({ body: createReviewSchema }),
  handle(async (req, res) => sendSuccess(req, res, await reviewService.create(userId(req), req.body), 201))
);

adminReviewRoutes.use(...customer, requireRole(Role.ADMIN));

// GET /api/v1/admin/reviews?rating=&hidden=&search=
adminReviewRoutes.get(
  "/",
  validateRequest({ query: adminListReviewsQuerySchema }),
  handle(async (req, res) => {
    const result = await reviewService.adminList(req.query as unknown as AdminListReviewsQuery);
    sendSuccess(req, res, { items: result.items }, 200, result.meta);
  })
);

// PATCH /api/v1/admin/reviews/:id: ẩn / hiện đánh giá
adminReviewRoutes.patch(
  "/:id",
  validateRequest({ params: reviewIdParamsSchema, body: updateReviewVisibilitySchema }),
  handle(async (req, res) =>
    sendSuccess(req, res, await reviewService.setHidden(req.params.id as string, req.body.isHidden))
  )
);
