import { RequestHandler, Router } from "express";

import { validateRequest } from "../../middlewares/validate.middleware";
import {
  ConversationParams,
  conversationParamsSchema,
  HistoryQuery,
  historyQuerySchema,
  SendChatbotMessageInput,
  sendChatbotMessageSchema,
} from "./chatbot.schema";
import { ChatbotHistoryResult, SendChatbotMessageResult } from "./chatbot.types";
import { ChatbotController } from "./chatbot.controller";

export interface ChatbotServiceContract {
  sendMessage(userId: string, input: SendChatbotMessageInput): Promise<SendChatbotMessageResult>;
  getHistory(userId: string, conversationId: string, page: number): Promise<ChatbotHistoryResult>;
  deleteConversation(userId: string, conversationId: string): Promise<void>;
}

export function createChatbotRoutes(
  service: ChatbotServiceContract,
  authenticationMiddlewares: RequestHandler[]
): Router {
  const router = Router();
  const controller = new ChatbotController(service);

  router.use(...authenticationMiddlewares);
  router.post(
    "/messages",
    validateRequest({ body: sendChatbotMessageSchema }),
    (req, res, next) => void controller.sendMessage(req, res, next)
  );
  router.get(
    "/conversations/:id/messages",
    validateRequest({ params: conversationParamsSchema, query: historyQuerySchema }),
    (req, res, next) => void controller.getHistory(req, res, next)
  );
  router.delete(
    "/conversations/:id",
    validateRequest({ params: conversationParamsSchema }),
    (req, res, next) => void controller.deleteConversation(req, res, next)
  );

  return router;
}

// Keep the inferred request contracts visible at this module boundary.
export type ChatbotRouteParams = ConversationParams;
export type ChatbotRouteHistoryQuery = HistoryQuery;
