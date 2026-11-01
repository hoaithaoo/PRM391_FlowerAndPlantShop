import {
  InvoiceStatus,
  PaymentStatus,
  Prisma,
  PrismaClient,
} from "@prisma/client";
import { logger } from "../../lib/logger";
import { prisma } from "../../lib/prisma";
import {
  CANCELLABLE_STATUSES,
  cancelOrderInTransaction,
} from "../orders/order-state";

type ExpiryDatabase = Pick<PrismaClient, "$transaction" | "payment">;
type Clock = () => Date;

const BATCH_SIZE = 100;

/**
 * Đổi payment quá hạn sang EXPIRED và tự hủy đơn chưa xử lý để trả hàng về kho.
 * Mỗi payment một transaction: lỗi một payment không chặn các payment còn lại.
 */
export const expireOverduePayments = async (
  where: Prisma.PaymentWhereInput = {},
  db: ExpiryDatabase = prisma,
  now: Clock = () => new Date()
): Promise<void> => {
  const currentTime = now();
  const overdue = await db.payment.findMany({
    where: {
      ...where,
      status: PaymentStatus.PENDING,
      expiresAt: { lte: currentTime },
    },
    orderBy: { expiresAt: "asc" },
    take: BATCH_SIZE,
    select: { id: true },
  });

  for (const { id } of overdue) {
    try {
      await db.$transaction(async (tx) => {
        // Cập nhật có điều kiện để không tranh với webhook đang đánh dấu PAID.
        const updated = await tx.payment.updateMany({
          where: { id, status: PaymentStatus.PENDING },
          data: { status: PaymentStatus.EXPIRED },
        });
        if (updated.count === 0) return;

        const payment = await tx.payment.findUnique({
          where: { id },
          select: {
            invoice: {
              select: {
                status: true,
                order: { select: { id: true, status: true } },
              },
            },
          },
        });
        const invoice = payment?.invoice;
        const order = invoice?.order;
        if (
          !order ||
          invoice.status === InvoiceStatus.PAID ||
          !CANCELLABLE_STATUSES.includes(order.status)
        ) {
          return;
        }

        await cancelOrderInTransaction(tx, order.id, {
          cancelledAt: currentTime,
          byAdmin: false,
          bySystem: true,
        });
      });
    } catch (error) {
      logger.error("Không xử lý được payment quá hạn", { paymentId: id, error });
    }
  }
};
