import express, { Application, Request, Response, NextFunction } from "express";
import helmet from "helmet";
import cors from "cors";
import { env } from "./config/env";
import { requestIdMiddleware } from "./middlewares/request-id.middleware";
import { errorHandler } from "./middlewares/error-handler";
import { AppError } from "./common/errors/app-error";
import { ErrorCodes } from "./common/errors/error-codes";
import { profileRoutes } from "./modules/profiles/profile.routes";

export const createApp = (): Application => {
  const app = express();

  // 1. Security & Core Middlewares
  app.use(helmet());
  app.use(
    cors({
      origin: env.CORS_ORIGIN === "*" ? "*" : env.CORS_ORIGIN.split(","),
      credentials: true,
    })
  );
  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));
  app.use(requestIdMiddleware);

  // 2. Health check route
  app.get("/health", (_req: Request, res: Response) => {
    res.status(200).json({
      status: "ok",
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
    });
  });

  // 3. API Routes v1
  app.use("/api/v1/profile", profileRoutes);

  // 4. Fallback 404 handler
  app.use((req: Request, _res: Response, next: NextFunction) => {
    next(
      new AppError(
        404,
        ErrorCodes.BAD_REQUEST,
        `Tài nguyên không tìm thấy: ${req.method} ${req.originalUrl}`
      )
    );
  });

  // 5. Centralized Error Handler
  app.use(errorHandler);

  return app;
};
