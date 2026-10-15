import { NextFunction, Request, Response } from "express";
import { sendSuccess } from "../../common/utils/response";
import { ListProductsQuery } from "./product.schema";
import { productService } from "./product.service";

export class ProductController {
  async list(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await productService.list(
        req.query as unknown as ListProductsQuery
      );
      sendSuccess(req, res, { items: result.items }, 200, {
        page: result.page,
        total: result.total,
        totalPages: result.totalPages,
      });
    } catch (error) {
      next(error);
    }
  }

  async getById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const product = await productService.getActiveById(req.params.id as string);
      sendSuccess(req, res, product);
    } catch (error) {
      next(error);
    }
  }

  async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const product = await productService.create(req.body);
      sendSuccess(req, res, product, 201);
    } catch (error) {
      next(error);
    }
  }

  async update(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const product = await productService.update(req.params.id as string, req.body);
      sendSuccess(req, res, product);
    } catch (error) {
      next(error);
    }
  }

  async delete(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await productService.delete(req.params.id as string);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  }
}

export const productController = new ProductController();
