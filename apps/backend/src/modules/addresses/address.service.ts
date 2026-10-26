import { PrismaClient } from "@prisma/client";
import { prisma as defaultPrisma } from "../../lib/prisma";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { geocodeAddress as defaultGeocodeAddress, GeoCoordinates } from "../../common/utils/geocoder";
import { CreateAddressInput, UpdateAddressInput } from "./address.schema";
import { logger } from "../../lib/logger";

export interface AddressResponse {
  id: string;
  userId: string;
  recipientName: string;
  recipientPhone: string;
  phone: string; // compatibility alias for recipientPhone
  addressLine: string;
  address: string; // compatibility alias for addressLine
  label: string | null;
  deliveryNote: string | null;
  driverNote: string | null; // compatibility alias for deliveryNote
  isDefault: boolean;
  isDelete: boolean;
  latitude: number | null;
  longitude: number | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface AddressServiceDeps {
  prisma?: PrismaClient;
  geocoder?: (address: string) => Promise<GeoCoordinates | null>;
}

export class AddressService {
  private readonly prisma: PrismaClient;
  private readonly geocode: (address: string) => Promise<GeoCoordinates | null>;

  constructor(deps: AddressServiceDeps = {}) {
    this.prisma = deps.prisma ?? defaultPrisma;
    this.geocode = deps.geocoder ?? defaultGeocodeAddress;
  }

  /**
   * Format Prisma record into standard API response.
   * Includes both exact DB fields and aliases for frontend compatibility.
   */
  private formatAddress(record: {
    id: string;
    userId: string;
    recipientName: string;
    recipientPhone: string;
    addressLine: string;
    label: string | null;
    deliveryNote: string | null;
    isDefault: boolean;
    isDelete: boolean | null;
    latitude: number | null;
    longitude: number | null;
    createdAt: Date;
    updatedAt: Date;
  }): AddressResponse {
    return {
      id: record.id,
      userId: record.userId,
      recipientName: record.recipientName,
      recipientPhone: record.recipientPhone,
      phone: record.recipientPhone,
      addressLine: record.addressLine,
      address: record.addressLine,
      label: record.label ?? "Nhà riêng",
      deliveryNote: record.deliveryNote,
      driverNote: record.deliveryNote,
      isDefault: record.isDefault,
      isDelete: record.isDelete ?? false,
      latitude: record.latitude,
      longitude: record.longitude,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    };
  }

  /**
   * Ensure coordinates exist: if latitude or longitude is missing,
   * geocode using the address text and persist the resolved coordinates to the database.
   */
  private async ensureCoordinates(addressRecord: {
    id: string;
    addressLine: string;
    latitude: number | null;
    longitude: number | null;
  }): Promise<{ latitude: number | null; longitude: number | null }> {
    const hasLat = addressRecord.latitude !== null && addressRecord.latitude !== undefined;
    const hasLng = addressRecord.longitude !== null && addressRecord.longitude !== undefined;

    if (hasLat && hasLng) {
      return {
        latitude: addressRecord.latitude,
        longitude: addressRecord.longitude,
      };
    }

    const fullAddress = addressRecord.addressLine?.trim();
    if (!fullAddress) {
      return { latitude: null, longitude: null };
    }

    try {
      const coords = await this.geocode(fullAddress);
      if (coords) {
        // Save coordinates back to database
        await this.prisma.userAddress.update({
          where: { id: addressRecord.id },
          data: {
            latitude: coords.latitude,
            longitude: coords.longitude,
          },
        });

        logger.info("Auto-geocoded and saved coordinates for user address", {
          addressId: addressRecord.id,
          coords,
        });

        return coords;
      }
    } catch (err) {
      logger.warn("Failed to auto-geocode address", {
        addressId: addressRecord.id,
        error: err,
      });
    }

    return {
      latitude: addressRecord.latitude ?? null,
      longitude: addressRecord.longitude ?? null,
    };
  }

  /**
   * List all active addresses for a user.
   * Auto-resolves lat/long for addresses that lack coordinates, updates DB, and returns updated list.
   */
  async listUserAddresses(userId: string): Promise<AddressResponse[]> {
    const addresses = await this.prisma.userAddress.findMany({
      where: {
        userId,
        OR: [{ isDelete: false }, { isDelete: null }],
      },
      orderBy: [{ isDefault: "desc" }, { createdAt: "desc" }],
    });

    const results: AddressResponse[] = [];

    for (const record of addresses) {
      const coords = await this.ensureCoordinates(record);
      results.push(
        this.formatAddress({
          ...record,
          latitude: coords.latitude,
          longitude: coords.longitude,
        })
      );
    }

    return results;
  }

  /**
   * Get an address by ID for a user.
   * Auto-resolves lat/long if missing, updates DB, and returns updated address.
   */
  async getAddressById(userId: string, addressId: string): Promise<AddressResponse> {
    const record = await this.prisma.userAddress.findFirst({
      where: {
        id: addressId,
        userId,
        OR: [{ isDelete: false }, { isDelete: null }],
      },
    });

    if (!record) {
      throw new AppError(404, ErrorCodes.ADDRESS_NOT_FOUND, "Không tìm thấy địa chỉ.");
    }

    const coords = await this.ensureCoordinates(record);
    return this.formatAddress({
      ...record,
      latitude: coords.latitude,
      longitude: coords.longitude,
    });
  }

