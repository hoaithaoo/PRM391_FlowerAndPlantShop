import { Request, Response, NextFunction, ErrorRequestHandler } from "express";
import { ZodError } from "zod";
import { Prisma } from "@prisma/client";
import { AppError } from "../common/errors/app-error";
import { ErrorCodes } from "../common/errors/error-codes";
import { toErrorBody } from "../common/utils/response";
import { logger } from "../lib/logger";

export const errorHandler: ErrorRequestHandler = (
  err: unknown,
  req: Request,
  res: Response,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  _next: NextFunction
): void => {
  // 1. Explicit business AppError
  if (err instanceof AppError) {
    logger.warn(`[${err.code}] ${err.message}`, {
      statusCode: err.statusCode,
      requestId: req.requestId,
      path: req.originalUrl,
      details: err.details,
    });
    res.status(err.statusCode).json(toErrorBody(err, req));
    return;
  }

  // 2. Unhandled Zod validation error
  if (err instanceof ZodError) {
    const appError = new AppError(
      422,
      ErrorCodes.VALIDATION_ERROR,
      "Dữ liệu không hợp lệ.",
      err.flatten()
    );
    res.status(422).json(toErrorBody(appError, req));
    return;
  }

  // 3. Prisma Known Request Errors
  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    logger.error(`Prisma error: ${err.code}`, {
      code: err.code,
      meta: err.meta,
      requestId: req.requestId,
    });

    if (err.code === "P2002") {
      const appError = new AppError(
        409,
        ErrorCodes.DUPLICATE_RESOURCE,
        "Dữ liệu đã tồn tại trong hệ thống.",
        { target: err.meta?.target }
      );
      res.status(409).json(toErrorBody(appError, req));
      return;
    }

    if (err.code === "P2025") {
      const appError = new AppError(
        404,
        ErrorCodes.BAD_REQUEST,
        "Bản ghi yêu cầu không tồn tại."
      );
      res.status(404).json(toErrorBody(appError, req));
      return;
    }
  }

  // 4. JSON Syntax Error (body-parser)
  if (err instanceof SyntaxError && "body" in err) {
    const appError = new AppError(
      400,
      ErrorCodes.BAD_REQUEST,
      "Malformed JSON payload trong body request."
    );
    res.status(400).json(toErrorBody(appError, req));
    return;
  }

  // 5. Unhandled / unexpected internal errors
  const errorMessage = err instanceof Error ? err.message : "Internal Server Error";
  const errorStack = err instanceof Error ? err.stack : undefined;

  logger.error("Unhandled exception occurred", {
    message: errorMessage,
    stack: errorStack,
    requestId: req.requestId,
    path: req.originalUrl,
  });

  const internalError = new AppError(
    500,
    ErrorCodes.INTERNAL_ERROR,
    "Đã xảy ra lỗi máy chủ nội bộ. Vui lòng thử lại sau."
  );

  res.status(500).json(toErrorBody(internalError, req));
};
