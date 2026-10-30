import type { NextFunction, Request, Response } from "express";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { sendSuccess } from "../../common/utils/response";
import { sepayWebhookSchema } from "./sepay-webhook.schema";
import { sepayWebhookService } from "./sepay-webhook.service";

export class SepayWebhookController {
  async receive(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const parsed = sepayWebhookSchema.safeParse(req.body);
      if (!parsed.success) {
        throw new AppError(
          400,
          ErrorCodes.BAD_REQUEST,
          "Payload webhook SePay không đúng định dạng.",
          parsed.error.flatten()
        );
      }

      const result = await sepayWebhookService.process(parsed.data, req.body);
      sendSuccess(req, res, result);
    } catch (error) {
      next(error);
    }
  }
}

export const sepayWebhookController = new SepayWebhookController();
