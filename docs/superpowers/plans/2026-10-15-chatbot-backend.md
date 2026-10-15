# Chatbot Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Implement the authenticated chatbot backend defined in `docs/spec.md`, including Gemini responses, persistent conversation history, clickable product suggestions, and a structured action that opens a prefilled incident-report form.

**Architecture:** Add a feature-local chatbot module following the repository's route → controller → service → Prisma pattern. The service owns conversation authorization, verified product/order/payment context, rate limiting, persistence, and response shaping; a replaceable provider seam isolates Gemini. The backend returns navigation data but does not submit an incident report because no incident-report endpoint exists in the current specification.

**Tech Stack:** Node.js 24, Express 5, TypeScript strict mode, Zod 3, Prisma 6, Supabase Auth middleware, Node test runner with `tsx`, Gemini REST `generateContent` through built-in `fetch`.

**Spec:** `docs/spec.md` sections 3, 4, 5, 8, 12, 14, and 15; approved chat behavior from the 2026-10-15 conversation.

## Global Constraints

- Keep secrets in backend environment variables; never return or log the Gemini key or Supabase bearer token.
- Preserve the standard success envelope `{ success, data, meta }` and error envelope `{ success, error, meta }`.
- Protected routes use `authMiddleware -> profileMiddleware -> accountStatusMiddleware -> validateRequest -> controller`.
- `message` is required and contains 1–2000 characters; IDs use UUID validation.
- A user may read, append to, or delete only their own conversation.
- Suggested products must be active, in stock, and loaded from PostgreSQL; Gemini may select IDs but may not invent price, stock, name, or image data.
- Incident actions may prefill a report form but may not submit a report, promise refunds, or change order/payment state.
- Money remains VND backed by Prisma `Decimal(18,0)` and is serialized as an integer-safe decimal string or number within JavaScript's safe range.

## Review Focus

- A conversation ID owned by another user returns `CHATBOT_CONVERSATION_NOT_FOUND`, without revealing that it exists.
- A product, order, or payment context that does not exist or does not belong to the user is rejected before Gemini receives it.
- Gemini timeout and non-2xx/malformed responses map to the documented 504 and 502 chatbot error codes without persisting an assistant reply.
- Concurrent or rapid messages cannot bypass the database-backed per-user rate limit.
- Reloaded history preserves `suggestedProducts` and the incident action so product cards and prefilled navigation still work.

---

### Task 1: Lock the Extended Chat Contract and Persistence Shape

**Files:**
- Modify: `docs/spec.md`
- Modify: `apps/backend/prisma/schema.prisma`
- Create: `apps/backend/prisma/migrations/20261015_add_chatbot_message_metadata/migration.sql`
- Modify: `apps/backend/.env.example`
- Modify: `render.yaml`

**Interfaces:**
- Consumes: Existing section 8 chatbot request/response contract and `ChatbotMessage` model.
- Produces: Optional request `context`, optional response `action`, history message metadata, and `ChatbotMessage.metadata Json?`.

- [x] **Step 1: Update section 8 of `docs/spec.md`**

Document optional `context.orderId`, `context.paymentId`, and `context.source`; document `action.type = OPEN_INCIDENT_REPORT` and its editable draft fields; add `suggestedProducts` and `action` to history items. State that the client opens the form and the user confirms submission.

- [x] **Step 2: Add assistant-message metadata persistence**

Add `metadata Json?` mapped to `metadata` on `ChatbotMessage` and a migration containing `ALTER TABLE "chatbot_messages" ADD COLUMN "metadata" JSONB`.

- [x] **Step 3: Add environment contract**

Document `GEMINI_API_KEY`, `GEMINI_MODEL`, `GEMINI_API_BASE_URL`, `GEMINI_TIMEOUT_MS`, and `CHATBOT_RATE_LIMIT_MS` in `.env.example`; add the secret/config keys to `render.yaml` without values.

- [x] **Step 4: Verify schema and migration**

Run: `corepack pnpm prisma:validate && corepack pnpm prisma:generate`

Expected: both commands exit 0 and generated Prisma types expose `ChatbotMessage.metadata`.

- [x] **Step 5: Commit**

```bash
git add docs/spec.md apps/backend/prisma apps/backend/.env.example render.yaml
git commit -m "docs(chatbot): define structured chat actions"
```

### Task 2: Validate Chatbot Requests and Define Public Result Types

**Files:**
- Create: `apps/backend/src/modules/chatbot/chatbot.schema.ts`
- Create: `apps/backend/src/modules/chatbot/chatbot.types.ts`
- Create: `apps/backend/src/modules/chatbot/chatbot.schema.test.ts`
- Modify: `apps/backend/package.json`

**Interfaces:**
- Consumes: Extended section 8 request and response fields from Task 1.
- Produces: `SendChatbotMessageInput`, `ConversationParams`, `HistoryQuery`, `ChatbotAction`, `SuggestedProduct`, and validated Zod schemas.

