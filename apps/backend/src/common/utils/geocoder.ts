import { logger } from "../../lib/logger";

export interface GeoCoordinates {
  latitude: number;
  longitude: number;
}

const DEFAULT_USER_AGENT = "NhaCoHoa-FlowerAndPlantShop/1.0 (NodeBackend)";
const DEFAULT_TIMEOUT_MS = 4000;

/**
 * Remove house number / alley prefix from comma-separated address for fallback geocoding.
 * E.g., "15 Nguyễn Thiện Thuật, Phường 2, Quận 3, TP. Hồ Chí Minh"
 * -> "Phường 2, Quận 3, TP. Hồ Chí Minh"
 */
export function withoutHouseNumber(address: string): string | null {
  const parts = address
    .split(",")
    .map((part) => part.trim())
    .filter((part) => part.length > 0);

  if (parts.length < 3) {
    return null;
  }

  return parts.slice(1).join(", ");
}

/**
 * Geocode query using OpenStreetMap Nominatim.
 */
async function searchNominatim(
  query: string,
  timeoutMs: number,
  fetchFn: typeof fetch
): Promise<GeoCoordinates | null> {
  const url = new URL("https://nominatim.openstreetmap.org/search");
  url.searchParams.set("q", query);
  url.searchParams.set("format", "jsonv2");
  url.searchParams.set("limit", "1");
  url.searchParams.set("countrycodes", "vn");
  url.searchParams.set("accept-language", "vi");

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetchFn(url.toString(), {
      signal: controller.signal,
      headers: {
        "User-Agent": DEFAULT_USER_AGENT,
        Accept: "application/json",
      },
    });

    if (!response.ok) {
      return null;
    }

    const data = (await response.json()) as Array<{ lat?: string; lon?: string }>;
    if (!Array.isArray(data) || data.length === 0) {
      return null;
    }

    const first = data[0];
    const lat = Number(first.lat);
    const lon = Number(first.lon);

    if (
      Number.isFinite(lat) &&
      Number.isFinite(lon) &&
      lat >= -90 &&
      lat <= 90 &&
      lon >= -180 &&
      lon <= 180
    ) {
      return {
        latitude: Math.round(lat * 1_000_000) / 1_000_000,
        longitude: Math.round(lon * 1_000_000) / 1_000_000,
      };
    }

    return null;
  } catch (err) {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

/**
 * Geocode query using Photon (Komoot OSM-based API).
 * Used as high-reliability fallback when Nominatim is rate-limited or DNS-restricted.
 */
async function searchPhoton(
  query: string,
  timeoutMs: number,
  fetchFn: typeof fetch
): Promise<GeoCoordinates | null> {
  const url = new URL("https://photon.komoot.io/api/");
  url.searchParams.set("q", query);
  url.searchParams.set("limit", "1");

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetchFn(url.toString(), {
      signal: controller.signal,
      headers: {
        "User-Agent": DEFAULT_USER_AGENT,
        Accept: "application/json",
      },
    });

    if (!response.ok) {
      return null;
    }

    const data = (await response.json()) as {
      features?: Array<{
        geometry?: { coordinates?: [number, number] };
      }>;
    };

    const first = data.features?.[0];
    const coords = first?.geometry?.coordinates;
    if (!coords || coords.length < 2) {
      return null;
    }

    const lon = coords[0];
    const lat = coords[1];

    if (
      Number.isFinite(lat) &&
      Number.isFinite(lon) &&
      lat >= -90 &&
      lat <= 90 &&
      lon >= -180 &&
      lon <= 180
    ) {
      return {
        latitude: Math.round(lat * 1_000_000) / 1_000_000,
        longitude: Math.round(lon * 1_000_000) / 1_000_000,
      };
    }

    return null;
  } catch (err) {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

export interface GeocodeOptions {
  timeoutMs?: number;
  fetchFn?: typeof fetch;
}

/**
 * Converts a text address into geographic coordinates (latitude, longitude).
 * Falls back to street/ward search if house number is not indexed in OSM,
 * and falls back to Photon if Nominatim fails or times out.
 * Never throws errors: returns null if address cannot be resolved.
 */
export async function geocodeAddress(
  address: string,
  options: GeocodeOptions = {}
): Promise<GeoCoordinates | null> {
  const query = address.trim();
  if (!query) {
    return null;
  }

  const timeoutMs = options.timeoutMs ?? DEFAULT_TIMEOUT_MS;
  const fetchFn = options.fetchFn ?? globalThis.fetch;

  // 1. Try Nominatim with full address
  try {
    const coords = await searchNominatim(query, timeoutMs, fetchFn);
    if (coords) return coords;
  } catch {
    // continue to fallback
  }

  // 2. Try Nominatim with house number removed
  const fallbackQuery = withoutHouseNumber(query);
  if (fallbackQuery) {
    try {
      const coords = await searchNominatim(fallbackQuery, timeoutMs, fetchFn);
      if (coords) return coords;
    } catch {
      // continue to Photon fallback
    }
  }

  // 3. Fallback to Photon with full query
  try {
    const coords = await searchPhoton(query, timeoutMs, fetchFn);
    if (coords) return coords;
  } catch {
    // continue to Photon fallback without house number
  }

  // 4. Fallback to Photon without house number
  if (fallbackQuery) {
    try {
      const coords = await searchPhoton(fallbackQuery, timeoutMs, fetchFn);
      if (coords) return coords;
    } catch {
      // all providers exhausted
    }
  }

  logger.warn("Geocoding failed to resolve coordinates for address", { query });
  return null;
}
