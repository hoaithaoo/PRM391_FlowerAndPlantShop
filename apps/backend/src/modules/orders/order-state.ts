import {
  InvoiceStatus,
  OrderStatus,
  PaymentMethod,
  PaymentStatus,
  Prisma,
} from "@prisma/client";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";

// Spec mục 11: PENDING → CONFIRMED → PREPARING → SHIPPING → COMPLETED;
// PENDING/CONFIRMED có thể → CANCELLED.
export const ORDER_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  PENDING: [OrderStatus.CONFIRMED, OrderStatus.CANCELLED],
  CONFIRMED: [OrderStatus.PREPARING, OrderStatus.CANCELLED],
  PREPARING: [OrderStatus.SHIPPING],
  SHIPPING: [OrderStatus.COMPLETED],
  COMPLETED: [],
  CANCELLED: [],
};

export const CANCELLABLE_STATUSES: OrderStatus[] = [
  OrderStatus.PENDING,
  OrderStatus.CONFIRMED,
];

type PaymentStatusSource = {
  paymentMethod: PaymentMethod;
  invoice: {
    status: InvoiceStatus;
    payments: { status: PaymentStatus }[];
  } | null;
};

/**
 * Trạng thái thanh toán hiển thị cho order:
 * - SEPAY: theo payment mới nhất.
 * - COD: không có bản ghi payment, suy ra từ invoice (PAID khi đã giao xong).
 */
export const derivePaymentStatus = (
  order: PaymentStatusSource
): PaymentStatus => {
  const invoice = order.invoice;
  if (!invoice) return PaymentStatus.PENDING;
  if (invoice.status === InvoiceStatus.PAID) return PaymentStatus.PAID;

  const latest = invoice.payments[0];
  if (latest) return latest.status;
  return invoice.status === InvoiceStatus.CANCELLED
    ? PaymentStatus.FAILED
    : PaymentStatus.PENDING;
};

/** Điều kiện lọc order theo trạng thái thanh toán, khớp với derivePaymentStatus. */
export const paymentStatusWhere = (
  status: PaymentStatus
): Prisma.OrderWhereInput => {
  if (status === PaymentStatus.PAID) {
    return { invoice: { status: InvoiceStatus.PAID } };
  }
  const byPayment: Prisma.OrderWhereInput = {
    invoice: {
      status: { not: InvoiceStatus.PAID },
      payments: { some: { status } },
    },
  };
  if (status === PaymentStatus.PENDING) {
    return {
      OR: [
        byPayment,
        {
          paymentMethod: PaymentMethod.COD,
          invoice: { status: InvoiceStatus.ISSUED },
        },
      ],
    };
  }
  if (status === PaymentStatus.FAILED) {
    return {
      OR: [
        byPayment,
        {
          paymentMethod: PaymentMethod.COD,
          invoice: { status: InvoiceStatus.CANCELLED },
        },
      ],
    };
  }
  return byPayment;
};

/**
 * Hủy order trong transaction: hoàn kho, hủy invoice, đánh FAILED cho payment
 * đang chờ và gửi thông báo. Gọi sau khi đã kiểm tra quyền và trạng thái.
 */
export const cancelOrderInTransaction = async (
  tx: Prisma.TransactionClient,
  orderId: string,
  options: { cancelledAt: Date; reason?: string | null; byAdmin: boolean }
) => {
  const order = await tx.order.findUnique({
    where: { id: orderId },
    select: {
      id: true,
      userId: true,
      orderNumber: true,
      status: true,
      items: { select: { productId: true, quantity: true } },
      invoice: { select: { id: true, status: true } },
    },
  });
  if (!order) {
    throw new AppError(404, ErrorCodes.ORDER_NOT_FOUND, "Không tìm thấy đơn hàng.");
  }
  if (order.invoice?.status === InvoiceStatus.PAID) {
    throw new AppError(
      409,
      options.byAdmin
        ? ErrorCodes.INVALID_ORDER_STATE_TRANSITION
        : ErrorCodes.ORDER_CANNOT_CANCEL,
      "Đơn hàng đã được thanh toán, cần xử lý hoàn tiền trước khi hủy."
    );
  }

  // Cập nhật có điều kiện để hai yêu cầu hủy đồng thời không hoàn kho hai lần.
  const updated = await tx.order.updateMany({
    where: { id: orderId, status: { in: CANCELLABLE_STATUSES } },
    data: { status: OrderStatus.CANCELLED, cancelledAt: options.cancelledAt },
  });
  if (updated.count === 0) {
    throw new AppError(
      409,
      options.byAdmin
        ? ErrorCodes.INVALID_ORDER_STATE_TRANSITION
        : ErrorCodes.ORDER_CANNOT_CANCEL,
      `Đơn hàng đang ở trạng thái ${order.status}, không thể hủy.`
    );
  }

  const sortedItems = [...order.items].sort((a, b) =>
    a.productId.localeCompare(b.productId)
  );
  for (const item of sortedItems) {
    await tx.product.update({
      where: { id: item.productId },
      data: { stock: { increment: item.quantity } },
    });
  }

  if (order.invoice) {
    await tx.invoice.updateMany({
      where: { id: order.invoice.id, status: InvoiceStatus.ISSUED },
      data: { status: InvoiceStatus.CANCELLED },
    });
    await tx.payment.updateMany({
      where: { invoiceId: order.invoice.id, status: PaymentStatus.PENDING },
      data: { status: PaymentStatus.FAILED },
    });
  }

  await tx.notification.create({
    data: {
      userId: order.userId,
      type: "ORDER",
      title: "Đơn hàng đã hủy",
      message: options.byAdmin
        ? `Đơn hàng ${order.orderNumber} đã được cửa hàng hủy.`
        : `Bạn đã hủy đơn hàng ${order.orderNumber}.`,
      data: {
        orderId: order.id,
        status: OrderStatus.CANCELLED,
        reason: options.reason ?? null,
      },
    },
  });

  return { id: order.id, status: OrderStatus.CANCELLED, cancelledAt: options.cancelledAt };
};

export const ORDER_STATUS_MESSAGES: Partial<Record<OrderStatus, string>> = {
  CONFIRMED: "đã được xác nhận",
  PREPARING: "đang được chuẩn bị",
  SHIPPING: "đang được giao",
  COMPLETED: "đã giao thành công",
};
