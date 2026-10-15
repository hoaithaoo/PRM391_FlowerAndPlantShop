import { z } from "zod";

export const listStoresQuerySchema = z
  .object({
    latitude: z.coerce
      .number()
      .min(-90, "Latitude phải nằm trong khoảng -90 đến 90.")
      .max(90, "Latitude phải nằm trong khoảng -90 đến 90.")
      .optional(),
    longitude: z.coerce
      .number()
      .min(-180, "Longitude phải nằm trong khoảng -180 đến 180.")
      .max(180, "Longitude phải nằm trong khoảng -180 đến 180.")
      .optional(),
  })
  .refine(
    (data) =>
      (data.latitude === undefined && data.longitude === undefined) ||
      (data.latitude !== undefined && data.longitude !== undefined),
    {
      message: "Cả latitude và longitude phải được gửi cùng nhau để tính khoảng cách.",
      path: ["latitude"],
    }
  );

export const shippingEstimateSchema = z.object({
  latitude: z.coerce
    .number()
    .min(-90, "Latitude phải nằm trong khoảng -90 đến 90.")
    .max(90, "Latitude phải nằm trong khoảng -90 đến 90."),
  longitude: z.coerce
    .number()
    .min(-180, "Longitude phải nằm trong khoảng -180 đến 180.")
    .max(180, "Longitude phải nằm trong khoảng -180 đến 180."),
  storeId: z.string().uuid("Store ID phải là định dạng UUID hợp lệ.").optional(),
});

export type ListStoresQueryInput = z.infer<typeof listStoresQuerySchema>;
export type ShippingEstimateInput = z.infer<typeof shippingEstimateSchema>;
