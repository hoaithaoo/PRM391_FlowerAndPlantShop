# Chatbot Mobile Overlay Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a persistent Flutter chatbot launcher and panel that can appear above every authenticated customer screen, call the existing chatbot API, render clickable product suggestions, and open a prefilled incident report through callbacks.

**Architecture:** Add a self-contained `features/chatbot` module following the repository's checkout and notification feature patterns: models, transport/repository, `ChangeNotifier` controller, widgets, and a barrel export. `ChatbotOverlayHost` wraps the app navigator once through `MaterialApp.builder`; navigation to product details and incident reporting stays behind callbacks so this feature does not edit another team's screens or router.

**Tech Stack:** Flutter 3.47, Dart 3.13, `ChangeNotifier`, Flutter widget tests.

**Spec:** `docs/spec.md` sections 8.1-8.3 and `docs/superpowers/plans/2026-10-15-chatbot-backend.md`

## Global Constraints

- Keep Gemini and all provider secrets on the backend.
- Use `POST /api/v1/chatbot/messages`, `GET /api/v1/chatbot/conversations/:id/messages`, and `DELETE /api/v1/chatbot/conversations/:id` exactly as documented.
- Treat `suggestedProducts[].id` as the navigation identifier for product detail.
- Treat `OPEN_INCIDENT_REPORT` as a client navigation suggestion; the user must review and submit the form separately.
- Do not edit checkout, product-detail, incident-report, or router files owned by other feature branches.
- Keep the launcher hidden unless the app shell marks the current area as an authenticated customer screen.

## Review Focus

- A second send while a request is in flight must be ignored so duplicate user messages are not created.
- API authentication failures must surface a useful error without discarding the current conversation.
- Malformed optional product/action metadata must not crash the chat panel.
- Closing and reopening the panel must preserve the in-memory conversation and conversation ID.
- Product and incident actions must call host callbacks with the complete parsed payload.

---

### Task 1: Flutter package and chatbot domain models

**Files:**
- Create: `apps/mobile/pubspec.yaml`
- Create: `apps/mobile/analysis_options.yaml`
- Modify: `pubspec.yaml`
- Create: `apps/mobile/lib/features/chatbot/models/chatbot_models.dart`
- Test: `apps/mobile/test/features/chatbot/chatbot_models_test.dart`

**Interfaces:**
- Produces: `ChatMessage`, `SuggestedProduct`, `IncidentReportDraft`, `ChatbotAction`, `ChatbotReply`, and `ChatbotRequestContext` with defensive JSON parsing.

- [x] Write model parsing tests for a normal reply, product suggestions, `OPEN_INCIDENT_REPORT`, and malformed optional metadata.
- [x] Run the tests and verify they fail because the models do not exist.
- [x] Implement the minimal immutable models and parsers.
- [x] Run the tests and commit the green result.

### Task 2: Authenticated chatbot data layer

**Files:**
- Create: `apps/mobile/lib/features/chatbot/data/chatbot_failure.dart`
- Create: `apps/mobile/lib/features/chatbot/data/chatbot_remote_data_source.dart`
- Create: `apps/mobile/lib/features/chatbot/data/chatbot_repository.dart`
- Create: `apps/mobile/lib/features/chatbot/data/chatbot_repository_impl.dart`
- Create: `apps/mobile/lib/features/chatbot/data/mock_chatbot_repository.dart`
- Test: `apps/mobile/test/features/chatbot/chatbot_remote_data_source_test.dart`

**Interfaces:**
- Consumes: domain models from Task 1.
- Produces: `ChatbotRepository.sendMessage`, `getHistory`, and `deleteConversation`; `ChatbotRemoteDataSource` receives an abstract transport and access-token provider.

- [x] Write failing tests for endpoint paths, bearer headers, request context serialization, response envelopes, and backend error-code mapping.
- [x] Run the tests and confirm the expected missing-type failures.
- [x] Implement the transport, repository, failure mapping, and deterministic mock.
- [x] Run the tests and commit the green result.

### Task 3: Conversation controller

**Files:**
- Create: `apps/mobile/lib/features/chatbot/state/chatbot_state.dart`
- Create: `apps/mobile/lib/features/chatbot/state/chatbot_controller.dart`
- Test: `apps/mobile/test/features/chatbot/chatbot_controller_test.dart`

**Interfaces:**
- Consumes: `ChatbotRepository` and optional `ChatbotRequestContext Function()`.
- Produces: observable messages, current conversation ID, loading/error states, `send`, `resume`, `startNewConversation`, and `deleteCurrentConversation`.

- [x] Write failing tests for successful send, duplicate-send prevention, provider failure, reopening state preservation, resume, and delete/reset.
- [x] Run the tests and confirm they fail for missing controller behavior.
- [x] Implement the minimal `ChangeNotifier` controller.
- [x] Run the tests and commit the green result.

### Task 4: Persistent overlay and navigation actions

**Files:**
- Create: `apps/mobile/lib/features/chatbot/widgets/chatbot_launcher.dart`
- Create: `apps/mobile/lib/features/chatbot/widgets/chatbot_panel.dart`
- Create: `apps/mobile/lib/features/chatbot/widgets/chat_message_bubble.dart`
- Create: `apps/mobile/lib/features/chatbot/widgets/suggested_product_card.dart`
- Create: `apps/mobile/lib/features/chatbot/widgets/chatbot_overlay_host.dart`
- Create: `apps/mobile/lib/features/chatbot/chatbot.dart`
- Test: `apps/mobile/test/features/chatbot/chatbot_overlay_host_test.dart`

**Interfaces:**
- Consumes: a repository, optional current-context provider, `onProductTap(String productId)`, and `onOpenIncidentReport(IncidentReportDraft draft)`.
- Produces: `ChatbotOverlayHost`, intended for one-time use in `MaterialApp.builder`, plus independently previewable widgets.

- [ ] Write failing widget tests for launcher visibility, opening/closing the panel, message send, product tap, incident action, and state preservation after reopen.
- [ ] Run the tests and verify they fail because the widgets are absent.
- [ ] Implement the launcher, modal panel, bubbles, suggestion cards, quick prompts, typing state, and callbacks.
- [ ] Run widget tests, `flutter analyze`, and the complete mobile test suite.
- [ ] Commit the green result and document the future `MaterialApp.builder` integration snippet in `apps/mobile/README.md`.

### Task 5: Branch verification and handoff

**Files:**
- Modify: `docs/superpowers/plans/2026-10-15-chatbot-mobile-overlay.md`

**Interfaces:**
- Produces: a merge-ready feature branch stacked on `backend/feature/PFS-000-chatbot-api`.

- [ ] Run `flutter analyze` and `flutter test` from `apps/mobile`.
- [ ] Run `git diff --check` and verify no secret or environment value was introduced.
- [ ] Record test output, integration instructions, and rebase guidance below.

## Handoff Notes

- Branch: `mobile/user/feature/PFS-000-chatbot-overlay`
- Base while developing: `backend/feature/PFS-000-chatbot-api`
- After the backend branch merges, rebase this branch onto the updated `main` before opening the mobile PR.
- Do not replace callbacks with direct imports until the owning product-detail, checkout, and incident-report branches have merged.

