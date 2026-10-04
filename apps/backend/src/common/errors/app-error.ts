import { ErrorCode } from "./error-codes";

export class AppError extends Error {
  constructor(
    public statusCode: number,
    public code: ErrorCode | string,
    message: string,
    public details?: unknown
  ) {
    super(message);
    this.name = "AppError";
    Object.setPrototypeOf(this, new.target.prototype);
    Error.captureStackTrace(this, this.constructor);
  }
}
