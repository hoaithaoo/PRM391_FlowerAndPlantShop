import { NextFunction, Request, Response } from "express";

import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { sendSuccess } from "../../common/utils/response";
import type { ChatbotServiceContract } from "./chatbot.routes";

/**
 * Controller HTTP của chatbot: lấy userId đã xác thực từ request, gọi ChatbotService
 * và trả kết quả theo định dạng chung { success, data, meta }.
 * - sendMessage: POST /messages, gửi tin nhắn và nhận câu trả lời.
 * - getHistory: GET /conversations/:id/messages, xem lịch sử có phân trang.
 * - deleteConversation: DELETE /conversations/:id, xóa cuộc trò chuyện (trả 204).
 * Không chứa nghiệp vụ; mọi lỗi được chuyển cho error middleware qua next().
 */
export class ChatbotController {
  constructor(private readonly service: ChatbotServiceContract) {}

  async sendMessage(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await this.service.sendMessage(this.requireUserId(req), req.body);
      sendSuccess(req, res, result);
    } catch (error) {
      next(error);
    }
  }

  async getHistory(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await this.service.getHistory(
        this.requireUserId(req),
        req.params.id as string,
        req.query.page as unknown as number
      );
      sendSuccess(req, res, result);
    } catch (error) {
      next(error);
    }
  }

  async deleteConversation(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await this.service.deleteConversation(this.requireUserId(req), req.params.id as string);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  }

  private requireUserId(req: Request): string {
    if (!req.auth?.userId) {
      throw new AppError(401, ErrorCodes.AUTH_TOKEN_MISSING, "Chưa xác thực người dùng.");
    }
    return req.auth.userId;
  }
}
