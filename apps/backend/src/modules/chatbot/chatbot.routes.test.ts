import assert from "node:assert/strict";
import { AddressInfo } from "node:net";
import { test } from "node:test";
import express, { NextFunction, Request, Response } from "express";

import { errorHandler } from "../../middlewares/error-handler";
import { requestIdMiddleware } from "../../middlewares/request-id.middleware";
import { ChatbotServiceContract, createChatbotRoutes } from "./chatbot.routes";

const USER_ID = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
const CONVERSATION_ID = "cccccccc-cccc-4ccc-8ccc-cccccccccccc";
const MESSAGE_ID = "12121212-1212-4121-8121-121212121212";

class FakeChatbotService implements ChatbotServiceContract {
  sendCalls: Array<{ userId: string; input: unknown }> = [];
  historyCalls: Array<{ userId: string; conversationId: string; page: number }> = [];
  deleteCalls: Array<{ userId: string; conversationId: string }> = [];

  async sendMessage(userId: string, input: unknown) {
    this.sendCalls.push({ userId, input });
    return {
      conversationId: CONVERSATION_ID,
      messageId: MESSAGE_ID,
      reply: "Xin chào",
      suggestedProducts: [],
      action: null,
      createdAt: "2026-10-15T10:00:00.000Z",
    };
  }

  async getHistory(userId: string, conversationId: string, page: number) {
    this.historyCalls.push({ userId, conversationId, page });
    return {
      conversation: { id: conversationId, title: "Chat" },
      items: [],
      page,
      pageSize: 20,
      total: 0,
      totalPages: 0,
    };
  }

  async deleteConversation(userId: string, conversationId: string): Promise<void> {
    this.deleteCalls.push({ userId, conversationId });
  }
}

const trustedIdentity = (req: Request, _res: Response, next: NextFunction) => {
  req.auth = { userId: USER_ID };
  next();
};

async function request(
  service: FakeChatbotService,
  path: string,
  init?: RequestInit
): Promise<{ response: globalThis.Response; text: string }> {
  const app = express();
  app.use(express.json());
  app.use(requestIdMiddleware);
  app.use("/api/v1/chatbot", createChatbotRoutes(service, [trustedIdentity]));
  app.use(errorHandler);

  const server = app.listen(0);
  await new Promise<void>((resolve) => server.once("listening", resolve));
  const port = (server.address() as AddressInfo).port;
  try {
    const response = await fetch(`http://127.0.0.1:${port}${path}`, init);
    return { response, text: await response.text() };
  } finally {
    await new Promise<void>((resolve, reject) =>
      server.close((error) => (error ? reject(error) : resolve()))
    );
  }
}

test("POST returns the standard success envelope and trusts only authenticated user identity", async () => {
  const service = new FakeChatbotService();
  const { response, text } = await request(service, "/api/v1/chatbot/messages", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ message: "Xin chào" }),
  });
  const body = JSON.parse(text);

  assert.equal(response.status, 200);
  assert.equal(body.success, true);
  assert.equal(body.data.conversationId, CONVERSATION_ID);
  assert.equal(typeof body.meta.requestId, "string");
  assert.deepEqual(service.sendCalls, [{ userId: USER_ID, input: { message: "Xin chào" } }]);
});

test("GET validates pagination and delegates the authenticated identity", async () => {
  const service = new FakeChatbotService();
  const { response, text } = await request(
    service,
    `/api/v1/chatbot/conversations/${CONVERSATION_ID}/messages?page=2`
  );
  const body = JSON.parse(text);

  assert.equal(response.status, 200);
  assert.equal(body.data.page, 2);
  assert.deepEqual(service.historyCalls, [
    { userId: USER_ID, conversationId: CONVERSATION_ID, page: 2 },
  ]);
});

test("DELETE returns 204 with an empty body", async () => {
  const service = new FakeChatbotService();
  const { response, text } = await request(
    service,
    `/api/v1/chatbot/conversations/${CONVERSATION_ID}`,
    { method: "DELETE" }
  );

  assert.equal(response.status, 204);
  assert.equal(text, "");
  assert.deepEqual(service.deleteCalls, [{ userId: USER_ID, conversationId: CONVERSATION_ID }]);
});

test("invalid body returns the standard validation error envelope without invoking the service", async () => {
  const service = new FakeChatbotService();
  const { response, text } = await request(service, "/api/v1/chatbot/messages", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ message: "", userId: "attacker-controlled" }),
  });
  const body = JSON.parse(text);

  assert.equal(response.status, 422);
  assert.equal(body.success, false);
  assert.equal(body.error.code, "VALIDATION_ERROR");
  assert.equal(typeof body.meta.requestId, "string");
  assert.equal(service.sendCalls.length, 0);
});
