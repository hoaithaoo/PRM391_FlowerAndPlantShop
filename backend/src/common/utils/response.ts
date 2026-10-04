import { Request, Response } from "express";
import { SuccessResponse, ErrorResponse } from "../types/api-response";
import { AppError } from "../errors/app-error";

export function sendSuccess<T>(
  req: Request,
  res: Response,
  data: T,
  statusCode = 200,
  extraMeta: Record<string, unknown> = {}
): Response {
  const responseBody: SuccessResponse<T> = {
    success: true,
    data,
    meta: {
      requestId: req.requestId || "req_unknown",
      timestamp: new Date().toISOString(),
      ...extraMeta,
    },
  };
  return res.status(statusCode).json(responseBody);
}

export function toErrorBody(err: AppError, req: Request): ErrorResponse {
  return {
    success: false,
    error: {
      code: err.code,
      message: err.message,
      details: err.details ?? null,
    },
    meta: {
      requestId: req.requestId || "req_unknown",
      timestamp: new Date().toISOString(),
      path: req.originalUrl || req.url,
    },
  };
}
