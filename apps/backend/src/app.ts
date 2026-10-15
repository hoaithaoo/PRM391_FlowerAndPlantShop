import express, { Application, Request, Response, NextFunction } from "express";
import helmet from "helmet";
import cors from "cors";
import { env } from "./config/env";
import { requestIdMiddleware } from "./middlewares/request-id.middleware";
import { errorHandler } from "./middlewares/error-handler";
import { AppError } from "./common/errors/app-error";
import { ErrorCodes } from "./common/errors/error-codes";
import { profileRoutes } from "./modules/profiles/profile.routes";
import { authMiddleware } from "./middlewares/auth.middleware";
import { profileMiddleware } from "./middlewares/profile.middleware";
import { accountStatusMiddleware } from "./middlewares/account-status.middleware";
import { createChatbotRoutes } from "./modules/chatbot/chatbot.routes";
import { PrismaChatbotRepository } from "./modules/chatbot/prisma-chatbot.repository";
import { GeminiChatbotProvider } from "./modules/chatbot/gemini.provider";
import { ChatbotService } from "./modules/chatbot/chatbot.service";

const chatbotRepository = new PrismaChatbotRepository(undefined, env.GEMINI_TIMEOUT_MS + 10_000);
const chatbotProvider = new GeminiChatbotProvider({
  apiKey: env.GEMINI_API_KEY ?? "",
  model: env.GEMINI_MODEL,
  baseUrl: env.GEMINI_API_BASE_URL,
  timeoutMs: env.GEMINI_TIMEOUT_MS,
});
const chatbotService = new ChatbotService({
  repository: chatbotRepository,
  provider: chatbotProvider,
  rateLimitMs: env.CHATBOT_RATE_LIMIT_MS,
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
  app.use("/api/v1/chatbot", chatbotRoutes);

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
