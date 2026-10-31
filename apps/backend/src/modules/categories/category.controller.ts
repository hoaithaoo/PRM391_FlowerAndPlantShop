import { NextFunction, Request, Response } from "express";
import { sendSuccess } from "../../common/utils/response";
import { ListCategoriesQuery } from "./category.schema";
import { categoryService } from "./category.service";

export class CategoryController {
  async list(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const items = await categoryService.list(
        req.query as unknown as ListCategoriesQuery,
        { includeInactive: false }
      );
      sendSuccess(req, res, { items });
    } catch (error) {
      next(error);
    }
  }

  async adminList(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const items = await categoryService.list(
        req.query as unknown as ListCategoriesQuery,
        { includeInactive: true }
      );
      // Admin app đọc trực tiếp `data` là mảng.
      sendSuccess(req, res, items);
    } catch (error) {
      next(error);
    }
  }

  async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const category = await categoryService.create(req.body);
      sendSuccess(req, res, category, 201);
    } catch (error) {
      next(error);
    }
  }

  async update(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const category = await categoryService.update(
        req.params.id as string,
        req.body
      );
      sendSuccess(req, res, category);
    } catch (error) {
      next(error);
    }
  }

  async delete(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await categoryService.delete(req.params.id as string);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  }
}

export const categoryController = new CategoryController();
