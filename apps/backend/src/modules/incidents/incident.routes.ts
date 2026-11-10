import { Role } from "@prisma/client";
import { NextFunction, Request, Response, Router } from "express";
import { sendSuccess } from "../../common/utils/response";
import { accountStatusMiddleware } from "../../middlewares/account-status.middleware";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { profileMiddleware } from "../../middlewares/profile.middleware";
import { requireRole } from "../../middlewares/role.middleware";
import { validateRequest } from "../../middlewares/validate.middleware";
import {
  createIncidentSchema,
  incidentIdParamsSchema,
  ListIncidentsQuery,
  listIncidentsQuerySchema,
  updateIncidentSchema,
} from "./incident.schema";
import { incidentService } from "./incident.service";

type Handler = (req: Request, res: Response) => Promise<unknown>;
const handle = (fn: Handler) => (req: Request, res: Response, next: NextFunction) => {
  fn(req, res).catch(next);
};
// authMiddleware luôn gắn req.auth trước khi tới đây.
const userId = (req: Request) => req.auth!.userId;

export const incidentRoutes = Router();
export const adminIncidentRoutes = Router();

incidentRoutes.use(authMiddleware, profileMiddleware, accountStatusMiddleware);

// POST /api/v1/incidents: khách gửi phiếu báo sự cố
incidentRoutes.post(
  "/",
  validateRequest({ body: createIncidentSchema }),
  handle(async (req, res) => sendSuccess(req, res, await incidentService.create(userId(req), req.body), 201))
);

// GET /api/v1/incidents: phiếu của chính khách
incidentRoutes.get(
  "/",
  validateRequest({ query: listIncidentsQuerySchema }),
  handle(async (req, res) => {
    const result = await incidentService.listMine(userId(req), req.query as unknown as ListIncidentsQuery);
    sendSuccess(req, res, { items: result.items }, 200, result.meta);
  })
);

adminIncidentRoutes.use(authMiddleware, profileMiddleware, accountStatusMiddleware, requireRole(Role.ADMIN));

// GET /api/v1/admin/incidents?status=&category=&search=
adminIncidentRoutes.get(
  "/",
  validateRequest({ query: listIncidentsQuerySchema }),
  handle(async (req, res) => {
    const result = await incidentService.adminList(req.query as unknown as ListIncidentsQuery);
    sendSuccess(req, res, { items: result.items }, 200, result.meta);
  })
);

// PATCH /api/v1/admin/incidents/:id: đổi trạng thái + phản hồi khách
adminIncidentRoutes.patch(
  "/:id",
  validateRequest({ params: incidentIdParamsSchema, body: updateIncidentSchema }),
  handle(async (req, res) =>
    sendSuccess(req, res, await incidentService.adminUpdate(req.params.id as string, req.body))
  )
);