- [x] **Step 1: Add the backend test command and write failing schema tests**

Add `"test": "node --import tsx --test src/**/*.test.ts"`. Test acceptance of a 1-character message with optional UUID context, rejection of empty/2001-character messages, invalid UUIDs, unknown fields, and page values below 1.

- [x] **Step 2: Run tests to verify RED**

Run: `corepack pnpm --filter @plant-flower/backend test -- chatbot.schema.test.ts`

Expected: FAIL because the chatbot schemas do not exist.

- [x] **Step 3: Implement the schemas and public result types**

Export strict Zod schemas and inferred inputs. Use a discriminated action type whose only current value is `OPEN_INCIDENT_REPORT`; keep `action` nullable in send/history results.

- [x] **Step 4: Run tests to verify GREEN**

Run: `corepack pnpm --filter @plant-flower/backend test -- chatbot.schema.test.ts`

Expected: PASS.

- [x] **Step 5: Commit**

```bash
git add apps/backend/package.json apps/backend/src/modules/chatbot
git commit -m "feat(chatbot): validate message requests"
```

### Task 3: Implement the Replaceable Gemini Provider

**Files:**
- Create: `apps/backend/src/modules/chatbot/chatbot.provider.ts`
- Create: `apps/backend/src/modules/chatbot/gemini.provider.ts`
- Create: `apps/backend/src/modules/chatbot/gemini.provider.test.ts`
- Modify: `apps/backend/src/config/env.ts`

**Interfaces:**
- Consumes: `ChatbotProviderInput` containing the user message, recent history, verified catalog products, and verified incident context.
- Produces: `ChatbotProvider.generate(input, signal?) -> Promise<{ reply: string; suggestedProductIds: string[]; actionDraft: IncidentDraft | null }>`.

- [x] **Step 1: Write failing provider tests**

Use an injected `fetch` adapter. Test parsing a valid structured Gemini response, dropping product IDs outside the supplied catalog, mapping an aborted request to `CHATBOT_PROVIDER_TIMEOUT`, and mapping non-2xx or malformed responses to `CHATBOT_PROVIDER_ERROR`.

- [x] **Step 2: Run tests to verify RED**

Run: `corepack pnpm --filter @plant-flower/backend test -- gemini.provider.test.ts`

Expected: FAIL because the provider modules do not exist.

- [x] **Step 3: Implement the provider interface and Gemini adapter**

Call `{GEMINI_API_BASE_URL}/models/{GEMINI_MODEL}:generateContent` with `x-goog-api-key`, JSON response instructions, and `AbortController`. The system instruction must require Vietnamese answers, catalog-only facts, no refund promises, and JSON containing `reply`, `suggestedProductIds`, and nullable `actionDraft`.

- [x] **Step 4: Run tests to verify GREEN**

Run: `corepack pnpm --filter @plant-flower/backend test -- gemini.provider.test.ts`

Expected: PASS.

- [x] **Step 5: Commit**

```bash
git add apps/backend/src/config/env.ts apps/backend/src/modules/chatbot
git commit -m "feat(chatbot): add Gemini provider adapter"
```

### Task 4: Implement Conversation Persistence and Send-Message Logic

**Files:**
- Create: `apps/backend/src/modules/chatbot/chatbot.repository.ts`
- Create: `apps/backend/src/modules/chatbot/prisma-chatbot.repository.ts`
- Create: `apps/backend/src/modules/chatbot/chatbot.service.ts`
- Create: `apps/backend/src/modules/chatbot/chatbot.service.test.ts`

**Interfaces:**
- Consumes: Validated `SendChatbotMessageInput`, trusted `userId`, `ChatbotProvider`, and `ChatbotRepository`.
- Produces: `ChatbotService.sendMessage(userId, input) -> Promise<SendChatbotMessageResult>`.

- [x] **Step 1: Write failing send-message tests**

Test new conversation creation, existing conversation ownership, product-not-found handling, verified order/payment context, active in-stock product suggestions, assistant metadata persistence, no provider call for invalid context, and `CHATBOT_RATE_LIMITED` for a recent user message.

- [x] **Step 2: Run tests to verify RED**

Run: `corepack pnpm --filter @plant-flower/backend test -- chatbot.service.test.ts`

Expected: FAIL because the repository and service do not exist.

- [x] **Step 3: Implement the repository seam and Prisma adapter**

Expose focused methods for owned conversation lookup, recent messages, active catalog/context product loading, owned order/payment context verification, last-user-message lookup, atomic exchange persistence, paged history, and owned deletion. Serialize Prisma decimals at the adapter edge.

- [x] **Step 4: Implement `ChatbotService.sendMessage`**

Validate ownership and context before provider invocation, generate a title from the first message, pass only verified data to Gemini, resolve provider-selected product IDs against the verified catalog, construct the incident action from verified IDs plus editable text, and persist user/assistant messages atomically after a successful provider response.

