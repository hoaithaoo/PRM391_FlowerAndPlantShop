import { Request, Response, NextFunction } from "express";
import { ZodError, ZodTypeAny } from "zod";
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
        const parsedQuery = await schemas.query.parseAsync(req.query);
        // Express 5 exposes req.query through a getter. Define an own property so
        // controllers receive the parsed/coerced values without assigning to it.
        Object.defineProperty(req, "query", {
          value: parsedQuery,
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
        const isQueryOnlyValidation =
          schemas.query !== undefined &&
          schemas.body === undefined &&
          schemas.params === undefined;
        return next(
          new AppError(
            isQueryOnlyValidation ? 400 : 422,
            isQueryOnlyValidation
              ? ErrorCodes.BAD_REQUEST
              : ErrorCodes.VALIDATION_ERROR,
            isQueryOnlyValidation
              ? "Tham số query không đúng định dạng."
              : "Dữ liệu gửi lên không đúng định dạng.",
            error.flatten()
          )
        );
      }
      next(error);
    }
  };
};
