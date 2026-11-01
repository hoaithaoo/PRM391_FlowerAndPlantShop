import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { geocodeAddress, withoutHouseNumber } from "./geocoder";

describe("withoutHouseNumber", () => {
  it("strips the first part when there are 3 or more comma-separated parts", () => {
    const input = "15 Nguyễn Thiện Thuật, Phường 2, Quận 3, TP. Hồ Chí Minh";
    const result = withoutHouseNumber(input);
    assert.equal(result, "Phường 2, Quận 3, TP. Hồ Chí Minh");
  });

  it("handles messy spacing around commas", () => {
    const input = " 44/16/44 ,  Phạm Văn Chiêu ,  Phường 14 ,  Quận Gò Vấp ";
    const result = withoutHouseNumber(input);
    assert.equal(result, "Phạm Văn Chiêu, Phường 14, Quận Gò Vấp");
  });

  it("returns null if there are fewer than 3 parts", () => {
    assert.equal(withoutHouseNumber("Quận 1, TP. HCM"), null);
    assert.equal(withoutHouseNumber("Ho Chi Minh"), null);
    assert.equal(withoutHouseNumber(""), null);
  });
});

describe("geocodeAddress", () => {
  it("returns null for empty address", async () => {
    const result = await geocodeAddress("   ");
    assert.equal(result, null);
  });

  it("resolves coordinates from Nominatim on primary attempt", async () => {
    const mockFetch: typeof fetch = async (input) => {
      const url = input.toString();
      if (url.includes("nominatim.openstreetmap.org")) {
        return new Response(
          JSON.stringify([
            {
              lat: "10.770300",
              lon: "106.682200",
            },
          ]),
          { status: 200 }
        );
      }
      return new Response("Not found", { status: 404 });
    };

    const coords = await geocodeAddress("15 Nguyễn Thiện Thuật, Phường 2, Quận 3, TP. Hồ Chí Minh", {
      fetchFn: mockFetch,
    });

    assert.deepEqual(coords, {
      latitude: 10.7703,
      longitude: 106.6822,
    });
  });

  it("falls back to Nominatim without house number if specific address yields no result", async () => {
    const calls: string[] = [];

    const mockFetch: typeof fetch = async (input) => {
      const url = input.toString();
      calls.push(url);

      if (url.includes("nominatim.openstreetmap.org")) {
        // First call with full alley fails
        if (url.includes("44%2F16%2F44")) {
          return new Response(JSON.stringify([]), { status: 200 });
        }
        // Fallback without alley succeeds
        if (url.includes("Pham+Van+Chieu")) {
          return new Response(
            JSON.stringify([
              {
                lat: "10.841234",
                lon: "106.654321",
              },
            ]),
            { status: 200 }
          );
        }
      }
      return new Response("{}", { status: 404 });
    };

    const coords = await geocodeAddress("44/16/44, Pham Van Chieu, Phuong 14, Go Vap", {
      fetchFn: mockFetch,
    });

    assert.deepEqual(coords, {
      latitude: 10.841234,
      longitude: 106.654321,
    });
  });

  it("falls back to Photon if Nominatim network error occurs", async () => {
    const mockFetch: typeof fetch = async (input) => {
      const url = input.toString();
      if (url.includes("nominatim.openstreetmap.org")) {
        throw new Error("DNS resolution failure");
      }
      if (url.includes("photon.komoot.io")) {
        return new Response(
          JSON.stringify({
            features: [
              {
                geometry: {
                  coordinates: [106.700123, 10.780456],
                },
              },
            ],
          }),
          { status: 200 }
        );
      }
      return new Response("{}", { status: 404 });
    };

    const coords = await geocodeAddress("91 Đồng Khởi, Bến Nghé, Quận 1, TP. Hồ Chí Minh", {
      fetchFn: mockFetch,
    });

    assert.deepEqual(coords, {
      latitude: 10.780456,
      longitude: 106.700123,
    });
  });
});