- [x] **Step 5: Run tests to verify GREEN**

Run: `corepack pnpm --filter @plant-flower/backend test -- chatbot.service.test.ts`

Expected: PASS.

- [x] **Step 6: Commit**

```bash
git add apps/backend/src/modules/chatbot
git commit -m "feat(chatbot): persist Gemini conversations"
```

### Task 5: Implement History and Delete Behaviors

**Files:**
- Modify: `apps/backend/src/modules/chatbot/chatbot.service.ts`
- Modify: `apps/backend/src/modules/chatbot/chatbot.service.test.ts`

**Interfaces:**
- Consumes: Repository methods established in Task 4.
- Produces: `getHistory(userId, conversationId, page)` and `deleteConversation(userId, conversationId)`.

- [x] **Step 1: Write failing history and deletion tests**

Test chronological page output with conversation data and restored metadata, 404 for missing/foreign conversations, owned deletion, and no delete call for a foreign conversation.

- [x] **Step 2: Run tests to verify RED**

Run: `corepack pnpm --filter @plant-flower/backend test -- chatbot.service.test.ts`

Expected: FAIL because history/delete methods are missing.

- [x] **Step 3: Implement history and deletion**

Use a fixed documented page size of 20. Return persisted `suggestedProducts` and `action` for assistant messages; return null/empty values for user messages.

- [x] **Step 4: Run tests to verify GREEN**

Run: `corepack pnpm --filter @plant-flower/backend test -- chatbot.service.test.ts`

Expected: PASS.

- [x] **Step 5: Commit**

```bash
git add apps/backend/src/modules/chatbot
git commit -m "feat(chatbot): add history and conversation deletion"
```

### Task 6: Expose the Authenticated HTTP Routes

**Files:**
- Create: `apps/backend/src/modules/chatbot/chatbot.controller.ts`
- Create: `apps/backend/src/modules/chatbot/chatbot.routes.ts`
- Create: `apps/backend/src/modules/chatbot/chatbot.routes.test.ts`
- Modify: `apps/backend/src/app.ts`

**Interfaces:**
- Consumes: Chatbot schemas and service methods from Tasks 2, 4, and 5.
- Produces: `POST /api/v1/chatbot/messages`, `GET /api/v1/chatbot/conversations/:id/messages`, and `DELETE /api/v1/chatbot/conversations/:id`.

- [x] **Step 1: Write failing route tests**

Mount a route factory in an isolated Express app with a trusted test identity and fake service. Assert the standard success envelope, 204 empty delete response, validation error envelope, and delegation of only the authenticated user ID rather than any client-provided user ID.

- [x] **Step 2: Run tests to verify RED**

Run: `corepack pnpm --filter @plant-flower/backend test -- chatbot.routes.test.ts`

Expected: FAIL because routes/controllers do not exist.

- [x] **Step 3: Implement controller and route factory**

Use the standard middleware chain in production, `sendSuccess` for POST/GET, and `res.status(204).send()` for DELETE. Export a factory that accepts the service so route tests do not require Supabase or PostgreSQL.

- [x] **Step 4: Register the routes**

Mount `chatbotRoutes` at `/api/v1/chatbot` before the 404 handler in `createApp()`.

- [x] **Step 5: Run tests to verify GREEN**

Run: `corepack pnpm --filter @plant-flower/backend test -- chatbot.routes.test.ts`

Expected: PASS.

- [x] **Step 6: Commit**

```bash
git add apps/backend/src/app.ts apps/backend/src/modules/chatbot
git commit -m "feat(chatbot): expose authenticated chatbot routes"
```

### Task 7: Full Verification and Integration Documentation

**Files:**
- Modify: `apps/backend/README.md`

**Interfaces:**
- Consumes: Completed chatbot module and environment contract.
- Produces: Reproducible local setup and verification instructions for the team.

- [x] **Step 1: Document local Gemini setup and endpoint examples**

Explain that `GEMINI_API_KEY` belongs in `apps/backend/.env`, show requests without real secrets, and describe the product-card and incident-action client behavior.

- [x] **Step 2: Run the full backend checks**

Run: `corepack pnpm prisma:validate && corepack pnpm prisma:generate && corepack pnpm typecheck:backend && corepack pnpm build:backend && corepack pnpm --filter @plant-flower/backend test`

Expected: every command exits 0 and all tests pass.

- [x] **Step 3: Review the diff for secrets and scope**

Run: `git diff --check && git status --short && git diff --stat`

Expected: no whitespace errors, no `.env` files staged, and changes limited to chatbot/backend contract files plus this plan.

- [x] **Step 4: Commit**

```bash
git add apps/backend/README.md docs/superpowers/plans/2026-10-15-chatbot-backend.md
git commit -m "docs(chatbot): add backend integration guide"
```

