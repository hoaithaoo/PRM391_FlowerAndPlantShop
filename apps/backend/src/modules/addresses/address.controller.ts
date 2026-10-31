import { Request, Response, NextFunction } from "express";
import { addressService, AddressService } from "./address.service";
import { sendSuccess } from "../../common/utils/response";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";

export class AddressController {
  private readonly service: AddressService;

  constructor(service: AddressService = addressService) {
    this.service = service;
  }

  private getUserId(req: Request): string {
    const userId = req.auth?.userId;
    if (!userId) {
      throw new AppError(401, ErrorCodes.AUTH_TOKEN_MISSING, "Chưa xác thực.");
    }
    return userId;
  }

  async list(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = this.getUserId(req);
      const items = await this.service.listUserAddresses(userId);
      sendSuccess(req, res, { items });
    } catch (err) {
      next(err);
    }
  }

  private getAddressId(req: Request): string {
    const id = req.params.id;
    return Array.isArray(id) ? id[0] : (id ?? "");
  }

  async getById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = this.getUserId(req);
      const addressId = this.getAddressId(req);
      const address = await this.service.getAddressById(userId, addressId);
      sendSuccess(req, res, address);
    } catch (err) {
      next(err);
    }
  }

  async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = this.getUserId(req);
      const created = await this.service.createAddress(userId, req.body);
      sendSuccess(req, res, created, 201);
    } catch (err) {
      next(err);
    }
  }

  async update(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = this.getUserId(req);
      const addressId = this.getAddressId(req);
      const updated = await this.service.updateAddress(userId, addressId, req.body);
      sendSuccess(req, res, updated);
    } catch (err) {
      next(err);
    }
  }

  async delete(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = this.getUserId(req);
      const addressId = this.getAddressId(req);
      await this.service.deleteAddress(userId, addressId);
      res.status(204).send();
    } catch (err) {
      next(err);
    }
  }

  async setDefault(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = this.getUserId(req);
      const addressId = this.getAddressId(req);
      const updated = await this.service.setDefaultAddress(userId, addressId);
      sendSuccess(req, res, updated);
    } catch (err) {
      next(err);
    }
  }
}

export const addressController = new AddressController();
