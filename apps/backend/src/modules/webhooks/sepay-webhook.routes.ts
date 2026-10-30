import { Router } from "express";
import { verifySepaySignature } from "./sepay-signature";
import { sepayWebhookController } from "./sepay-webhook.controller";

export const sepayWebhookRoutes = Router();

sepayWebhookRoutes.post(
  "/",
  verifySepaySignature,
  (req, res, next) => sepayWebhookController.receive(req, res, next)
);