  /**
   * Create a new address for a user.
   * Automatically geocodes coordinates if not provided.
   */
  async createAddress(userId: string, input: CreateAddressInput): Promise<AddressResponse> {
    const addressLine = (input.addressLine || input.address || "").trim();
    const phone = (input.recipientPhone || input.phone || "").trim();
    const deliveryNote = input.deliveryNote || input.driverNote || null;

    let lat = input.latitude ?? null;
    let lng = input.longitude ?? null;

    if (lat === null || lng === null) {
      const coords = await this.geocode(addressLine);
      if (coords) {
        lat = coords.latitude;
        lng = coords.longitude;
      }
    }

    // Check count of active addresses
    const count = await this.prisma.userAddress.count({
      where: {
        userId,
        OR: [{ isDelete: false }, { isDelete: null }],
      },
    });

    const isDefault = input.isDefault ?? (count === 0);

    if (isDefault) {
      // Unset previous defaults
      await this.prisma.userAddress.updateMany({
        where: { userId, isDefault: true },
        data: { isDefault: false },
      });
    }

    const created = await this.prisma.userAddress.create({
      data: {
        userId,
        recipientName: input.recipientName.trim(),
        recipientPhone: phone,
        addressLine,
        label: input.label || "Nhà riêng",
        deliveryNote,
        isDefault,
        isDelete: false,
        latitude: lat,
        longitude: lng,
      },
    });

    return this.formatAddress(created);
  }

  /**
   * Update an address.
   * Re-geocodes if address text changed and new coordinates were not explicitly given.
   */
  async updateAddress(
    userId: string,
    addressId: string,
    input: UpdateAddressInput
  ): Promise<AddressResponse> {
    const existing = await this.prisma.userAddress.findFirst({
      where: {
        id: addressId,
        userId,
        OR: [{ isDelete: false }, { isDelete: null }],
      },
    });

    if (!existing) {
      throw new AppError(404, ErrorCodes.ADDRESS_NOT_FOUND, "Không tìm thấy địa chỉ.");
    }

    const newAddressLine = input.addressLine || input.address;
    const addressChanged = newAddressLine !== undefined && newAddressLine.trim() !== existing.addressLine;
    const effectiveAddress = addressChanged ? newAddressLine.trim() : existing.addressLine;

    let lat = input.latitude !== undefined ? input.latitude : existing.latitude;
    let lng = input.longitude !== undefined ? input.longitude : existing.longitude;

    if (addressChanged && input.latitude === undefined && input.longitude === undefined) {
      const coords = await this.geocode(effectiveAddress);
      if (coords) {
        lat = coords.latitude;
        lng = coords.longitude;
      }
    }

    if (input.isDefault) {
      await this.prisma.userAddress.updateMany({
        where: { userId, isDefault: true, NOT: { id: addressId } },
        data: { isDefault: false },
      });
    }

    const updated = await this.prisma.userAddress.update({
      where: { id: addressId },
      data: {
        ...(input.recipientName !== undefined && { recipientName: input.recipientName.trim() }),
        ...((input.recipientPhone !== undefined || input.phone !== undefined) && {
          recipientPhone: (input.recipientPhone || input.phone)!.trim(),
        }),
        ...(addressChanged && { addressLine: effectiveAddress }),
        ...(input.label !== undefined && { label: input.label }),
        ...((input.deliveryNote !== undefined || input.driverNote !== undefined) && {
          deliveryNote: input.deliveryNote || input.driverNote || null,
        }),
        ...(input.isDefault !== undefined && { isDefault: input.isDefault }),
        latitude: lat,
        longitude: lng,
      },
    });

    return this.formatAddress(updated);
  }

  /**
   * Delete an address (soft delete). If default was deleted, assign default to the latest remaining address.
   */
  async deleteAddress(userId: string, addressId: string): Promise<void> {
    const existing = await this.prisma.userAddress.findFirst({
      where: {
        id: addressId,
        userId,
        OR: [{ isDelete: false }, { isDelete: null }],
      },
    });

    if (!existing) {
      throw new AppError(404, ErrorCodes.ADDRESS_NOT_FOUND, "Không tìm thấy địa chỉ.");
    }

    await this.prisma.userAddress.update({
      where: { id: addressId },
      data: { isDelete: true },
    });

    if (existing.isDefault) {
      const latest = await this.prisma.userAddress.findFirst({
        where: {
          userId,
          NOT: { id: addressId },
          OR: [{ isDelete: false }, { isDelete: null }],
        },
        orderBy: { createdAt: "desc" },
      });

      if (latest) {
        await this.prisma.userAddress.update({
          where: { id: latest.id },
          data: { isDefault: true },
        });
      }
    }
  }

  /**
   * Explicitly set an address as the default address.
   */
  async setDefaultAddress(userId: string, addressId: string): Promise<AddressResponse> {
    const existing = await this.prisma.userAddress.findFirst({
      where: {
        id: addressId,
        userId,
        OR: [{ isDelete: false }, { isDelete: null }],
      },
    });

    if (!existing) {
      throw new AppError(404, ErrorCodes.ADDRESS_NOT_FOUND, "Không tìm thấy địa chỉ.");
    }

    await this.prisma.userAddress.updateMany({
      where: { userId, isDefault: true },
      data: { isDefault: false },
    });

    const updated = await this.prisma.userAddress.update({
      where: { id: addressId },
      data: { isDefault: true },
    });

    const coords = await this.ensureCoordinates(updated);
    return this.formatAddress({
      ...updated,
      latitude: coords.latitude,
      longitude: coords.longitude,
    });
  }
}

export const addressService = new AddressService();
