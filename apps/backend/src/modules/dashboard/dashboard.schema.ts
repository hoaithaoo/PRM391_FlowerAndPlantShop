import { z } from "zod";

const DATE_ONLY = /^\d{4}-\d{2}-\d{2}$/;

const dateQuerySchema = z
  .string()
  .trim()
  .refine((value) => !Number.isNaN(Date.parse(value)), {
    message: "Ngày phải theo định dạng YYYY-MM-DD hoặc ISO 8601.",
  });

export const dashboardQuerySchema = z
  .object({
    from: dateQuerySchema.optional(),
    to: dateQuerySchema.optional(),
  })
  .strict()
  .refine(
    ({ from, to }) => !from || !to || Date.parse(from) <= Date.parse(to),
    { message: "from không được lớn hơn to.", path: ["from"] }
  );

export const isDateOnly = (value: string): boolean => DATE_ONLY.test(value);

export type DashboardQuery = z.infer<typeof dashboardQuerySchema>;
