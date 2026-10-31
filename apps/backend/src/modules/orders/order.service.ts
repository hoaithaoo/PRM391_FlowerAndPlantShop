import {
  InvoiceStatus,
  OrderStatus,
  PaymentMethod,
  Prisma,
  PrismaClient,
} from "@prisma/client";
import { AppError } from "../../common/errors/app-error";
import { ErrorCodes } from "../../common/errors/error-codes";
import { toNumber } from "../../common/utils/decimal";
import { toPageMeta, toSkipTake } from "../../common/utils/pagination";
import { prisma } from "../../lib/prisma";
import {
  ORDER_STATUS_MESSAGES,
  ORDER_TRANSITIONS,
  cancelOrderInTransaction,
  derivePaymentStatus,
  paymentStatusWhere,
} from "./order-state";
import type {
  AdminListOrdersQuery,
  AdminUpdateOrderStatusInput,
  CancelOrderInput,
  ListMyOrdersQuery,
} from "./order.schema";

type OrderDatabase = Pick<PrismaClient, "$transaction" | "order">;
type Clock = () => Date;

const MAX_TRANSACTION_ATTEMPTS = 3;

const paymentStatusInclude = {
  invoice: {
    select: {
      id: true,
      invoiceNo: true,
      status: true,
      grandTotal: true,
      payments: {
        orderBy: { createdAt: "desc" as const },
        take: 1,
        select: { id: true, status: true },
      },
    },
  },
} satisfies Prisma.OrderInclude;

const orderSummarySelect = {
  id: true,
  orderNumber: true,
  status: true,
  paymentMethod: true,
  totalAmount: true,
  recipientName: true,
  recipientPhone: true,
  shippingAddress: true,
  note: true,
  createdAt: true,
  updatedAt: true,
  user: { select: { id: true, fullName: true, email: true, phone: true } },
  ...paymentStatusInclude,
} satisfies Prisma.OrderSelect;

const orderDetailSelect = {
  ...orderSummarySelect,
  shippingLatitude: true,
  shippingLongitude: true,
  cancelledAt: true,
  completedAt: true,
  items: {
    orderBy: { name: "asc" as const },
    select: {
      id: true,
      productId: true,
      name: true,
      sku: true,
      unitPrice: true,
      quantity: true,
      subtotal: true,
      product: { select: { imageUrl: true } },
    },
  },
} satisfies Prisma.OrderSelect;

type OrderSummaryRow = Prisma.OrderGetPayload<{ select: typeof orderSummarySelect }>;
type OrderDetailRow = Prisma.OrderGetPayload<{ select: typeof orderDetailSelect }>;

const isRetryableTransactionError = (error: unknown): boolean =>
  error instanceof Prisma.PrismaClientKnownRequestError &&
  error.code === "P2034";

const notFound = () =>
  new AppError(404, ErrorCodes.ORDER_NOT_FOUND, "Không tìm thấy đơn hàng.");

// Trả cả tên field theo spec lẫn alias mà admin app đang đọc (customerName, totalAmount...).
const mapSummary = (order: OrderSummaryRow) => {
  const grandTotal = toNumber(order.totalAmount);
  return {
    id: order.id,
    orderCode: order.orderNumber,
    status: order.status,
    paymentStatus: derivePaymentStatus(order),
    paymentMethod: order.paymentMethod,
    grandTotal,
    totalAmount: grandTotal,
    customer: {
      id: order.user.id,
      name: order.user.fullName ?? order.recipientName,
      email: order.user.email,
      phone: order.user.phone ?? order.recipientPhone,
    },
    customerName: order.recipientName,
    customerPhone: order.recipientPhone,
    customerAddress: order.shippingAddress,
    invoiceId: order.invoice?.id ?? null,
    note: order.note,
    createdAt: order.createdAt,
    updatedAt: order.updatedAt,
  };
};

const mapDetail = (order: OrderDetailRow) => ({
  ...mapSummary(order),
  receiverName: order.recipientName,
  phone: order.recipientPhone,
  address: order.shippingAddress,
  latitude: toNumber(order.shippingLatitude),
  longitude: toNumber(order.shippingLongitude),
  invoiceNumber: order.invoice?.invoiceNo ?? null,
  paymentId: order.invoice?.payments[0]?.id ?? null,
  cancelledAt: order.cancelledAt,
  completedAt: order.completedAt,
  items: order.items.map((item) => ({
    id: item.id,
    productId: item.productId,
    productName: item.name,
    sku: item.sku,
    unitPrice: toNumber(item.unitPrice),
    quantity: item.quantity,
    subtotal: toNumber(item.subtotal),
    imageUrl: item.product.imageUrl,
  })),
});

export class OrderService {
  constructor(
    private readonly db: OrderDatabase = prisma,
    private readonly now: Clock = () => new Date()
  ) {}

  async listMine(userId: string, query: ListMyOrdersQuery) {
    const where: Prisma.OrderWhereInput = {
      userId,
      ...(query.status && { status: query.status }),
    };
    return this.list(where, query);
  }

  async getMine(userId: string, orderId: string) {
    const order = await this.db.order.findFirst({
      where: { id: orderId, userId },
      select: orderDetailSelect,
    });
    if (!order) throw notFound();
    return mapDetail(order);
  }

  async cancelMine(userId: string, orderId: string, input: CancelOrderInput) {
    return this.runInTransaction(async (tx) => {
      const order = await tx.order.findFirst({
        where: { id: orderId, userId },
        select: { id: true },
      });
      if (!order) throw notFound();

      return cancelOrderInTransaction(tx, orderId, {
        cancelledAt: this.now(),
        reason: input.reason,
        byAdmin: false,
      });
    });
  }

