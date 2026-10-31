import express, { Application, Request, Response, NextFunction } from "express";
import helmet from "helmet";
import cors from "cors";
import swaggerUi from "swagger-ui-express";
import { buildOpenApiDocument } from "./docs/openapi";
import { env } from "./config/env";
import { requestIdMiddleware } from "./middlewares/request-id.middleware";
import { errorHandler } from "./middlewares/error-handler";
import { AppError } from "./common/errors/app-error";
import { ErrorCodes } from "./common/errors/error-codes";
import { profileRoutes } from "./modules/profiles/profile.routes";
import {
  adminCategoryRoutes,
  categoryRoutes,
} from "./modules/categories/category.routes";
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
import { addressRoutes } from "./modules/addresses/address.routes";
import { authRoutes } from "./modules/auth/auth.routes";
import { adminDashboardRoutes } from "./modules/dashboard/dashboard.routes";
import {
  adminInvoiceRoutes,
  invoiceRoutes,
} from "./modules/invoices/invoice.routes";
import { adminOrderRoutes, orderRoutes } from "./modules/orders/order.routes";
import {
  adminPaymentRoutes,
  adminSepayTransactionRoutes,
} from "./modules/payments/payment.routes";
import { adminUserRoutes } from "./modules/users/user.routes";
import { authMiddleware } from "./middlewares/auth.middleware";
import { profileMiddleware } from "./middlewares/profile.middleware";
import { accountStatusMiddleware } from "./middlewares/account-status.middleware";
import { createChatbotRoutes } from "./modules/chatbot/chatbot.routes";
import { PrismaChatbotRepository } from "./modules/chatbot/repository/prisma-chatbot.repository";
import { GeminiChatbotProvider } from "./modules/chatbot/providers/gemini.provider";
import { ChatbotService } from "./modules/chatbot/chatbot.service";
import { GeminiEmbeddingProvider } from "./modules/chatbot/providers/gemini-embedding.provider";

const chatbotRepository = new PrismaChatbotRepository();
const chatbotProvider = new GeminiChatbotProvider({
  apiKey: env.GEMINI_API_KEY ?? "",
  model: env.GEMINI_MODEL,
  baseUrl: env.GEMINI_API_BASE_URL,
  timeoutMs: env.GEMINI_TIMEOUT_MS,
});
const embeddingProvider = new GeminiEmbeddingProvider({
  apiKey: env.GEMINI_API_KEY ?? "",
  model: env.GEMINI_EMBEDDING_MODEL,
  baseUrl: env.GEMINI_API_BASE_URL,
  dimensions: env.RAG_EMBEDDING_DIMENSIONS,
  timeoutMs: env.GEMINI_TIMEOUT_MS,
});
const chatbotService = new ChatbotService({
  repository: chatbotRepository,
  provider: chatbotProvider,
  embeddingProvider,
  embeddingModel: env.GEMINI_EMBEDDING_MODEL,
  minSemanticScore: env.RAG_MIN_SEMANTIC_SCORE,
  rateLimitMs: env.CHATBOT_RATE_LIMIT_MS,
  // Một lượt chat có tối đa hai network calls liên tiếp: embedding rồi generation.
  sendLeaseMs: env.GEMINI_TIMEOUT_MS * 2 + 10_000,
});
const chatbotRoutes = createChatbotRoutes(chatbotService, [
  authMiddleware,
  profileMiddleware,
  accountStatusMiddleware,
]);

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

  // 2b. Tài liệu API (Swagger UI) — trang gốc chuyển thẳng tới đây
  const openApiDocument = buildOpenApiDocument();
  app.get("/", (_req: Request, res: Response) => res.redirect("/api/docs"));
  app.get("/api/docs.json", (_req: Request, res: Response) => {
    res.json(openApiDocument);
  });
  app.use(
    "/api/docs",
    swaggerUi.serve,
    swaggerUi.setup(openApiDocument, {
      customSiteTitle: "Plant & Flower Shop API",
      swaggerOptions: { persistAuthorization: true, docExpansion: "none" },
    })
  );

  // 3. API Routes v1
  app.use("/api/v1/auth", authRoutes);
  app.use("/api/v1/profile", profileRoutes);
  app.use("/api/v1/categories", categoryRoutes);
  app.use("/api/v1/admin/categories", adminCategoryRoutes);
  app.use("/api/v1/products", productRoutes);
  app.use("/api/v1/admin/products", adminProductRoutes);
  app.use("/api/v1/stores", storeRoutes);
  app.use("/api/v1/cart", cartRoutes);
  app.use("/api/v1/checkout", checkoutRoutes);
  app.use("/api/v1/orders", orderRoutes);
  app.use("/api/v1/invoices", invoiceRoutes);
  app.use("/api/v1/payments", paymentRoutes);
  app.use("/api/v1/notifications", notificationRoutes);
  app.use("/api/v1/webhooks/sepay", sepayWebhookRoutes);
  app.use("/api/v1/user-addresses", addressRoutes);
  app.use("/api/v1/addresses", addressRoutes);
  app.use("/api/v1/chatbot", chatbotRoutes);

  // 3b. Admin API (spec mục 9)
  app.use("/api/v1/admin/dashboard", adminDashboardRoutes);
  app.use("/api/v1/admin/users", adminUserRoutes);
  app.use("/api/v1/admin/orders", adminOrderRoutes);
  app.use("/api/v1/admin/invoices", adminInvoiceRoutes);
  app.use("/api/v1/admin/payments", adminPaymentRoutes);
  app.use("/api/v1/admin/sepay-transactions", adminSepayTransactionRoutes);

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
