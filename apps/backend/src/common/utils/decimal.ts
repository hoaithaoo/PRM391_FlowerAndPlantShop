import { Prisma } from "@prisma/client";

export const toNumber = (value: Prisma.Decimal): number =>
  Number(value.toString());

export const toNullableNumber = (
  value: Prisma.Decimal | null
): number | null => (value === null ? null : toNumber(value));
