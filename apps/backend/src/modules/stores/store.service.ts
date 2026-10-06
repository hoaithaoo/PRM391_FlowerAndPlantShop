import { prisma } from "../../lib/prisma";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import {
  calculateDistanceKm,
  calculateShippingFee,
  estimateDeliveryMinutes,
} from "../../common/utils/distance";

export class StoreService {
  /**
   * List all active stores.
   * If user coordinates are provided, compute distance and shipping fee for each store
   * and sort by nearest distance.
   */
  async listStores(userLat?: number, userLng?: number) {
    const stores = await prisma.store.findMany({
      where: { isActive: true },
      orderBy: { createdAt: "asc" },
    });

    const hasLocation =
      typeof userLat === "number" && typeof userLng === "number";

    const items = stores.map((store) => {
      const storeLat = Number(store.latitude);
      const storeLng = Number(store.longitude);

      let distanceKm: number | null = null;
      let shippingFee: number | null = null;
      let estimatedMinutes: number | null = null;

      if (hasLocation) {
        distanceKm = calculateDistanceKm(userLat, userLng, storeLat, storeLng);
        shippingFee = calculateShippingFee(distanceKm);
        estimatedMinutes = estimateDeliveryMinutes(distanceKm);
      }

      return {
        id: store.id,
        name: store.name,
        address: store.address,
        latitude: storeLat,
        longitude: storeLng,
        phone: store.phone,
        openingHours: store.openingHours,
        distanceKm,
        shippingFee,
        estimatedDeliveryMinutes: estimatedMinutes,
      };
    });

    if (hasLocation) {
      items.sort((a, b) => (a.distanceKm ?? 0) - (b.distanceKm ?? 0));
    }

    return { items };
  }

  /**
   * Calculate shipping details based on user's selected/current coordinates.
   * Finds the nearest active store (or the explicitly chosen store) and computes:
   * - distance in km
   * - shipping fee (VND)
   * - estimated delivery time in minutes
   */
  async estimateShipping(userLat: number, userLng: number, targetStoreId?: string) {
    let targetStore;

    if (targetStoreId) {
      targetStore = await prisma.store.findFirst({
        where: { id: targetStoreId, isActive: true },
      });
      if (!targetStore) {
        throw new AppError(
          404,
          ErrorCodes.STORE_NOT_FOUND,
          "Cửa hàng được chọn không tồn tại hoặc đã tạm dừng hoạt động."
        );
      }
    } else {
      // Find all active stores and determine the closest one
      const stores = await prisma.store.findMany({
        where: { isActive: true },
      });

      if (stores.length === 0) {
        throw new AppError(
          404,
          ErrorCodes.STORE_NOT_FOUND,
          "Hiện tại không có cửa hàng nào đang hoạt động."
        );
      }

      // Pick nearest
      let minDistance = Infinity;
      for (const store of stores) {
        const d = calculateDistanceKm(
          userLat,
          userLng,
          Number(store.latitude),
          Number(store.longitude)
        );
        if (d < minDistance) {
          minDistance = d;
          targetStore = store;
        }
      }
    }

    if (!targetStore) {
      throw new AppError(
        404,
        ErrorCodes.STORE_NOT_FOUND,
        "Không thể xác định cửa hàng phục vụ đơn hàng."
      );
    }

    const storeLat = Number(targetStore.latitude);
    const storeLng = Number(targetStore.longitude);
    const distanceKm = calculateDistanceKm(userLat, userLng, storeLat, storeLng);
    const shippingFee = calculateShippingFee(distanceKm);
    const estimatedMinutes = estimateDeliveryMinutes(distanceKm);

    return {
      store: {
        id: targetStore.id,
        name: targetStore.name,
        address: targetStore.address,
        latitude: storeLat,
        longitude: storeLng,
        phone: targetStore.phone,
      },
      userLocation: {
        latitude: userLat,
        longitude: userLng,
      },
      distanceKm,
      shippingFee,
      estimatedDeliveryMinutes: estimatedMinutes,
      currency: "VND",
    };
  }

  /**
   * Get store detail by ID
   */
  async getStoreById(id: string) {
    const store = await prisma.store.findUnique({
      where: { id },
    });

    if (!store) {
      throw new AppError(
        404,
        ErrorCodes.STORE_NOT_FOUND,
        "Không tìm thấy thông tin cửa hàng."
      );
    }

    return {
      id: store.id,
      name: store.name,
      address: store.address,
      latitude: Number(store.latitude),
      longitude: Number(store.longitude),
      phone: store.phone,
      openingHours: store.openingHours,
      isActive: store.isActive,
      createdAt: store.createdAt,
    };
  }
}

export const storeService = new StoreService();
