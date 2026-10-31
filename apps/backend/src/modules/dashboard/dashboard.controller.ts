import type { NextFunction, Request, Response } from "express";
import { sendSuccess } from "../../common/utils/response";
import type { DashboardQuery } from "./dashboard.schema";
import { dashboardService } from "./dashboard.service";

export class DashboardController {
  async getStats(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const stats = await dashboardService.getStats(
        req.query as unknown as DashboardQuery
      );
      sendSuccess(req, res, stats);
    } catch (error) {
      next(error);
    }
  }
}

export const dashboardController = new DashboardController();
