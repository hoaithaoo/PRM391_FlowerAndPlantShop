import { Request, Response, NextFunction } from "express";
import { AnyZodObject, ZodError } from "zod";
import { AppError } from "../common/errors/app-error";
import { ErrorCodes } from "../common/errors/error-codes";

interface ValidationSchemas {
  body?: AnyZodObject;
  query?: AnyZodObject;
  params?: AnyZodObject;
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
        req.query = await schemas.query.parseAsync(req.query);
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
