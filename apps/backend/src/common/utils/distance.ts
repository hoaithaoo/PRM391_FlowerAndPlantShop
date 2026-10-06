/**
 * Calculate distance between two coordinate pairs using the Haversine formula (km).
 * Applies an urban street tortuosity multiplier (~1.25) to approximate driving distance.
 */
export function calculateDistanceKm(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371; // Earth's mean radius in km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const straightDistanceKm = R * c;

  // Approx 1.25 routing factor for urban streets
  const routingDistanceKm = straightDistanceKm * 1.25;

  return Math.round(routingDistanceKm * 10) / 10;
}

/**
 * Standard shop shipping fee tiered formula based on distance:
 * - Up to 2 km: 15,000 VND base fee
 * - Each additional km: + 5,000 VND
 */
export function calculateShippingFee(distanceKm: number): number {
  const BASE_DISTANCE_KM = 2;
  const BASE_FEE = 15000;
  const PER_KM_FEE = 5000;

  if (distanceKm <= BASE_DISTANCE_KM) {
    return BASE_FEE;
  }

  const extraKm = Math.ceil(distanceKm - BASE_DISTANCE_KM);
  return BASE_FEE + extraKm * PER_KM_FEE;
}

/**
 * Estimate preparation + delivery duration in minutes
 */
export function estimateDeliveryMinutes(distanceKm: number): number {
  const PREPARATION_MINUTES = 15;
  const TRAVEL_MINUTES_PER_KM = 3;
  return PREPARATION_MINUTES + Math.ceil(distanceKm * TRAVEL_MINUTES_PER_KM);
}
