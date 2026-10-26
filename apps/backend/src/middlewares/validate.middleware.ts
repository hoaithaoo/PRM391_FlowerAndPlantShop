import { Request, Response, NextFunction } from "express";
import { AnyZodObject, ZodError, ZodTypeAny } from "zod";
import { AppError } from "../common/errors/app-error";
import { ErrorCodes } from "../common/errors/error-codes";

interface ValidationSchemas {
  body?: ZodTypeAny;
  query?: ZodTypeAny;
  params?: ZodTypeAny;
}

/**
 * validateRequest:
 * - Validates req.body, req.query, req.params against Zod schemas
 * - Formats Zod errors into 422 VALIDATION_ERROR or 400 BAD_REQUEST
 */
export const validateRequest = (schemas: ValidationSchemas) => {
  return async (req: Request, _res: Response, next: NextFunction): Promise<void> => {
    try {
      if (schemas.body) {
        req.body = await schemas.body.parseAsync(req.body);
      }
      if (schemas.query) {
        const validatedQuery = await schemas.query.parseAsync(req.query);
        // Express 5 exposes query through a configurable getter without a setter.
        Object.defineProperty(req, "query", {
          value: validatedQuery,
          writable: true,
          configurable: true,
          enumerable: true,
        });
      }
      if (schemas.params) {
        req.params = await schemas.params.parseAsync(req.params);
      }
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        return next(
          new AppError(
            422,
            ErrorCodes.VALIDATION_ERROR,
            "Dữ liệu gửi lên không đúng định dạng.",
            error.flatten()
          )
        );
      }
      next(error);
    }
  };
};
