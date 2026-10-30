import { z } from "zod";

const uuidSchema = z.string().uuid("ID phải là UUID hợp lệ.");

const unreadOnlySchema = z
  .enum(["true", "false"])
  .transform((value) => value === "true")
  .default("false");

export const NOTIFICATIONS_PAGE_SIZE = 20;

export const listNotificationsQuerySchema = z
  .object({
    page: z.coerce.number().int().min(1).safe().default(1),
    unreadOnly: unreadOnlySchema,
  })
  .strict();

export const notificationIdParamsSchema = z
  .object({
    id: uuidSchema,
  })
  .strict();

export type ListNotificationsQuery = z.infer<
  typeof listNotificationsQuerySchema
>;
