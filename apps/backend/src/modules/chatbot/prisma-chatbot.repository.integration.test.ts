import assert from "node:assert/strict";
import { after, describe, test } from "node:test";
import { PrismaClient } from "@prisma/client";

import { PrismaChatbotRepository } from "./prisma-chatbot.repository";

const databaseUrl = process.env.CHATBOT_INTEGRATION_DATABASE_URL;
const client = databaseUrl ? new PrismaClient({ datasourceUrl: databaseUrl }) : null;
const repository = client ? new PrismaChatbotRepository(client) : null;

const metadata = { suggestedProducts: [], action: null };

describe("PrismaChatbotRepository with PostgreSQL", { skip: !databaseUrl }, () => {
  after(async () => {
    await client?.$disconnect();
  });

  test("atomically rejects an overlapping slot and preserves cooldown outside conversation history", async () => {
    const userId = "41414141-4141-4414-8414-414141414141";
    const conversationId = "42424242-4242-4424-8424-424242424242";
    await client!.profile.create({ data: { id: userId, email: "rate-limit@example.com" } });

    try {
      assert.equal(await repository!.tryAcquireSendSlot(userId, 10_000, 30_000), true);
      assert.equal(await repository!.tryAcquireSendSlot(userId, 10_000, 30_000), false);

      await repository!.createExchange({
        conversationId,
        createConversation: true,
        userId,
        title: "Rate limit",
        userMessage: "Tin đầu",
        assistantReply: "Phản hồi đầu",
        assistantMetadata: metadata,
      });
      await repository!.releaseSendSlot(userId);
      await repository!.deleteOwnedConversation(conversationId, userId);

      assert.equal(await repository!.tryAcquireSendSlot(userId, 10_000, 30_000), false);
    } finally {
      await client!.profile.deleteMany({ where: { id: userId } });
    }
  });

  test("returns persisted turns in deterministic user-assistant order", async () => {
    const userId = "51515151-5151-4515-8515-515151515151";
    const conversationId = "52525252-5252-4525-8525-525252525252";
    await client!.profile.create({ data: { id: userId, email: "ordering@example.com" } });

    try {
      await repository!.createExchange({
        conversationId,
        createConversation: true,
        userId,
        title: "Ordering",
        userMessage: "user-1",
        assistantReply: "assistant-1",
        assistantMetadata: metadata,
      });
      await repository!.createExchange({
        conversationId,
        createConversation: false,
        userId,
        title: null,
        userMessage: "user-2",
        assistantReply: "assistant-2",
        assistantMetadata: metadata,
      });

      const recent = await repository!.findRecentMessages(conversationId, 10);
      const history = await repository!.getMessages(conversationId, 1, 20);
      const expected = ["user-1", "assistant-1", "user-2", "assistant-2"];

      assert.deepEqual(recent.map((message) => message.content), expected);
      assert.deepEqual(history.items.map((message) => message.content), expected);
    } finally {
      await client!.profile.deleteMany({ where: { id: userId } });
    }
  });
});
