import { Prisma, Role } from "@prisma/client";
import { NextFunction, Request, Response, Router } from "express";
import { z } from "zod";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { sendSuccess } from "../../common/utils/response";
import { prisma } from "../../lib/prisma";
import { accountStatusMiddleware } from "../../middlewares/account-status.middleware";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { profileMiddleware } from "../../middlewares/profile.middleware";
import { requireRole } from "../../middlewares/role.middleware";
import { validateRequest } from "../../middlewares/validate.middleware";

// FAQ chatbot dùng để trả lời chính sách cửa hàng; chỉ admin sửa.
const faqBody = z
  .object({
    topic: z.string().trim().min(1, "Nhập chủ đề").max(120),
    answer: z.string().trim().min(1, "Nhập câu trả lời").max(2000),
    sortOrder: z.number().int().min(0).max(100000).optional(),
    isActive: z.boolean().optional(),
  })
  .strict();
const faqIdParams = z.object({ id: z.string().uuid("ID FAQ không hợp lệ") });

const select = { id: true, topic: true, answer: true, sortOrder: true, isActive: true, updatedAt: true };

type Handler = (req: Request, res: Response) => Promise<unknown>;
const handle = (fn: Handler) => (req: Request, res: Response, next: NextFunction) => {
  fn(req, res).catch((error: unknown) =>
    next(
      error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2025"
        ? new AppError(404, ErrorCodes.FAQ_NOT_FOUND, "Không tìm thấy câu hỏi FAQ.")
        : error
    )
  );
};

export const adminFaqRoutes = Router();
adminFaqRoutes.use(authMiddleware, profileMiddleware, accountStatusMiddleware, requireRole(Role.ADMIN));

// GET /api/v1/admin/faqs: toàn bộ FAQ, kể cả đang tắt
adminFaqRoutes.get(
  "/",
  handle(async (req, res) =>
    sendSuccess(req, res, {
      items: await prisma.storeFaq.findMany({ orderBy: [{ sortOrder: "asc" }, { createdAt: "asc" }], select }),
    })
  )
);

// POST /api/v1/admin/faqs
adminFaqRoutes.post(
  "/",
  validateRequest({ body: faqBody }),
  handle(async (req, res) => sendSuccess(req, res, await prisma.storeFaq.create({ data: req.body, select }), 201))
);

// PATCH /api/v1/admin/faqs/:id
adminFaqRoutes.patch(
  "/:id",
  validateRequest({ params: faqIdParams, body: faqBody.partial() }),
  handle(async (req, res) =>
    sendSuccess(req, res, await prisma.storeFaq.update({ where: { id: req.params.id as string }, data: req.body, select }))
  )
);

// DELETE /api/v1/admin/faqs/:id
adminFaqRoutes.delete(
  "/:id",
  validateRequest({ params: faqIdParams }),
  handle(async (req, res) => {
    await prisma.storeFaq.delete({ where: { id: req.params.id as string } });
    sendSuccess(req, res, { id: req.params.id });
  })
);
