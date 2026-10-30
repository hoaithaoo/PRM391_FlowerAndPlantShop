import express, { Application, Request, Response, NextFunction } from "express";
import helmet from "helmet";
import cors from "cors";
import { env } from "./config/env";
import { requestIdMiddleware } from "./middlewares/request-id.middleware";
import { errorHandler } from "./middlewares/error-handler";
import { AppError } from "./common/errors/app-error";
import { ErrorCodes } from "./common/errors/error-codes";
import { profileRoutes } from "./modules/profiles/profile.routes";
import {
  adminProductRoutes,
  productRoutes,
} from "./modules/products/product.routes";
import { storeRoutes } from "./modules/stores/store.routes";
import { cartRoutes } from "./modules/carts/cart.routes";
import { checkoutRoutes } from "./modules/checkout/checkout.routes";
import { notificationRoutes } from "./modules/notifications/notification.routes";
import { paymentRoutes } from "./modules/payments/payment.routes";
import { sepayWebhookRoutes } from "./modules/webhooks/sepay-webhook.routes";
import { rejectCompressedSepayWebhook } from "./modules/webhooks/sepay-signature";

export const createApp = (): Application => {
  const app = express();
  const allowAnyOrigin = env.CORS_ORIGIN === "*";
  const allowedOrigins = env.CORS_ORIGIN.split(",")
    .map((origin) => origin.trim())
    .filter(Boolean);

  // 1. Security & Core Middlewares
  app.use(helmet());
  app.use(
    cors({
      origin: allowAnyOrigin ? "*" : allowedOrigins,
      // Browsers reject Access-Control-Allow-Origin: * together with credentials.
      credentials: !allowAnyOrigin,
    })
  );
  app.use(requestIdMiddleware);
  app.use("/api/v1/webhooks/sepay", rejectCompressedSepayWebhook);
  app.use(
    express.json({
      verify: (req, _res, buffer) => {
        (req as Request).rawBody = Buffer.from(buffer);
      },
    })
  );
  app.use(express.urlencoded({ extended: true }));

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
  app.use("/api/v1/products", productRoutes);
  app.use("/api/v1/admin/products", adminProductRoutes);
  app.use("/api/v1/stores", storeRoutes);
  app.use("/api/v1/cart", cartRoutes);
  app.use("/api/v1/checkout", checkoutRoutes);
  app.use("/api/v1/payments", paymentRoutes);
  app.use("/api/v1/notifications", notificationRoutes);
  app.use("/api/v1/webhooks/sepay", sepayWebhookRoutes);

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