  async adminList(query: AdminListOrdersQuery) {
    const filters: Prisma.OrderWhereInput[] = [];
    if (query.status) filters.push({ status: query.status });
    if (query.paymentStatus) filters.push(paymentStatusWhere(query.paymentStatus));
    if (query.search) {
      const contains = { contains: query.search, mode: "insensitive" as const };
      filters.push({
        OR: [
          { orderNumber: contains },
          { recipientName: contains },
          { recipientPhone: contains },
          { user: { fullName: contains } },
          { user: { email: contains } },
        ],
      });
    }
    // Admin app hiển thị sản phẩm ngay trên danh sách nên trả kèm items.
    const where: Prisma.OrderWhereInput = filters.length ? { AND: filters } : {};
    const [orders, total] = await this.db.$transaction([
      this.db.order.findMany({
        where,
        orderBy: [{ createdAt: "desc" }, { id: "desc" }],
        ...toSkipTake(query),
        select: orderDetailSelect,
      }),
      this.db.order.count({ where }),
    ]);
    return { items: orders.map(mapDetail), meta: toPageMeta(query, total) };
  }

  async adminGet(orderId: string) {
    const order = await this.db.order.findUnique({
      where: { id: orderId },
      select: orderDetailSelect,
    });
    if (!order) throw notFound();
    return mapDetail(order);
  }

  async adminUpdateStatus(orderId: string, input: AdminUpdateOrderStatusInput) {
    await this.runInTransaction(async (tx) => {
      const order = await tx.order.findUnique({
        where: { id: orderId },
        select: {
          id: true,
          userId: true,
          orderNumber: true,
          status: true,
          paymentMethod: true,
          invoice: { select: { id: true, status: true } },
        },
      });
      if (!order) throw notFound();

      if (!ORDER_TRANSITIONS[order.status].includes(input.status)) {
        throw new AppError(
          409,
          ErrorCodes.INVALID_ORDER_STATE_TRANSITION,
          `Không thể chuyển đơn hàng từ ${order.status} sang ${input.status}.`,
          { from: order.status, to: input.status, allowed: ORDER_TRANSITIONS[order.status] }
        );
      }

      if (input.status === OrderStatus.CANCELLED) {
        await cancelOrderInTransaction(tx, orderId, {
          cancelledAt: this.now(),
          reason: input.note,
          byAdmin: true,
        });
        return;
      }

      // Đơn chuyển khoản phải được thanh toán trước khi cửa hàng xử lý tiếp.
      if (
        order.paymentMethod === PaymentMethod.SEPAY &&
        order.invoice?.status !== InvoiceStatus.PAID
      ) {
        throw new AppError(
          409,
          ErrorCodes.INVALID_ORDER_STATE_TRANSITION,
          "Đơn hàng SePay chưa được thanh toán, chưa thể xử lý tiếp."
        );
      }

      const changedAt = this.now();
      const updated = await tx.order.updateMany({
        where: { id: orderId, status: order.status },
        data: {
          status: input.status,
          ...(input.status === OrderStatus.COMPLETED && { completedAt: changedAt }),
        },
      });
      if (updated.count === 0) {
        throw new AppError(
          409,
          ErrorCodes.INVALID_ORDER_STATE_TRANSITION,
          "Đơn hàng vừa được cập nhật bởi yêu cầu khác, vui lòng tải lại."
        );
      }

      // COD không có bản ghi payment: giao xong nghĩa là đã thu tiền.
      if (
        input.status === OrderStatus.COMPLETED &&
        order.paymentMethod === PaymentMethod.COD &&
        order.invoice
      ) {
        await tx.invoice.updateMany({
          where: { id: order.invoice.id, status: InvoiceStatus.ISSUED },
          data: { status: InvoiceStatus.PAID, paidAt: changedAt },
        });
      }

      await tx.notification.create({
        data: {
          userId: order.userId,
          type: "ORDER",
          title: "Cập nhật đơn hàng",
          message: `Đơn hàng ${order.orderNumber} ${ORDER_STATUS_MESSAGES[input.status] ?? "đã được cập nhật"}.`,
          data: { orderId: order.id, status: input.status },
        },
      });
    });

    return this.adminGet(orderId);
  }

  private async list(
    where: Prisma.OrderWhereInput,
    query: { page: number; limit: number }
  ) {
    const [orders, total] = await this.db.$transaction([
      this.db.order.findMany({
        where,
        orderBy: [{ createdAt: "desc" }, { id: "desc" }],
        ...toSkipTake(query),
        select: orderSummarySelect,
      }),
      this.db.order.count({ where }),
    ]);
    return { items: orders.map(mapSummary), meta: toPageMeta(query, total) };
  }

  private async runInTransaction<T>(
    work: (tx: Prisma.TransactionClient) => Promise<T>
  ): Promise<T> {
    for (let attempt = 1; ; attempt += 1) {
      try {
        return await this.db.$transaction(work, {
          isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
        });
      } catch (error) {
        if (!isRetryableTransactionError(error) || attempt >= MAX_TRANSACTION_ATTEMPTS) {
          if (isRetryableTransactionError(error)) {
            throw new AppError(
              409,
              ErrorCodes.TRANSACTION_CONFLICT,
              "Đơn hàng đang được cập nhật đồng thời, vui lòng thử lại."
            );
          }
          throw error;
        }
      }
    }
  }
}

export const orderService = new OrderService();
