import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { AddressService } from "./address.service";
import { GeoCoordinates } from "../../common/utils/geocoder";

const USER_ID = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
const ADDR_ID_1 = "11111111-1111-4111-8111-111111111111";
const ADDR_ID_2 = "22222222-2222-4222-8222-222222222222";

describe("AddressService", () => {
  it("auto-geocodes and updates DB when queried addresses lack lat/long", async () => {
    const dbAddresses = [
      {
        id: ADDR_ID_1,
        userId: USER_ID,
        recipientName: "Lê Nhật Nam",
        recipientPhone: "0912345678",
        addressLine: "44/16/44, Phạm Văn Chiêu, phường 8, quận Gò Vấp, Thành phố Hồ Chí Minh",
        label: "Nhà",
        deliveryNote: null,
        isDefault: true,
        isDelete: false,
        latitude: null, // missing lat/long
        longitude: null,
        createdAt: new Date("2026-10-21T00:00:00Z"),
        updatedAt: new Date("2026-10-21T00:00:00Z"),
      },
      {
        id: ADDR_ID_2,
        userId: USER_ID,
        recipientName: "Lê Nhật Nam",
        recipientPhone: "0912345678",
        addressLine: "72 Lê Thánh Tôn, Bến Nghé, Quận 1, TP. Hồ Chí Minh",
        label: "Văn phòng",
        deliveryNote: null,
        isDefault: false,
        isDelete: false,
        latitude: 10.778, // already has coordinates
        longitude: 106.702,
        createdAt: new Date("2026-10-22T00:00:00Z"),
        updatedAt: new Date("2026-10-22T00:00:00Z"),
      },
    ];

    const updatedRecords: Array<{ id: string; data: unknown }> = [];
    const geocodedAddresses: string[] = [];

    const mockPrisma = {
      userAddress: {
        findMany: async () => dbAddresses,
        update: async ({ where, data }: { where: { id: string }; data: any }) => {
          updatedRecords.push({ id: where.id, data });
          return { ...dbAddresses[0], ...data };
        },
      },
    } as any;

    const mockGeocoder = async (query: string): Promise<GeoCoordinates | null> => {
      geocodedAddresses.push(query);
      return { latitude: 10.8412, longitude: 106.6543 };
    };

    const service = new AddressService({
      prisma: mockPrisma,
      geocoder: mockGeocoder,
    });

    const results = await service.listUserAddresses(USER_ID);

    // 1. Geocoder called only once for ADDR_ID_1 (since ADDR_ID_2 already had coordinates)
    assert.equal(geocodedAddresses.length, 1);
    assert.equal(geocodedAddresses[0], "44/16/44, Phạm Văn Chiêu, phường 8, quận Gò Vấp, Thành phố Hồ Chí Minh");

    // 2. DB update performed for ADDR_ID_1 with new coordinates
    assert.equal(updatedRecords.length, 1);
    assert.equal(updatedRecords[0].id, ADDR_ID_1);
    assert.deepEqual(updatedRecords[0].data, {
      latitude: 10.8412,
      longitude: 106.6543,
    });

    // 3. Response contains coordinates for ADDR_ID_1 and backward compatibility aliases
    assert.equal(results[0].id, ADDR_ID_1);
    assert.equal(results[0].latitude, 10.8412);
    assert.equal(results[0].longitude, 106.6543);
    assert.equal(results[0].phone, "0912345678"); // alias
    assert.equal(results[0].address, "44/16/44, Phạm Văn Chiêu, phường 8, quận Gò Vấp, Thành phố Hồ Chí Minh"); // alias

    // 4. ADDR_ID_2 keeps its existing coordinates
    assert.equal(results[1].id, ADDR_ID_2);
    assert.equal(results[1].latitude, 10.778);
    assert.equal(results[1].longitude, 106.702);
  });

  it("getAddressById auto-geocodes if missing and updates DB", async () => {
    const addressRecord = {
      id: ADDR_ID_1,
      userId: USER_ID,
      recipientName: "Trần Ngọc Lan",
      recipientPhone: "0918862288",
      addressLine: "28 Đường số 7, Phường An Khánh, TP. Thủ Đức, TP. Hồ Chí Minh",
      label: "Nhà mẹ",
      deliveryNote: null,
      isDefault: false,
      isDelete: false,
      latitude: null,
      longitude: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    let updatedInDb = false;

    const mockPrisma = {
      userAddress: {
        findFirst: async () => addressRecord,
        update: async () => {
          updatedInDb = true;
          return addressRecord;
        },
      },
    } as any;

    const service = new AddressService({
      prisma: mockPrisma,
      geocoder: async () => ({ latitude: 10.791, longitude: 106.732 }),
    });

    const result = await service.getAddressById(USER_ID, ADDR_ID_1);

    assert.equal(updatedInDb, true);
    assert.equal(result.latitude, 10.791);
    assert.equal(result.longitude, 106.732);
  });

  it("createAddress automatically resolves coordinates and sets isDelete=false", async () => {
    let createdPayload: any = null;

    const mockPrisma = {
      userAddress: {
        count: async () => 0,
        updateMany: async () => {},
        create: async ({ data }: { data: any }) => {
          createdPayload = data;
          return {
            id: ADDR_ID_1,
            ...data,
            createdAt: new Date(),
            updatedAt: new Date(),
          };
        },
      },
    } as any;

    const service = new AddressService({
      prisma: mockPrisma,
      geocoder: async () => ({ latitude: 10.7703, longitude: 106.6822 }),
    });

    const result = await service.createAddress(USER_ID, {
      recipientName: "Nguyen Minh Anh",
      phone: "0901234567",
      addressLine: "15 Nguyễn Thiện Thuật",
      isDefault: true,
      label: "Nhà riêng",
    });

    assert.equal(result.isDefault, true);
    assert.equal(result.isDelete, false);
    assert.equal(result.latitude, 10.7703);
    assert.equal(result.longitude, 106.6822);
    assert.equal(createdPayload.recipientPhone, "0901234567");
    assert.equal(createdPayload.latitude, 10.7703);
  });

  it("deleteAddress performs soft delete by setting isDelete=true", async () => {
    let updatedData: any = null;
    let newDefaultId: string | null = null;

    const mockPrisma = {
      userAddress: {
        findFirst: async ({ where }: any) => {
          if (where.id === ADDR_ID_1) {
            return { id: ADDR_ID_1, userId: USER_ID, isDefault: true, isDelete: false };
          }
          return { id: ADDR_ID_2, userId: USER_ID, isDefault: false, isDelete: false };
        },
        update: async ({ where, data }: any) => {
          if (where.id === ADDR_ID_1) {
            updatedData = data;
          } else {
            newDefaultId = where.id;
          }
        },
      },
    } as any;

    const service = new AddressService({ prisma: mockPrisma });
    await service.deleteAddress(USER_ID, ADDR_ID_1);

    assert.deepEqual(updatedData, { isDelete: true });
    assert.equal(newDefaultId, ADDR_ID_2);
  });
});
